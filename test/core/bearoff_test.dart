// The exact bear-off table: ranks are a bijection, stored values match a
// fresh computation and hand-checked positions, and the AI plays the
// table's best move in pure bear-off races.
import 'dart:math' as math;

import 'package:haftnard/core/ai/ai.dart';
import 'package:haftnard/core/ai/bearoff.dart';
import 'package:haftnard/core/ai/personality.dart';
import 'package:haftnard/core/rules/board.dart';
import 'package:haftnard/core/rules/move_gen.dart';
import 'package:haftnard/core/rules/state.dart';
import 'package:haftnard/core/rules/types.dart';
import 'package:test/test.dart';

List<int> home(Map<int, int> m) {
  final a = List.filled(26, 0);
  var on = 0;
  m.forEach((p, n) {
    a[p] = n;
    on += n;
  });
  a[0] = 15 - on;
  return a;
}

void main() {
  test('ranks cover every position exactly once', () {
    final all = BearOff.allPositions();
    expect(all.length, BearOff.size);
    final seen = <int>{};
    for (final c in all) {
      final i = BearOff.index(c);
      expect(i, inInclusiveRange(0, BearOff.size - 1));
      expect(seen.add(i), isTrue);
    }
  });

  test('hand-checked values', () {
    expect(BearOff.expectedRolls(home({})), 0);
    expect(BearOff.expectedRolls(home({1: 1})), 1);
    // Four on the ace point: a double clears them (1/6), otherwise 2 rolls.
    expect(BearOff.expectedRolls(home({1: 4})), closeTo(11 / 6, 1e-3));
    // One checker on the 6-point fails only with 11, 21, 31, 41, 32
    // (9/36), and every leftover comes off next roll.
    expect(BearOff.expectedRolls(home({6: 1})), closeTo(1.25, 1e-3));
    // Further back is never better.
    expect(
      BearOff.expectedRolls(home({6: 15})),
      greaterThan(BearOff.expectedRolls(home({1: 15}))),
    );
  });

  test('the stored table matches a fresh computation (up to 6 checkers)', () {
    final fresh = BearOff.compute(maxTotal: 6);
    for (final c in BearOff.allPositions()) {
      if (c.fold(0, (a, b) => a + b) > 6) continue;
      final i = BearOff.index(c);
      final stored = BearOff.expectedRolls([
        15 - c.fold(0, (a, b) => a + b),
        ...c.sublist(1),
        ...List.filled(19, 0),
      ]);
      expect(stored, closeTo(fresh[i], 1 / BearOff.scale), reason: '$c');
    }
  });

  test('the AI bears off with the table-optimal play', () {
    final brain = AiBrain(
      const AiConfig(difficulty: Difficulty.hard, plies: 1),
    );
    final rng = math.Random(3);
    var checked = 0;
    for (var k = 0; k < 120; k++) {
      Map<int, int> rand() {
        final m = <int, int>{};
        final n = 3 + rng.nextInt(10);
        for (var i = 0; i < n; i++) {
          final p = 1 + rng.nextInt(6);
          m[p] = (m[p] ?? 0) + 1;
        }
        return m;
      }

      final w = rand();
      final b = rand();
      final a = 1 + rng.nextInt(6);
      final d = 1 + rng.nextInt(6);
      final s =
          GameState.initial(
            GameConfig(
              startingBoard: Board.fromMaps(white: w, black: b),
              p7: 0,
            ),
          ).copyWith(
            phase: Phase.moving,
            current: Side.white,
            dice: a == d ? [a, a, a, a] : [a, d],
          );
      final sim = TurnSim.fromBoard(s.board, Side.white);
      final plays = MoveGen.allPlays(sim, s.dice);
      if (plays.length < 2) continue;
      final best = plays
          .map((p) => BearOff.expectedRolls(p.result.mine))
          .reduce(math.min);
      final chosen = brain.bestPlay(s);
      final mine = plays
          .firstWhere((p) => '${p.moves}' == '$chosen')
          .result
          .mine;
      expect(
        BearOff.expectedRolls(mine),
        closeTo(best, 1e-9),
        reason: 'white $w black $b dice ${s.dice}',
      );
      checked++;
    }
    expect(checked, greaterThan(60));
  });
}
