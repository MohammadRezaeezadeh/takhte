import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/services.dart';
import 'package:haftnard/game/audio/audio_manager.dart';
import 'package:haftnard/game/audio/audioplayers_backend.dart';

/// Game-facing audio and haptics. A thin facade over [AudioManager] so call
/// sites stay simple; everything is best-effort and never throws.
class Sfx {
  Sfx._();
  static final Sfx instance = Sfx._();

  bool soundOn = true;
  bool musicOn = true;
  bool hapticsOn = true;

  /// Effect and music volumes (0–1). Music sits below effects by default.
  double sfxVolume = 1;
  double musicVolume = 0.35;

  /// Disabled entirely in tests / headless runs.
  bool available = true;

  /// Diagnostic sink, wired to the problem log at startup.
  void Function(String message)? onLog;

  AudioManager? _manager;
  String _track = 'ambient';
  bool _ambientWanted = false;
  final _rng = math.Random();

  /// The manager, created on first use (null when audio is unavailable).
  AudioManager? get manager {
    if (!available) return null;
    return _manager ??= AudioManager(
      AudioplayersBackend(),
      onLog: (m) => onLog?.call(m),
    );
  }

  /// Replaces the manager (tests inject a fake backend).
  set manager(AudioManager? m) => _manager = m;

  Future<void> preload() async {
    final m = manager;
    if (m == null) return;
    await m.init();
  }

  void play(String name, {double volume = 1, double rate = 1}) {
    if (!soundOn) return;
    manager?.play(name, volume: volume * sfxVolume, rate: rate);
  }

  void clack({double rate = 1}) => play(
    'clack_${_rng.nextInt(3)}',
    rate: rate * (0.95 + _rng.nextDouble() * 0.1),
  );

  /// Music on/off; [track] switches tracks.
  Future<void> setAmbient({required bool on, String? track}) async {
    final m = manager;
    if (track != null) _track = track;
    _ambientWanted = on;
    if (m == null) return;
    if (on && musicOn) {
      await m.playMusic(_track, volume: musicVolume);
    } else {
      await m.stopMusic();
    }
  }

  Future<void> setMusicVolume(double v) async {
    musicVolume = v.clamp(0.0, 1.0);
    await manager?.setMusicVolume(musicVolume);
  }

  /// Re-applies the music state after a settings change.
  Future<void> refreshMusic() => setAmbient(on: _ambientWanted);

  Future<void> onPause() async {
    await _manager?.onPause();
  }

  Future<void> onResume() async {
    await _manager?.onResume();
  }

  void haptic(HapticKind k) {
    if (!available || !hapticsOn) return;
    try {
      switch (k) {
        case HapticKind.light:
          unawaited(HapticFeedback.selectionClick());
        case HapticKind.medium:
          unawaited(HapticFeedback.mediumImpact());
        case HapticKind.heavy:
          unawaited(HapticFeedback.heavyImpact());
      }
    } on Object {
      // ignore
    }
  }
}

enum HapticKind { light, medium, heavy }
