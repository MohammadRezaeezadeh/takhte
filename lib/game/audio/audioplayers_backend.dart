import 'package:audioplayers/audioplayers.dart';
import 'package:haftnard/game/audio/audio_manager.dart';

/// Real players via audioplayers. Sound effects use low-latency players
/// (Android SoundPool) that never request audio focus, so they cannot steal
/// focus from the music or from each other; music uses one streaming player.
class AudioplayersBackend implements AudioBackend {
  final AudioCache _cache = AudioCache(prefix: 'assets/audio/');

  static final AudioContext _sfxContext = AudioContext(
    android: const AudioContextAndroid(
      contentType: AndroidContentType.sonification,
      usageType: AndroidUsageType.game,
      audioFocus: AndroidAudioFocus.none,
    ),
  );

  static final AudioContext _musicContext = AudioContext(
    android: const AudioContextAndroid(
      usageType: AndroidUsageType.game,
      audioFocus: AndroidAudioFocus.none,
    ),
  );

  @override
  Future<void> configure() => AudioPlayer.global.setAudioContext(_sfxContext);

  @override
  Future<SfxVoice> createVoice(String file) async {
    final p = AudioPlayer()..audioCache = _cache;
    await p.setAudioContext(_sfxContext);
    await p.setPlayerMode(PlayerMode.lowLatency);
    await p.setReleaseMode(ReleaseMode.stop);
    await p.setSource(AssetSource(file));
    return _Voice(p);
  }

  @override
  Future<MusicVoice> createMusic() async {
    final p = AudioPlayer()..audioCache = _cache;
    await p.setAudioContext(_musicContext);
    await p.setReleaseMode(ReleaseMode.loop);
    return _Music(p);
  }
}

class _Voice implements SfxVoice {
  _Voice(this.p);
  final AudioPlayer p;
  double _rate = 1;

  @override
  Future<void> play(double volume, double rate) async {
    await p.stop();
    await p.setVolume(volume);
    if (rate != _rate) {
      await p.setPlaybackRate(rate);
      _rate = rate;
    }
    await p.resume();
  }

  @override
  Future<void> stop() => p.stop();

  @override
  Future<void> dispose() => p.dispose();
}

class _Music implements MusicVoice {
  _Music(this.p);
  final AudioPlayer p;

  @override
  Future<void> play(String file, double volume) async {
    await p.stop();
    await p.setVolume(volume);
    await p.play(AssetSource(file));
  }

  @override
  Future<void> setVolume(double volume) => p.setVolume(volume);

  @override
  Future<void> pause() => p.pause();

  @override
  Future<void> resume() => p.resume();

  @override
  Future<void> stop() => p.stop();

  @override
  Future<void> dispose() => p.dispose();
}
