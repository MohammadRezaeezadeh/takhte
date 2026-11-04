import 'dart:async';
import 'dart:math' as math;

import 'package:flame_audio/flame_audio.dart';
import 'package:flutter/services.dart';

/// Sound effects, ambient loop and haptics with graceful failure (e.g. tests).
class Sfx {
  Sfx._();
  static final Sfx instance = Sfx._();

  bool soundOn = true;
  bool musicOn = true;
  bool hapticsOn = true;

  /// Disabled entirely in tests / headless runs.
  bool available = true;
  bool _loaded = false;
  bool _ambient = false;
  String _track = 'ambient';
  final Map<String, AudioPool> _pools = {};

  /// High-frequency effects are pooled to avoid creating players per play.
  static const _pooled = [
    'clack_0',
    'clack_1',
    'clack_2',
    'ui_tick',
    'slide',
    'dice_land',
  ];
  final _rng = math.Random();

  static const files = [
    'dice_roll',
    'dice_land',
    'clack_0',
    'clack_1',
    'clack_2',
    'slide',
    'hit',
    'bear_off',
    'seven_fanfare',
    'card_whoosh',
    'card_flip',
    'card_pick',
    'ui_tick',
    'ui_confirm',
    'ui_back',
    'coin',
    'win',
    'lose',
    'mine',
    'magic',
    'pop',
  ];

  Future<void> preload() async {
    if (!available || _loaded) return;
    try {
      FlameAudio.audioCache.prefix = 'assets/audio/';
      await FlameAudio.audioCache.loadAll([for (final f in files) '$f.wav']);
      for (final f in _pooled) {
        _pools[f] = await FlameAudio.createPool('$f.wav', maxPlayers: 3);
      }
      _loaded = true;
    } on Object {
      available = false;
    }
  }

  void play(String name, {double volume = 1, double rate = 1}) {
    if (!available || !soundOn) return;
    final pool = _pools[name];
    if (pool != null) {
      try {
        unawaited(pool.start(volume: volume));
      } on Object {
        // Audio is best-effort.
      }
      return;
    }
    try {
      unawaited(
        FlameAudio.play('$name.wav', volume: volume).then((p) async {
          if (rate != 1) await p.setPlaybackRate(rate);
        }),
      );
    } on Object {
      // Audio is best-effort.
    }
  }

  void clack({double rate = 1}) => play(
    'clack_${_rng.nextInt(3)}',
    rate: rate * (0.95 + _rng.nextDouble() * 0.1),
  );

  Future<void> setAmbient({required bool on, String? track}) async {
    if (!available) return;
    try {
      if (on && musicOn && _ambient && track != null && track != _track) {
        await FlameAudio.bgm.stop();
        _ambient = false;
      }
      if (track != null) _track = track;
      if (on && musicOn && !_ambient) {
        await FlameAudio.bgm.initialize();
        await FlameAudio.bgm.play('$_track.wav', volume: 0.35);
        _ambient = true;
      } else if ((!on || !musicOn) && _ambient) {
        await FlameAudio.bgm.stop();
        _ambient = false;
      }
    } on Object {
      available = false;
    }
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
