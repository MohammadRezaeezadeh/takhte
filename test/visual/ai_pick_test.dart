// Playtest round 3: the opponent's 7–7 pick stays on screen until the player
// taps «فهمیدم» (8 s fallback), the game waits meanwhile, the card then flies
// to its target, and the history lists it. Delayed cards fly their HUD chip
// in when they fire.
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
import 'package:haftnard/ui/widgets/jewel.dart';

Future<MatchSession> start(WidgetTester t, List<String> pool) async {
  t.view.devicePixelRatio = 1;
  t.view.physicalSize = const Size(420, 900);
  final svc = SaveService(MemorySaveStore());
  svc.data.settings = const Settings(
    language: 'en',
    sound: false,
    music: false,
    tutorialDone: true,
    sevenGuideDone: true,
  );
  final session = MatchSession(
    match: MatchState(MatchConfig(seed: 4, p7: 1, cardPool: pool)),
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
  return session;
}

/// Plays the human seat until [until] is true (or the budget runs out).
Future<void> playUntil(WidgetTester t, bool Function() until) async {
  final brain = AiBrain(const AiConfig(difficulty: Difficulty.easy));
  for (var i = 0; i < 4000 && !until(); i++) {
    await t.pump(const Duration(milliseconds: 50));
    final g = BoardGame.current;
    if (g == null || !g.isLoaded) continue;
    final c = g.controller;
    if (!c.waitingForHuman) continue;
    final s = c.state;
    switch (s.phase) {
      case Phase.opening:
        unawaited(c.act(const RollOpening()));
      case Phase.preRoll:
        unawaited(c.act(const RollDice()));
      case Phase.sevenPick:
        unawaited(c.act(const PickCard(0)));
      case Phase.moving:
        unawaited(c.act(brain.decide(s).first));
      default:
        break;
    }
  }
}

Finder get overlay => find.byKey(const ValueKey('ai-pick-overlay'));

void main() {
  setUpAll(() {
    Sfx.instance.available = false;
    SevenOverlay.useSensors = false;
    kAiUseIsolates = false;
  });

  testWidgets(
    'AI pick waits for «Got it»; then it flies and is in the history',
    (t) async {
      await start(t, const [CardId.fog]);
      await playUntil(t, () => overlay.evaluate().isNotEmpty);
      expect(overlay, findsOneWidget);
      expect(find.text('Your opponent picked this card'), findsOneWidget);
      final c = BoardGame.current!.controller;
      final frozen = (c.state.turnNumber, c.state.phase, c.state.dice.length);
      for (var i = 0; i < 25; i++) {
        await t.pump(const Duration(milliseconds: 200));
      }
      expect(overlay, findsOneWidget, reason: 'still waiting after 5 s');
      expect(
        (c.state.turnNumber, c.state.phase, c.state.dice.length),
        frozen,
        reason: 'the game must wait while the player reads',
      );
      await t.tap(find.byKey(const ValueKey('ai-pick-ack')));
      await t.pump(const Duration(milliseconds: 100));
      expect(overlay, findsNothing);
      var flew = false;
      for (var i = 0; i < 20 && !flew; i++) {
        await t.pump(const Duration(milliseconds: 50));
        flew = find.byKey(const ValueKey('card-flight')).evaluate().isNotEmpty;
      }
      expect(flew, isTrue, reason: 'the card flies to its target');
      for (var i = 0; i < 30; i++) {
        await t.pump(const Duration(milliseconds: 50));
      }
      expect(find.byKey(const ValueKey('card-flight')), findsNothing);
      await t.tap(find.byKey(const ValueKey('card-history-button')));
      await t.pump(const Duration(milliseconds: 300));
      expect(find.byKey(const ValueKey('card-history')), findsOneWidget);
      expect(find.textContaining('Fox · Fog'), findsWidgets);
      await t.pumpWidget(const SizedBox());
      await t.pump(const Duration(seconds: 10));
    },
  );

  testWidgets('AI pick auto-continues after 8 s without a tap', (t) async {
    await start(t, const [CardId.fog]);
    await playUntil(t, () => overlay.evaluate().isNotEmpty);
    expect(overlay, findsOneWidget);
    for (var i = 0; i < 35; i++) {
      await t.pump(const Duration(milliseconds: 200));
    }
    expect(overlay, findsOneWidget, reason: 'still up at 7 s');
    for (var i = 0; i < 10; i++) {
      await t.pump(const Duration(milliseconds: 200));
    }
    expect(overlay, findsNothing, reason: 'gone after 8 s');
    await t.pumpWidget(const SizedBox());
    await t.pump(const Duration(seconds: 10));
  });

  testWidgets('a delayed card flies its chip in when it fires', (t) async {
    GameScreen.debugChipFlights = 0;
    await start(t, const [CardId.luckySix]);
    await playUntil(t, () {
      final ack = find.byKey(const ValueKey('ai-pick-ack'));
      if (ack.evaluate().isNotEmpty) {
        t.widget<JewelButton>(ack).onPressed?.call();
      }
      return GameScreen.debugChipFlights > 0;
    });
    expect(GameScreen.debugChipFlights, greaterThan(0));
    expect(t.takeException(), isNull);
    await t.pumpWidget(const SizedBox());
    await t.pump(const Duration(seconds: 10));
  });
}
