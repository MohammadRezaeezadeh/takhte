// Regressions for the dice: exactly two dice are thrown (a double clones
// its twins only after landing) and landed dice never change face,
// position or order.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:haftnard/core/ai/personality.dart';
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

  testWidgets('dice: two thrown, doubles clone after landing, faces stable', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(400, 860);
    addTearDown(tester.view.reset);
    final svc = SaveService(MemorySaveStore());
    svc.data.settings = const Settings(sound: false, music: false);
    final session = MatchSession(
      match: MatchState(const MatchConfig(mode: GameMode.classic, seed: 21)),
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
        overrides: [saveServiceProvider.overrideWithValue(svc)],
        child: HaftNardApp(home: GameScreen(session: session)),
      ),
    );
    List<({int value, Offset pos, bool used, bool landed})>? prev;
    Object? prevRoll;
    var doublesSeen = 0;
    var rollsSeen = 0;
    for (var i = 0; i < 6000 && !session.match.isOver; i++) {
      await tester.pump(const Duration(milliseconds: 16));
      final g = BoardGame.current;
      if (g == null || !g.isLoaded) continue;
      final dice = g.debugDice();
      final st = g.controller.state;
      final roll = (st.turnNumber, st.rollsThisTurn, st.current);

      if (dice.length == 4) {
        expect(
          dice[1].landed && dice[2].landed,
          isTrue,
          reason: 'four dice while the thrown pair was still in the air',
        );
      }
      expect(
        dice.where((d) => !d.landed).length,
        lessThanOrEqualTo(3),
        reason: 'more than the thrown dice tumbling at once',
      );

      final allLanded = dice.isNotEmpty && dice.every((d) => d.landed);
      if (prev != null && roll == prevRoll && allLanded) {
        final p = prev;
        if (p.length == dice.length && p.every((d) => d.landed)) {
          for (var k = 0; k < dice.length; k++) {
            expect(dice[k].value, p[k].value, reason: 'face changed');
            expect(
              dice[k].pos,
              p[k].pos,
              reason:
                  'die moved after landing: ${st.phase} t${st.turnNumber} $p -> $dice',
            );
            if (p[k].used) expect(dice[k].used, isTrue, reason: 'un-dimmed');
          }
        }
      }
      if (allLanded && roll != prevRoll) {
        rollsSeen++;
      }
      if (allLanded && dice.length == 4 && (prev == null || prev.length != 4)) {
        doublesSeen++;
        expect(dice.map((d) => d.value).toSet(), hasLength(1));
      }
      if (allLanded) {
        prev = dice;
        prevRoll = roll;
      }
    }
    for (var i = 0; i < 40; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 5));
    expect(rollsSeen, greaterThan(20));
    expect(doublesSeen, greaterThan(0), reason: 'no double was rolled');
    expect(tester.takeException(), isNull);
  });
}
