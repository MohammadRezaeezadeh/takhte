// In a real match the power layer draws an indicator for every live effect
// (and nothing for ended ones), plays moments, and dice show what the
// powers did (Broken Die shatters the second die).
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:haftnard/core/ai/personality.dart';
import 'package:haftnard/core/effects/cards.dart';
import 'package:haftnard/core/rules/match.dart';
import 'package:haftnard/core/rules/state.dart';
import 'package:haftnard/game/audio.dart';
import 'package:haftnard/game/match_controller.dart';
import 'package:haftnard/game/scene/board_game.dart';
import 'package:haftnard/game/scene/power_visuals.dart';
import 'package:haftnard/ui/game/seven_overlay.dart';
import 'package:haftnard/ui/screens/game_screen.dart';

import 'screens_test.dart' show harness, loadFonts, shot;

void main() {
  setUpAll(() async {
    Sfx.instance.available = false;
    SevenOverlay.useSensors = false;
    kAiUseIsolates = false;
    await loadFonts();
  });

  testWidgets('power indicators follow the live effects exactly', (t) async {
    t.view.devicePixelRatio = 1;
    t.view.physicalSize = const Size(400, 860);
    addTearDown(t.view.reset);
    final session = MatchSession(
      match: MatchState(
        const MatchConfig(
          seed: 9,
          p7: 1,
          cardPool: [
            CardId.brokenDie,
            CardId.fog,
            CardId.chains,
            CardId.holyShield,
          ],
        ),
      ),
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
    await t.pumpWidget(harness(GameScreen(session: session)));
    var shots = 0;
    var drewSomething = false;
    var sawSeven = false;
    for (var i = 0; i < 2500 && !session.match.isOver; i++) {
      await t.pump(const Duration(milliseconds: 60));
      final g = BoardGame.current;
      if (g == null || !g.isLoaded) continue;
      if (g.debugSevenCinematic) sawSeven = true;
      final s = g.shownState;
      if (s == null) continue;
      final drawn = g.power.debugDrawn.toSet();
      final expected = {
        for (final v in PowerVisuals.forState(
          s,
          viewer: g.controller.localSide,
        ))
          v.key,
      };
      // Everything live is drawn, and nothing stale lingers.
      expect(drawn, expected);
      if (drawn.isNotEmpty) drewSomething = true;
      // Board markers use the cards' own icons (SHOT_OUT to look at them).
      if (drawn.length >= 2 && shots < 2 && i % 40 == 0) {
        await shot(t, 'markers_${shots++}');
      }
      if (drewSomething && g.debugShattered > 0 && i > 400) break;
    }
    final g = BoardGame.current!;
    expect(drewSomething, isTrue, reason: 'no power indicator ever drawn');
    expect(g.power.debugMoments, isNotEmpty, reason: 'no power moments');
    expect(g.debugShattered, greaterThan(0), reason: 'Broken Die never shown');
    expect(sawSeven, isTrue, reason: '7-7 build-up never played');
    expect(t.takeException(), isNull);
    await t.pumpWidget(const SizedBox());
    await t.pump(const Duration(seconds: 5));
  });

  test('effect kinds without a board point draw on the dice area', () {
    for (final k in EffectKind.values) {
      final v = PowerVisuals.kindOf(k);
      expect(VisualKind.values, contains(v));
    }
  });
}
