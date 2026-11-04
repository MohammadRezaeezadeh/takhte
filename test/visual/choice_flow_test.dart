// End-to-end 7–7 flow in a real game: AI pick reveal, board preview,
// targeting with progress/undo/confirm, and the result banner.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:haftnard/core/ai/ai.dart';
import 'package:haftnard/core/ai/personality.dart';
import 'package:haftnard/core/effects/cards.dart';
import 'package:haftnard/core/rules/actions.dart';
import 'package:haftnard/core/rules/match.dart';
import 'package:haftnard/core/rules/state.dart';
import 'package:haftnard/game/audio.dart';
import 'package:haftnard/game/match_controller.dart';
import 'package:haftnard/game/scene/board_game.dart';
import 'package:haftnard/meta/meta_state.dart';
import 'package:haftnard/meta/save.dart';
import 'package:haftnard/meta/settings.dart';
import 'package:haftnard/ui/app.dart';
import 'package:haftnard/ui/game/seven_overlay.dart';
import 'package:haftnard/ui/screens/game_screen.dart';

void main() {
  setUpAll(() {
    Sfx.instance.available = false;
    SevenOverlay.useSensors = false;
    kAiUseIsolates = false;
  });

  testWidgets('7-7 flow: AI reveal, preview, targeting, result', (t) async {
    t.view.devicePixelRatio = 1;
    t.view.physicalSize = const Size(420, 900);
    addTearDown(t.view.reset);
    final svc = SaveService(MemorySaveStore());
    svc.data.settings = const Settings(
      language: 'en',
      sound: false,
      music: false,
      tutorialDone: true,
      sevenGuideDone: true,
    );
    final session = MatchSession(
      match: MatchState(
        const MatchConfig(seed: 4, p7: 1, cardPool: [CardId.chains]),
      ),
      white: const SeatConfig.human('Me'),
      black: const SeatConfig.ai(
        personalityId: 'fox',
        difficulty: Difficulty.easy,
        name: 'Fox',
      ),
    );
    await t.pumpWidget(
      ProviderScope(
        overrides: [saveServiceProvider.overrideWithValue(svc)],
        child: HaftNardApp(home: GameScreen(session: session)),
      ),
    );
    var sawReveal = false;
    var sawPreview = false;
    var targeted = false;
    var sawResult = false;
    final brain = AiBrain(const AiConfig(difficulty: Difficulty.easy));
    for (var i = 0; i < 3000 && !sawResult; i++) {
      await t.pump(const Duration(milliseconds: 50));
      if (find.byKey(const ValueKey('ai-reveal')).evaluate().isNotEmpty) {
        sawReveal = true;
      }
      if (find.byKey(const ValueKey('result-banner')).evaluate().isNotEmpty) {
        sawResult = true;
      }
      final g = BoardGame.current;
      if (g == null || !g.isLoaded) continue;
      final c = g.controller;
      final s = c.state;
      if (!c.waitingForHuman) continue;
      switch (s.phase) {
        case Phase.opening:
          unawaited(c.act(const RollOpening()));
          await t.pump(const Duration(milliseconds: 50));
        case Phase.preRoll:
          unawaited(c.act(const RollDice()));
          await t.pump(const Duration(milliseconds: 50));
        case Phase.moving:
          // One action per frame so the presenter can animate it.
          final a = brain.decide(s).first;
          unawaited(c.act(a));
          await t.pump(const Duration(milliseconds: 50));
        case Phase.sevenPick:
          final card = find.byKey(const ValueKey('offer-0'));
          if (card.evaluate().isEmpty) continue;
          // Let the deal-in animation finish before touching a card.
          for (var k = 0; k < 25; k++) {
            await t.pump(const Duration(milliseconds: 100));
          }
          await t.tap(card);
          await t.pump(const Duration(milliseconds: 300));
          sawPreview = g.debugPreviewing;
          await t.tap(find.byKey(const ValueKey('pick-card')));
          await t.pump(const Duration(milliseconds: 300));
        case Phase.cardTarget:
          if (targeted) continue;
          targeted = true;
          expect(find.byKey(const ValueKey('target-banner')), findsOneWidget);
          expect(find.textContaining('(0/2)'), findsOneWidget);
          final first = g.targetable.first;
          g.onTargetTap!(first);
          await t.pump(const Duration(milliseconds: 100));
          expect(find.textContaining('(1/2)'), findsOneWidget);
          await t.tap(find.byKey(const ValueKey('target-undo')));
          await t.pump(const Duration(milliseconds: 100));
          expect(find.textContaining('(0/2)'), findsOneWidget);
          g.onTargetTap!(g.targetable.first);
          await t.pump(const Duration(milliseconds: 100));
          g.onTargetTap!(g.targetable.first);
          await t.pump(const Duration(milliseconds: 100));
          expect(c.state.phase, Phase.cardTarget, reason: 'waits for Confirm');
          await t.tap(find.byKey(const ValueKey('target-confirm')));
          await t.pump(const Duration(milliseconds: 100));
        default:
          break;
      }
    }
    expect(sawReveal, isTrue, reason: 'AI pick not shown in the centre');
    expect(sawPreview, isTrue, reason: 'no board preview');
    expect(targeted, isTrue);
    expect(sawResult, isTrue, reason: 'no result banner');
    expect(t.takeException(), isNull);
    await t.pumpWidget(const SizedBox());
    await t.pump(const Duration(seconds: 5));
  });
}
