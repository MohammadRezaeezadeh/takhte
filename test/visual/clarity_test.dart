// Item 8 regressions: the "Double Down" card is renamed, the cube offer
// explains itself, and the "?" button explains the board.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:haftnard/core/ai/personality.dart';
import 'package:haftnard/core/effects/cards.dart';
import 'package:haftnard/core/rules/match.dart';
import 'package:haftnard/game/match_controller.dart';
import 'package:haftnard/ui/game/overlays.dart';
import 'package:haftnard/ui/game/seven_overlay.dart';
import 'package:haftnard/ui/screens/game_screen.dart';

import 'flows_test.dart' show pump;

void main() {
  setUpAll(() {
    SevenOverlay.useSensors = false;
    kAiUseIsolates = false;
  });

  test('the roll-twice card is no longer called "Double"/"دوبل"', () {
    final c = cardById(CardId.doubleDown);
    expect(c.nameEn, 'Roll Again');
    expect(c.nameFa, 'تاس دوباره');
    for (final card in kCards) {
      expect(card.nameFa, isNot('دوبل'));
    }
  });

  testWidgets('cube offer says what accepting and declining mean', (t) async {
    await pump(
      t,
      Scaffold(
        body: CubeOfferPanel(
          name: 'Fox',
          value: 4,
          onTake: () {},
          onDrop: () {},
        ),
      ),
    );
    expect(find.textContaining('decline and lose 2 now'), findsOneWidget);
  });

  testWidgets('"?" opens a panel explaining the board', (t) async {
    final session = MatchSession(
      match: MatchState(const MatchConfig(seed: 5)),
      white: const SeatConfig.human('Me'),
      black: const SeatConfig.ai(
        personalityId: 'fox',
        difficulty: Difficulty.easy,
        name: 'B',
      ),
    );
    await pump(t, GameScreen(session: session));
    await t.tap(find.byKey(const ValueKey('board-help')));
    for (var i = 0; i < 10; i++) {
      await t.pump(const Duration(milliseconds: 50));
    }
    expect(find.text('How to read the board'), findsOneWidget);
    expect(find.textContaining('certain after 12 dry turns'), findsOneWidget);
    expect(find.textContaining('Bar (middle)'), findsOneWidget);
  });
}
