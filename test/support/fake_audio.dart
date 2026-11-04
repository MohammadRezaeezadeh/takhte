import 'dart:async';

import 'package:haftnard/game/audio/audio_manager.dart';

class FakeVoice implements SfxVoice {
  FakeVoice(this.backend, this.file);
  final FakeBackend backend;
  final String file;
  int plays = 0;
  int stops = 0;
  bool disposed = false;

  @override
  Future<void> play(double volume, double rate) {
    if (disposed) throw StateError('play after dispose');
    plays++;
    switch (backend.mode) {
      case FailMode.none:
        return Future.value();
      case FailMode.throwing:
        return Future.error(StateError('player died'));
      case FailMode.hanging:
        return Completer<void>().future;
    }
  }

  @override
  Future<void> stop() async => stops++;

  @override
  Future<void> dispose() async => disposed = true;
}

class FakeMusic implements MusicVoice {
  final List<String> log = [];
  bool disposed = false;
  @override
  Future<void> play(String file, double volume) async {
    this.volume = volume;
    log.add('play $file');
  }

  @override
  Future<void> setVolume(double volume) async {
    this.volume = volume;
    if (logVolume) log.add('vol $volume');
  }

  double volume = 0;
  bool logVolume = false;
  Duration pos = const Duration(seconds: 42);

  @override
  Future<Duration?> position() async => pos;

  @override
  Future<void> seek(Duration at) async => log.add('seek ${at.inSeconds}');
  @override
  Future<void> pause() async => log.add('pause');
  @override
  Future<void> resume() async => log.add('resume');
  @override
  Future<void> stop() async => log.add('stop');
  @override
  Future<void> dispose() async => disposed = true;
}

enum FailMode { none, throwing, hanging }

class FakeBackend implements AudioBackend {
  FailMode mode = FailMode.none;
  final List<FakeVoice> voices = [];
  final List<FakeMusic> music = [];

  @override
  Future<void> configure() async {}

  @override
  Future<SfxVoice> createVoice(String file) async {
    final v = FakeVoice(this, file);
    voices.add(v);
    return v;
  }

  @override
  Future<MusicVoice> createMusic() async {
    final m = FakeMusic();
    music.add(m);
    return m;
  }

  Iterable<FakeVoice> get live => voices.where((v) => !v.disposed);
}
