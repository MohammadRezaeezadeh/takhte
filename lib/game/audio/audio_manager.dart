import 'dart:async';

/// One preloaded sound-effect voice (a player with its source already set).
abstract interface class SfxVoice {
  Future<void> play(double volume, double rate);
  Future<void> stop();
  Future<void> dispose();
}

/// One music channel (a streaming player).
abstract interface class MusicVoice {
  Future<void> play(String file, double volume);
  Future<void> setVolume(double volume);
  Future<void> pause();
  Future<void> resume();
  Future<void> stop();
  Future<void> dispose();
}

/// Creates platform players. Swapped for a fake in tests.
abstract interface class AudioBackend {
  Future<void> configure();
  Future<SfxVoice> createVoice(String file);
  Future<MusicVoice> createMusic();
}

/// Playback rules for one sound (or a group of variants such as clacks).
class SoundSpec {
  const SoundSpec({
    required this.durationMs,
    this.maxConcurrent = 2,
    this.debounceMs = 40,
    this.group,
  });

  /// How long a voice stays busy after it starts.
  final int durationMs;

  /// Voices of this sound (or group) that may sound at the same time; a new
  /// play steals the oldest one beyond this.
  final int maxConcurrent;

  /// Repeats of the same group within this window are dropped.
  final int debounceMs;

  /// Variants sharing a cap and debounce window (e.g. 'clack').
  final String? group;
}

/// Every sound effect the game ships, with its rules.
const Map<String, SoundSpec> kSoundSpecs = {
  'dice_roll': SoundSpec(durationMs: 750, maxConcurrent: 1, debounceMs: 120),
  'dice_land': SoundSpec(durationMs: 250),
  'clack_0': SoundSpec(durationMs: 180, maxConcurrent: 3, group: 'clack'),
  'clack_1': SoundSpec(durationMs: 180, maxConcurrent: 3, group: 'clack'),
  'clack_2': SoundSpec(durationMs: 180, maxConcurrent: 3, group: 'clack'),
  'slide': SoundSpec(durationMs: 220),
  'hit': SoundSpec(durationMs: 550),
  'bear_off': SoundSpec(durationMs: 1200, maxConcurrent: 1, debounceMs: 80),
  'seven_fanfare': SoundSpec(
    durationMs: 2400,
    maxConcurrent: 1,
    debounceMs: 500,
  ),
  'card_whoosh': SoundSpec(durationMs: 450),
  'card_flip': SoundSpec(durationMs: 120, maxConcurrent: 3, debounceMs: 30),
  'card_pick': SoundSpec(durationMs: 600, maxConcurrent: 1),
  'ui_tick': SoundSpec(durationMs: 60, debounceMs: 30),
  'ui_confirm': SoundSpec(durationMs: 300, maxConcurrent: 1),
  'ui_back': SoundSpec(durationMs: 300, maxConcurrent: 1),
  'coin': SoundSpec(durationMs: 700),
  'win': SoundSpec(durationMs: 2200, maxConcurrent: 1, debounceMs: 1000),
  'lose': SoundSpec(durationMs: 1600, maxConcurrent: 1, debounceMs: 1000),
  'mine': SoundSpec(durationMs: 1000, maxConcurrent: 1),
  'magic': SoundSpec(durationMs: 1200),
  'pop': SoundSpec(durationMs: 400),
};

class _Active {
  _Active(this.name, this.group, this.voice, this.startMs, this.endMs);
  final String name;
  final String group;
  final SfxVoice voice;
  final int startMs;
  final int endMs;
}

/// Counters exposed for the debug overlay, the problem log and tests.
class AudioStats {
  int played = 0;
  int debounced = 0;
  int stolen = 0;
  int failures = 0;
  int resets = 0;
}

/// Central audio manager: a fixed pool of preloaded SFX voices with per-sound
/// and global concurrency caps, voice stealing and debouncing, plus one music
/// channel. Any failed or hung platform call counts toward the watchdog,
/// which rebuilds every player; the app lifecycle pauses audio in the
/// background and fully re-initializes it on resume.
class AudioManager {
  AudioManager(
    this.backend, {
    int Function()? clock,
    this.maxActive = 8,
    this.callTimeout = const Duration(milliseconds: 600),
    this.failureLimit = 3,
    this.failureWindowMs = 5000,
    this.specs = kSoundSpecs,
    this.onLog,
  }) : _clock = clock ?? _wallClock;

  static final Stopwatch _sw = Stopwatch()..start();
  static int _wallClock() => _sw.elapsedMilliseconds;

  final AudioBackend backend;
  final int Function() _clock;
  final Map<String, SoundSpec> specs;

  /// Global cap on simultaneously sounding effects.
  final int maxActive;

  /// A platform call slower than this counts as hung.
  final Duration callTimeout;

  /// Failures within [failureWindowMs] that trigger a full reset.
  final int failureLimit;
  final int failureWindowMs;

  /// Diagnostic sink (the rolling problem log).
  final void Function(String message)? onLog;

  final AudioStats stats = AudioStats();
  final Map<String, List<SfxVoice>> _voices = {};
  final List<_Active> _active = [];
  final Map<String, int> _lastPlay = {};
  final List<int> _failureTimes = [];

  MusicVoice? _music;
  String? _musicTrack;
  double _musicVolume = 0.25;
  bool _musicPlaying = false;

  bool _ready = false;
  bool _paused = false;
  bool _disposed = false;
  Future<void>? _initFuture;

  /// Bumped on every rebuild so stale callbacks are ignored.
  int _generation = 0;

  bool get ready => _ready;
  int get activeCount {
    _prune(_clock());
    return _active.length;
  }

  int get voiceCount => _voices.values.fold(0, (a, l) => a + l.length);
  String? get musicTrack => _musicTrack;
  bool get musicPlaying => _musicPlaying;

  /// Creates every voice. Safe to call repeatedly; concurrent calls share one
  /// initialization.
  Future<void> init() => _initFuture ??= _init();

  Future<void> _init() async {
    final gen = ++_generation;
    try {
      await _guard(backend.configure());
      for (final e in specs.entries) {
        final list = <SfxVoice>[];
        for (var i = 0; i < e.value.maxConcurrent; i++) {
          list.add(await _guard(backend.createVoice('${e.key}.ogg')));
        }
        if (gen != _generation) {
          for (final v in list) {
            unawaited(_quiet(v.dispose()));
          }
          return;
        }
        _voices[e.key] = list;
      }
      _ready = true;
    } on Object catch (e) {
      _log('audio init failed: $e');
      _ready = false;
      _voices.clear();
    } finally {
      if (gen == _generation) _initFuture = null;
    }
  }

  /// Plays sound effect [name]. Never throws and never blocks.
  void play(String name, {double volume = 1, double rate = 1}) {
    if (_disposed || _paused || !_ready) return;
    final spec = specs[name];
    final voices = _voices[name];
    if (spec == null || voices == null || voices.isEmpty) return;
    final now = _clock();
    _prune(now);
    final group = spec.group ?? name;
    final last = _lastPlay[group];
    if (last != null && now - last < spec.debounceMs) {
      stats.debounced++;
      return;
    }
    _lastPlay[group] = now;

    // Per-group cap, then the global cap: steal the oldest voices.
    final inGroup = [
      for (final a in _active)
        if (a.group == group) a,
    ];
    if (inGroup.length >= spec.maxConcurrent) _steal(inGroup.first);
    if (_active.length >= maxActive) _steal(_active.first);

    // A free voice of this sound; if all are busy, steal this sound's oldest.
    SfxVoice? voice;
    for (final v in voices) {
      if (!_active.any((a) => a.voice == v)) {
        voice = v;
        break;
      }
    }
    if (voice == null) {
      _Active? own;
      for (final a in _active) {
        if (a.name == name) {
          own = a;
          break;
        }
      }
      if (own == null) return;
      _steal(own);
      voice = own.voice;
    }
    _active.add(_Active(name, group, voice, now, now + spec.durationMs));
    stats.played++;
    final gen = _generation;
    unawaited(
      _guard(voice.play(volume.clamp(0.0, 1.0), rate.clamp(0.5, 2.0)))
          .catchError((Object e) {
            if (gen == _generation) _fail('play $name: $e');
          }),
    );
  }

  void _steal(_Active a) {
    _active.remove(a);
    stats.stolen++;
    unawaited(_quiet(a.voice.stop()));
  }

  void _prune(int now) => _active.removeWhere((a) => a.endMs <= now);

  /// Starts (or switches to) a music track.
  Future<void> playMusic(String track, {double? volume}) async {
    if (_disposed) return;
    if (volume != null) _musicVolume = volume;
    if (_musicPlaying && _musicTrack == track) return;
    _musicTrack = track;
    _musicPlaying = true;
    if (_paused) return;
    await _startMusic();
  }

  Future<void> _startMusic() async {
    final track = _musicTrack;
    if (track == null) return;
    try {
      _music ??= await _guard(backend.createMusic());
      await _guard(_music!.play('$track.ogg', _musicVolume));
    } on Object catch (e) {
      _fail('music $track: $e');
      final m = _music;
      _music = null;
      if (m != null) unawaited(_quiet(m.dispose()));
    }
  }

  Future<void> setMusicVolume(double v) async {
    _musicVolume = v.clamp(0.0, 1.0);
    final m = _music;
    if (m == null) return;
    try {
      await _guard(m.setVolume(_musicVolume));
    } on Object catch (e) {
      _fail('music volume: $e');
    }
  }

  Future<void> stopMusic() async {
    _musicPlaying = false;
    final m = _music;
    if (m == null) return;
    try {
      await _guard(m.stop());
    } on Object catch (e) {
      _fail('music stop: $e');
    }
  }

  /// App went to the background (screen off, call, task switch).
  Future<void> onPause() async {
    if (_paused || _disposed) return;
    _paused = true;
    _stopAllVoices();
    final m = _music;
    if (m != null && _musicPlaying) {
      try {
        await _guard(m.pause());
      } on Object catch (e) {
        _log('music pause failed: $e');
      }
    }
  }

  /// App came back: rebuild every player from scratch (Android may have
  /// released them) and resume the music track.
  Future<void> onResume() async {
    if (_disposed) return;
    _paused = false;
    await reset(reason: 'resume');
  }

  /// Disposes and recreates every player.
  Future<void> reset({String reason = 'manual'}) async {
    if (_disposed) return;
    stats.resets++;
    _log('audio reset ($reason)');
    _ready = false;
    _generation++;
    _initFuture = null;
    _failureTimes.clear();
    await _disposePlayers();
    await init();
    if (_musicPlaying && !_paused) await _startMusic();
  }

  void _stopAllVoices() {
    for (final a in _active) {
      unawaited(_quiet(a.voice.stop()));
    }
    _active.clear();
  }

  Future<void> _disposePlayers() async {
    _active.clear();
    final all = [for (final l in _voices.values) ...l];
    _voices.clear();
    final m = _music;
    _music = null;
    await Future.wait([
      for (final v in all) _quiet(v.dispose()),
      if (m != null) _quiet(m.dispose()),
    ]);
  }

  /// Releases everything for good.
  Future<void> dispose() async {
    _disposed = true;
    _ready = false;
    _generation++;
    await _disposePlayers();
  }

  void _fail(String what) {
    stats.failures++;
    _log('audio error: $what');
    final now = _clock();
    _failureTimes
      ..add(now)
      ..removeWhere((t) => now - t > failureWindowMs);
    if (_failureTimes.length >= failureLimit && !_paused && !_disposed) {
      unawaited(reset(reason: 'watchdog'));
    }
  }

  Future<T> _guard<T>(Future<T> f) => f.timeout(callTimeout);

  Future<void> _quiet(Future<void> f) async {
    try {
      await f.timeout(callTimeout);
    } on Object {
      // Releasing a broken player must never cascade.
    }
  }

  void _log(String m) => onLog?.call(m);
}
