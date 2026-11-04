// Soak test: 50 complete AI-vs-AI matches (each ends with a full bear-off)
// in one session, each through a fresh GameScreen + Flame scene with the
// real AudioManager on a fake backend.
//
// Bear-off used to be where things went wrong (a new audio player and a
// per-frame text layout on every bear-off), so every frame of the bear-off
// is sampled: object counts must stay flat while bearing off and return to
// the match's baseline afterwards.
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:haftnard/core/ai/personality.dart';
import 'package:haftnard/core/rules/match.dart';
import 'package:haftnard/core/rules/types.dart';
import 'package:haftnard/game/audio.dart';
import 'package:haftnard/game/audio/audio_manager.dart';
import 'package:haftnard/game/match_controller.dart';
import 'package:haftnard/game/scene/board_game.dart';
import 'package:haftnard/game/scene/fx.dart';
import 'package:haftnard/meta/meta_state.dart';
import 'package:haftnard/meta/save.dart';
import 'package:haftnard/meta/settings.dart';
import 'package:haftnard/ui/app.dart';
import 'package:haftnard/ui/game/seven_overlay.dart';
import 'package:haftnard/ui/screens/game_screen.dart';

import '../support/fake_audio.dart';

void main() {
  const matches = int.fromEnvironment('SOAK_MATCHES', defaultValue: 50);
  final backend = FakeBackend();
  late AudioManager audio;

  setUpAll(() {
    SevenOverlay.useSensors = false;
    kAiUseIsolates = false;
    audio = AudioManager(backend);
    Sfx.instance
      ..available = true
      ..manager = audio;
  });

  tearDownAll(() {
    Sfx.instance
      ..manager = null
      ..available = false;
  });

  testWidgets('soak: $matches matches through bear-off keep every count flat', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(400, 860);
    addTearDown(tester.view.reset);
    await Sfx.instance.preload();
    final players = backend.voices.length;
    final weak = <WeakReference<BoardGame>>[];
    final rss = <double>[];
    int? firstBaseline;

    for (var m = 0; m < matches; m++) {
      final svc = SaveService(MemorySaveStore());
      svc.data.settings = const Settings(animSpeed: 2);
      final session = MatchSession(
        match: MatchState(MatchConfig(seed: 100 + m)),
        white: const SeatConfig.ai(
          personalityId: 'hammer',
          difficulty: Difficulty.easy,
          name: 'W',
        ),
        black: const SeatConfig.ai(
          personalityId: 'fox',
          difficulty: Difficulty.easy,
          name: 'B',
        ),
      );
      await tester.pumpWidget(
        ProviderScope(
          key: ValueKey(m),
          overrides: [saveServiceProvider.overrideWithValue(svc)],
          child: HaftNardApp(home: GameScreen(session: session)),
        ),
      );
      final layoutsBefore = FxLayer.debugPopupLayouts;
      final popupsBefore = FxLayer.debugPopupsCreated;
      int? baseComponents;
      int? baseListeners;
      var bearOffFrames = 0;
      for (var i = 0; i < 12000 && !session.match.isOver; i++) {
        await tester.pump(const Duration(milliseconds: 60));
        final g = BoardGame.current;
        if (g == null || !g.isLoaded) continue;
        final st = g.debugStats();
        final ctrl = g.controller;
        baseComponents ??= st['components'];
        baseListeners ??= ctrl.listenerCount;
        final s = ctrl.state;
        final bearingOff =
            s.board.borneOff(Side.white) > 0 ||
            s.board.borneOff(Side.black) > 0;
        if (!bearingOff) continue;
        bearOffFrames++;
        final where = 'match $m, bear-off frame $bearOffFrames';
        expect(
          st['components'],
          lessThanOrEqualTo(baseComponents! + 2),
          reason: 'components grew during bear-off ($where)',
        );
        expect(st['particles'], lessThanOrEqualTo(FxLayer.maxParticles));
        expect(st['popups'], lessThanOrEqualTo(FxLayer.maxPopups));
        expect(audio.activeCount, lessThanOrEqualTo(audio.maxActive));
        expect(
          backend.voices,
          hasLength(players),
          reason: 'new player ($where)',
        );
        expect(
          ctrl.listenerCount,
          baseListeners,
          reason: 'listeners changed during bear-off ($where)',
        );
      }
      expect(session.match.isOver, isTrue, reason: 'match $m stalled');
      expect(bearOffFrames, greaterThan(10), reason: 'match $m bear-off');
      // Let the game-over effects and every sound finish.
      for (var i = 0; i < 50; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      expect(tester.takeException(), isNull, reason: 'match $m');
      final g = BoardGame.current!;
      weak.add(WeakReference(g));
      final end = g.debugStats();
      firstBaseline ??= baseComponents;
      expect(
        end['components'],
        lessThanOrEqualTo(baseComponents! + 2),
        reason: 'match $m: components did not return to baseline',
      );
      expect(baseComponents, lessThanOrEqualTo(firstBaseline! + 2));
      expect(end['images'], lessThanOrEqualTo(2));
      expect(audio.stats.resets, 0, reason: 'audio needed a reset');
      expect(MatchController.live, lessThanOrEqualTo(1));
      // One text layout per popup, never one per frame.
      expect(
        FxLayer.debugPopupLayouts - layoutsBefore,
        lessThanOrEqualTo(FxLayer.debugPopupsCreated - popupsBefore),
        reason: 'popup text laid out per frame in match $m',
      );
      rss.add(ProcessInfo.currentRss / (1 << 20));
    }

    // Tear the last screen down: everything must be released.
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 5));
    expect(MatchController.live, 0, reason: 'controllers leaked');
    expect(BoardGame.current, isNull, reason: 'scene leaked');
    expect(backend.live, hasLength(players));

    // Churn the heap so the GC runs: finished matches' scenes must be
    // collectable (nothing keeps a reference to them).
    for (var k = 0; k < 80; k++) {
      List<List<int>>.generate(4000, (i) => List.filled(500, i)).clear();
      await tester.pump(const Duration(milliseconds: 10));
    }
    final alive = weak.where((w) => w.target != null).length;
    expect(
      alive,
      // GC timing varies; a real leak keeps every scene alive.
      lessThanOrEqualTo(8),
      reason: '$alive/$matches scenes leaked',
    );

    double avg(Iterable<double> l) => l.reduce((a, b) => a + b) / l.length;
    final growth = avg(rss.skip(matches - 5)) - avg(rss.take(5));
    debugPrint('SOAK rss growth ${growth.round()} MB, scenes alive $alive');
    // Loose bound: flutter_tester's RSS also holds its software rasterizer
    // caches; object-level leaks are caught exactly above.
    expect(growth, lessThan(300), reason: 'memory grew ${growth.round()} MB');
    expect(audio.stats.played, greaterThan(1000));
  }, timeout: const Timeout(Duration(minutes: 30)));
}
