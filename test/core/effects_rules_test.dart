// Edge cases where effects interact with core movement rules.
import 'package:haftnard/core/rules/board.dart';
import 'package:haftnard/core/rules/move_gen.dart';
import 'package:haftnard/core/rules/types.dart';
import 'package:test/test.dart';

import 'helpers.dart';

List<Move> legalCtx(Board b, List<int> dice, MoveContext ctx) =>
    MoveGen.legalMoves(TurnSim.fromBoard(b, Side.white, ctx), dice);

void main() {
  test('a frozen checker on a higher point still blocks over-bearing', () {
    final b = Board.fromMaps(white: const {5: 1, 2: 1});
    const ctx = MoveContext(frozen: {5: 1});
    final moves = legalCtx(b, [6], ctx);
    // The 5-point checker cannot move and still counts as "higher":
    // the 2-point checker cannot bear off with a 6, and nothing else moves.
    expect(moves, isEmpty);
  });

  test('frozen checkers outside home prevent bearing off entirely', () {
    final b = Board.fromMaps(white: const {8: 1, 3: 2});
    const ctx = MoveContext(frozen: {8: 1});
    final moves = legalCtx(b, [3, 1], ctx);
    expect(moves.any((m) => m.isBearOff), isFalse);
    expect(
      moveStrings(moves),
      containsAll(['3/0(3)'.replaceAll('3/0(3)', '3/2(1)')]),
    );
  });

  test('toll gate turns an exact bear-off into a normal move', () {
    final b = Board.fromMaps(white: const {4: 1, 1: 1});
    // Toll on point 2 (crossed strictly by 4 -> 0).
    const ctx = MoveContext(tollMask: 1 << 2);
    final moves = legalCtx(b, [4], ctx);
    // 4 - 4 = 0 natural; crossing 2 (and 1, 3 are not tolls) costs +1 -> lands on 1.
    expect(moveStrings(moves), contains('4/1(4)'));
    expect(moves.any((m) => m.from == 4 && m.isBearOff), isFalse);
  });

  test('ghost step never glides off the board', () {
    // Black blocks white's 2 and 1 points: a 3 from 5 is blocked at 2, the next
    // open point beyond would be off the board - not allowed.
    final b = Board.fromMaps(
      white: const {5: 1, 13: 14},
      black: const {23: 2, 24: 2, 1: 11},
    );
    const ctx = MoveContext(ghostCharges: 1);
    final moves = legalCtx(b, [3], ctx);
    expect(moves.any((m) => m.from == 5 && m.ghost), isFalse);
  });

  test('a protected lone checker blocks bar entry', () {
    final b = Board.fromMaps(
      white: const {25: 1, 13: 14},
      black: const {4: 1, 1: 14},
    );
    // Black's lone checker on its 4 = white relative 21, entry with a 4.
    const ctx = MoveContext(protectedMask: 1 << 21);
    final moves = legalCtx(b, [4, 4, 4, 4], ctx);
    expect(moves, isEmpty);
  });

  test(
    'a mine on the entry point sends the entering checker straight back',
    () {
      final b = Board.fromMaps(
        white: const {25: 1, 13: 14},
        black: const {1: 15},
      );
      final sim = TurnSim.fromBoard(
        b,
        Side.white,
        const MoveContext(mineMask: 1 << 22),
      );
      final m = MoveGen.legalMoves(sim, [3, 5]).firstWhere((m) => m.to == 22);
      final out = sim.apply(m);
      expect(out.mined, isTrue);
      expect(sim.mine[Pos.bar], 1);
      // With the 5 remaining it must enter again.
      expect(
        MoveGen.legalMoves(sim, [5]).every((m) => m.from == Pos.bar),
        isTrue,
      );
    },
  );

  test('phoenix re-entry never lands on a point the mover holds', () {
    // White hits a black blot; black has Phoenix. White holds points 1..5.
    final b = Board.fromMaps(
      white: const {7: 1, 1: 2, 2: 2, 3: 2, 4: 2, 5: 2, 13: 4},
      black: const {19: 1, 13: 14},
    );
    final sim = TurnSim.fromBoard(
      b,
      Side.white,
      const MoveContext(opponentPhoenix: true),
    );
    // Black blot at black rel 19 = white rel 6; white 7 -> 6 hits.
    final hit = MoveGen.legalMoves(sim, [1]).firstWhere((m) => m.hit);
    final out = sim.apply(hit);
    expect(out.phoenixUsed, isTrue);
    // Re-entry point (opponent relative) must not be one White holds.
    expect(sim.mine[25 - out.phoenixPoint], 0);
    expect(sim.toBoard(Side.white).validate(), isNull);
  });
}
