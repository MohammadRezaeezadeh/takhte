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
      _loaded = true;
    } on Object {
      available = false;
    }
  }

  void play(String name, {double volume = 1, double rate = 1}) {
    if (!available || !soundOn) return;
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

  Future<void> setAmbient({required bool on}) async {
    if (!available) return;
    try {
      if (on && musicOn && !_ambient) {
        await FlameAudio.bgm.initialize();
        await FlameAudio.bgm.play('ambient.wav', volume: 0.35);
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
