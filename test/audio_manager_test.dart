import 'dart:math' as math;

import 'package:haftnard/game/audio/audio_manager.dart';
import 'package:test/test.dart';

import 'support/fake_audio.dart';

void main() {
  late FakeBackend backend;
  late int now;
  late AudioManager audio;
  final logs = <String>[];

  setUp(() async {
    backend = FakeBackend();
    now = 0;
    logs.clear();
    audio = AudioManager(
      backend,
      clock: () => now,
      callTimeout: const Duration(milliseconds: 20),
      onLog: logs.add,
    );
    await audio.init();
  });

  test('voices are created once, up front', () {
    expect(audio.ready, isTrue);
    final expected = kSoundSpecs.values.fold<int>(
      0,
      (a, s) => a + s.maxConcurrent,
    );
    expect(audio.voiceCount, expected);
    expect(backend.voices, hasLength(expected));
  });

  test('stress: 20,000 rapid plays never exceed the caps or leak players', () {
    final names = kSoundSpecs.keys.toList();
    final r = math.Random(1);
    final created = backend.voices.length;
    for (var i = 0; i < 20000; i++) {
      now += r.nextInt(12);
      final name = names[r.nextInt(names.length)];
      audio.play(name);
      expect(audio.activeCount, lessThanOrEqualTo(audio.maxActive));
    }
    // Bursts: 500 clacks in the same millisecond.
    for (var i = 0; i < 500; i++) {
      audio.play('clack_${i % 3}');
    }
    expect(backend.voices, hasLength(created), reason: 'no new players');
    expect(audio.stats.played, greaterThan(1000));
    expect(audio.stats.debounced, greaterThan(0));
    expect(audio.stats.stolen, greaterThan(0));
    expect(audio.stats.failures, 0);
  });

  test('per-type cap: at most 3 clacks sound together', () {
    for (var i = 0; i < 10; i++) {
      now += 45; // past the debounce window, inside the clip length
      audio.play('clack_${i % 3}');
    }
    final activeClacks = backend.voices
        .where((v) => v.file.startsWith('clack'))
        .fold<int>(0, (a, v) => a + v.plays - v.stops);
    expect(activeClacks, lessThanOrEqualTo(3));
    expect(audio.stats.stolen, greaterThanOrEqualTo(7));
  });

  test('rapid repeats are debounced', () {
    audio
      ..play('ui_tick')
      ..play('ui_tick');
    now += 10;
    audio.play('ui_tick');
    expect(audio.stats.played, 1);
    expect(audio.stats.debounced, 2);
    now += 100;
    audio.play('ui_tick');
    expect(audio.stats.played, 2);
  });

  test('watchdog rebuilds every player after repeated failures', () async {
    backend.mode = FailMode.throwing;
    final before = backend.voices.toList();
    for (var i = 0; i < 3; i++) {
      now += 100;
      audio.play('hit');
    }
    await pumpEventQueue();
    expect(audio.stats.resets, 1);
    expect(before.every((v) => v.disposed), isTrue);
    expect(backend.live.length, audio.voiceCount);
    expect(logs.any((l) => l.contains('watchdog')), isTrue);
    backend.mode = FailMode.none;
    now += 100;
    audio.play('hit');
    await pumpEventQueue();
    expect(audio.stats.failures, 3);
  });

  test('hung play calls time out and trigger a reset', () async {
    backend.mode = FailMode.hanging;
    for (var i = 0; i < 3; i++) {
      now += 100;
      audio.play('pop');
    }
    await Future<void>.delayed(const Duration(milliseconds: 80));
    expect(audio.stats.failures, 3);
    expect(audio.stats.resets, greaterThanOrEqualTo(1));
    expect(audio.ready, isTrue);
  });

  test('pause silences, resume rebuilds players and restarts music', () async {
    await audio.playMusic('ambient_game');
    expect(backend.music.single.log, ['play ambient_game.ogg']);
    audio.play('hit');
    await audio.onPause();
    expect(backend.music.single.log.last, 'pause');
    final played = audio.stats.played;
    now += 1000;
    audio.play('hit');
    expect(audio.stats.played, played, reason: 'silent in background');

    final old = backend.voices.toList();
    await audio.onResume();
    expect(old.every((v) => v.disposed), isTrue);
    expect(backend.music.first.disposed, isTrue);
    expect(backend.music.last.log, ['play ambient_game.ogg']);
    now += 1000;
    audio.play('hit');
    expect(audio.stats.played, played + 1);
  });

  test('many pause/resume cycles keep the player count flat', () async {
    for (var i = 0; i < 50; i++) {
      await audio.onPause();
      await audio.onResume();
    }
    expect(backend.live.length, audio.voiceCount);
  });

  test('dispose releases everything and later calls are no-ops', () async {
    await audio.playMusic('ambient');
    await audio.dispose();
    expect(backend.voices.every((v) => v.disposed), isTrue);
    expect(backend.music.every((m) => m.disposed), isTrue);
    audio.play('hit');
    await audio.playMusic('ambient');
    expect(audio.stats.failures, 0);
  });

  test('init failure leaves audio silent but recoverable', () async {
    final broken = _BrokenBackend();
    final a = AudioManager(broken, clock: () => now, onLog: logs.add);
    await a.init();
    expect(a.ready, isFalse);
    a.play('hit');
    broken.ok = true;
    await a.onResume();
    expect(a.ready, isTrue);
  });
}

class _BrokenBackend extends FakeBackend {
  bool ok = false;
  @override
  Future<SfxVoice> createVoice(String file) async {
    if (!ok) throw StateError('no audio device');
    return await super.createVoice(file);
  }
}
