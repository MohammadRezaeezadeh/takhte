// Soak test: 30 complete AI-vs-AI matches in one session, each through a
// fresh GameScreen + Flame scene with the real AudioManager on a fake
// backend. Object counts and memory must stay flat from match to match.
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:haftnard/core/ai/personality.dart';
import 'package:haftnard/core/rules/match.dart';
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

class _Sample {
  _Sample(this.stats, this.controllers, this.rssMb, this.voices);
  final Map<String, int> stats;
  final int controllers;
  final double rssMb;
  final int voices;
  @override
  String toString() =>
      '$stats ctrl=$controllers voices=$voices rss=${rssMb.round()}MB';
}

void main() {
  const matches = int.fromEnvironment('SOAK_MATCHES', defaultValue: 30);
  final backend = FakeBackend();

  setUpAll(() {
    SevenOverlay.useSensors = false;
    kAiUseIsolates = false;
    Sfx.instance
      ..available = true
      ..manager = AudioManager(backend);
  });

  tearDownAll(() {
    Sfx.instance
      ..manager = null
      ..available = false;
  });

  testWidgets(
    'soak: $matches matches keep components, particles, listeners and memory flat',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(400, 860);
      addTearDown(tester.view.reset);
      await Sfx.instance.preload();
      final samples = <_Sample>[];
      final weak = <WeakReference<BoardGame>>[];
      var peakParticles = 0;
      for (var m = 0; m < matches; m++) {
        final svc = SaveService(MemorySaveStore());
        svc.data.settings = const Settings(animSpeed: 2);
        final session = MatchSession(
          match: MatchState(MatchConfig(seed: 100 + m, p7: 0.12)),
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
        for (var i = 0; i < 9000 && !session.match.isOver; i++) {
          await tester.pump(const Duration(milliseconds: 120));
          final g = BoardGame.current;
          if (g != null && g.isLoaded) {
            final p = g.debugStats()['particles']!;
            if (p > peakParticles) peakParticles = p;
          }
        }
        expect(session.match.isOver, isTrue, reason: 'match $m stalled');
        // Let the game-over effects play out and settle.
        for (var i = 0; i < 40; i++) {
          await tester.pump(const Duration(milliseconds: 100));
        }
        expect(tester.takeException(), isNull, reason: 'match $m');
        final g = BoardGame.current!;
        weak.add(WeakReference(g));
        samples.add(
          _Sample(
            g.debugStats(),
            MatchController.live,
            ProcessInfo.currentRss / (1 << 20),
            backend.live.length,
          ),
        );
      }
      // Tear the last screen down: everything must be released.
      await tester.pumpWidget(const SizedBox());
      await tester.pump();
      expect(MatchController.live, 0, reason: 'controllers leaked');
      expect(BoardGame.current, isNull, reason: 'scene leaked');

      final first = samples.take(5).toList();
      final last = samples.skip(matches - 5).toList();
      int maxOf(List<_Sample> l, String k) =>
          l.map((s) => s.stats[k]!).reduce((a, b) => a > b ? a : b);
      expect(
        maxOf(last, 'components'),
        lessThanOrEqualTo(maxOf(first, 'components') + 2),
        reason: 'component count grew: ${samples.first} -> ${samples.last}',
      );
      expect(peakParticles, lessThanOrEqualTo(FxLayer.maxParticles));
      expect(maxOf(last, 'popups'), lessThanOrEqualTo(FxLayer.maxPopups));
      expect(maxOf(last, 'images'), lessThanOrEqualTo(2));
      for (final s in samples) {
        expect(s.controllers, lessThanOrEqualTo(1), reason: '$s');
        expect(s.voices, Sfx.instance.manager!.voiceCount, reason: '$s');
      }
      // Churn the heap so the GC runs: finished matches' scenes must be
      // collectable (nothing keeps a reference to them).
      for (var k = 0; k < 40; k++) {
        List<List<int>>.generate(2000, (i) => List.filled(500, i)).clear();
        await tester.pump(const Duration(milliseconds: 10));
      }
      final alive = weak.where((w) => w.target != null).length;
      expect(
        alive,
        lessThanOrEqualTo(3),
        reason: '$alive/$matches scenes leaked',
      );
      double avgRss(List<_Sample> l) =>
          l.map((s) => s.rssMb).reduce((a, b) => a + b) / l.length;
      final growth = avgRss(last) - avgRss(first);
      debugPrint('SOAK rss growth ${growth.round()} MB, scenes alive $alive');
      expect(
        growth,
        // Loose bound: flutter_tester's RSS also holds its software
        // rasterizer caches; object-level leaks are caught exactly above.
        lessThan(200),
        reason: 'memory grew ${growth.round()} MB over $matches matches',
      );
      expect(Sfx.instance.manager!.stats.played, greaterThan(500));
    },
    timeout: const Timeout(Duration(minutes: 20)),
  );
}
