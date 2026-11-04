import 'package:haftnard/core/ai/ai.dart';
import 'package:haftnard/core/ai/personality.dart';
import 'package:haftnard/core/rules/actions.dart';
import 'package:haftnard/core/rules/board.dart';
import 'package:haftnard/core/rules/engine.dart';
import 'package:haftnard/core/rules/state.dart';
import 'package:haftnard/core/rules/types.dart';
import 'package:test/test.dart';

import 'helpers.dart';

/// Plays a full AI-vs-AI game; every AI action must be legal.
GameState aiGame(GameConfig cfg, AiConfig white, AiConfig black) {
  var s = GameState.initial(cfg);
  final brains = {Side.white: AiBrain(white), Side.black: AiBrain(black)};
  var guard = 0;
  while (!s.isOver && guard++ < 3000) {
    final actor = Engine.actor(s);
    final actions = brains[actor]!.decide(s);
    expect(actions, isNotEmpty, reason: 'AI produced nothing in ${s.phase}');
    for (final a in actions) {
      if (s.isOver) break;
      // Re-plan if a hidden mine changed the position mid-play.
      if (a is PlayMove && !Engine.legalMoves(s).contains(a.move)) break;
      if (a is EndTurn && !Engine.canEndTurn(s)) break;
      s = Engine.apply(s, a).state;
      expect(s.board.validate(), isNull);
    }
  }
  expect(s.isOver, isTrue);
  return s;
}

void main() {
  test('every difficulty plays complete legal classic games', () {
    for (final d in Difficulty.values) {
      aiGame(
        GameConfig(mode: GameMode.classic, seed: d.index + 1),
        AiConfig(difficulty: d),
        AiConfig(difficulty: d, seed: 9),
      );
    }
  });

  test('AI handles seven mode with all personalities', () {
    for (var i = 0; i < kPersonalities.length; i++) {
      aiGame(
        GameConfig(seed: 100 + i, p7: 0.25, cubeEnabled: true),
        AiConfig(personalityId: kPersonalities[i].id),
        AiConfig(
          personalityId: kPersonalities[(i + 1) % kPersonalities.length].id,
          difficulty: Difficulty.easy,
        ),
      );
    }
  });

  test('AI never gets stuck with heavy card usage (traps, chains)', () {
    for (var g = 0; g < 30; g++) {
      aiGame(
        GameConfig(seed: 10000 + g, p7: 0.3),
        AiConfig(seed: g, personalityId: kPersonalities[g % 5].id),
        AiConfig(seed: g + 1, personalityId: kPersonalities[(g + 2) % 5].id),
      );
    }
  });

  test('medium AI beats beginner more often than not', () {
    var wins = 0;
    const games = 24;
    for (var g = 0; g < games; g++) {
      final s = aiGame(
        GameConfig(mode: GameMode.classic, seed: 500 + g),
        const AiConfig(),
        const AiConfig(difficulty: Difficulty.beginner),
      );
      if (s.result!.winner == Side.white) wins++;
    }
    expect(wins, greaterThan(games * 0.6));
  });

  test('AI hits a blot when it is clearly right', () {
    // White checker can hit a black blot in black's outer board for free.
    final b = Board.fromMaps(
      white: const {8: 1, 6: 14},
      black: const {25 - 5: 1, 1: 14},
    );
    final s = movingState(b, [3, 1]);
    final play = AiBrain(const AiConfig(difficulty: Difficulty.hard))
        .bestPlay(s);
    expect(play.any((m) => m.hit), isTrue);
  });

  test('AI picks Blood Pact only when home', () {
    final home = Board.fromMaps(white: const {6: 5, 5: 5, 4: 5});
    final brain = AiBrain(const AiConfig());
    final s1 = sevenState(home, ['blood_pact', 'fog', 'greed']);
    expect(brain.pickCard(s1), 0);
    final s2 = sevenState(Board.initial(), ['blood_pact', 'fog', 'greed']);
    expect(brain.pickCard(s2), isNot(0));
  });

  test('decideAsync runs on an isolate', () async {
    final s = movingState(Board.initial(), [6, 5]);
    final actions = await AiBrain.decideAsync(
      s,
      const AiConfig(difficulty: Difficulty.master),
    );
    expect(actions.last, isA<EndTurn>());
    expect(actions.whereType<PlayMove>().length, 2);
  });
}
