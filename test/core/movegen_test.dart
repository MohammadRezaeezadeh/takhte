import 'package:haftnard/core/rules/actions.dart';
import 'package:haftnard/core/rules/board.dart';
import 'package:haftnard/core/rules/engine.dart';
import 'package:haftnard/core/rules/move_gen.dart';
import 'package:haftnard/core/rules/state.dart';
import 'package:haftnard/core/rules/types.dart';
import 'package:test/test.dart';

import 'helpers.dart';

void main() {
  group('board', () {
    test('initial position is valid with 167 pips each', () {
      final b = Board.initial();
      expect(b.validate(), isNull);
      expect(b.pips(Side.white), 167);
      expect(b.pips(Side.black), 167);
    });

    test('absolute mapping', () {
      final b = Board.initial();
      expect(b.atAbsolute(24), (Side.white, 2));
      expect(b.atAbsolute(1), (Side.black, 2));
      expect(b.atAbsolute(6), (Side.white, 5));
      expect(b.atAbsolute(19), (Side.black, 5));
      expect(b.atAbsolute(12), (Side.black, 5));
      expect(b.atAbsolute(13), (Side.white, 5));
    });
  });

  group('basic moves', () {
    test('opening 3-1 offers the 8/5 6/5 point', () {
      final moves = legal(Board.initial(), [3, 1]);
      final s = moveStrings(moves);
      expect(s, containsAll(['8/5(3)', '6/5(1)', '24/21(3)', '24/23(1)']));
      // 6/3 is fine (empty), 13/10 fine.
      expect(s, contains('13/10(3)'));
      // Black occupies white's 12 (black rel 13): 13/12 is blocked? No — black
      // holds 5 on absolute 12, so 13/12 with a 1 must be blocked.
      expect(s, isNot(contains('13/12(1)')));
    });

    test('a point with 2+ opposing checkers is blocked', () {
      final b = Board.fromMaps(white: const {10: 1}, black: const {25 - 7: 2});
      expect(moveStrings(legal(b, [3, 5])), isNot(contains('10/7(3)')));
    });

    test('hitting a blot is flagged', () {
      final b = Board.fromMaps(
        white: const {10: 1},
        black: const {25 - 7: 1, 24: 1},
      );
      final m = legal(b, [3, 5]).firstWhere((m) => m.from == 10 && m.to == 7);
      expect(m.hit, isTrue);
    });

    test('doubles give four moves', () {
      final s = movingState(Board.initial(), [6, 6, 6, 6]);
      final after = play(s, [(24, 18), (24, 18), (13, 7), (13, 7)]);
      expect(after.dice, isEmpty);
      expect(Engine.canEndTurn(after), isTrue);
    });
  });

  group('bar', () {
    test('entering from the bar is mandatory', () {
      final b = Board.fromMaps(white: const {25: 1, 13: 5, 6: 9});
      final moves = legal(b, [3, 5]);
      expect(moves.every((m) => m.from == Pos.bar), isTrue);
      expect(moveStrings(moves), {'25/22(3)', '25/20(5)'});
    });

    test('blocked entry means no moves at all', () {
      final b = Board.fromMaps(
        white: const {25: 1, 13: 14},
        black: {for (var p = 1; p <= 6; p++) p: 2},
      );
      expect(legal(b, [3, 5]), isEmpty);
    });

    test('two on the bar with doubles enter both then continue', () {
      final b = Board.fromMaps(white: const {25: 2, 6: 13});
      final s = movingState(b, [4, 4, 4, 4]);
      final first = Engine.legalMoves(s);
      expect(first.every((m) => m.from == Pos.bar), isTrue);
      final after = play(s, [(25, 21), (25, 21)]);
      expect(Engine.legalMoves(after).any((m) => m.from == 21), isTrue);
    });

    test('one enters, second die must be used afterwards if possible', () {
      // Only the 6-entry (19) is open; the 2 then must be played.
      final b = Board.fromMaps(
        white: const {25: 1, 13: 14},
        black: {for (var p = 1; p <= 5; p++) p: 2},
      );
      final moves = legal(b, [6, 2]);
      expect(moveStrings(moves), {'25/19(6)'});
    });
  });

  group('must use both dice', () {
    test('order matters: only the order that uses both is allowed', () {
      // White checker on 10. Black blocks 4 (=10-6) and 5.
      // With 6-1: 10/4 blocked. 10/9 then 9/3 OK. So 1 must be played first.
      final b = Board.fromMaps(
        white: const {10: 1, 1: 14},
        black: const {25 - 4: 2, 25 - 5: 2, 24: 11},
      );
      final moves = legal(b, [6, 1]);
      expect(moveStrings(moves), {'10/9(1)'});
    });

    test('a move that kills the second die is excluded', () {
      // White checkers on 8 and 13. Black blocks 2 and 7.
      // 5-1: 8/3 then 13/12 okay ... construct: both dice must be used.
      final b = Board.fromMaps(
        white: const {8: 1, 3: 14},
        black: const {25 - 2: 2, 25 - 7: 2, 24: 11},
      );
      // Dice 6-1: 8/2 blocked; 8/7 blocked; 3/off? not all home (8 outside).
      // 3/2 blocked. So 6 then? Only legal 1s: none. 6s: 8/2 blocked, 3/-3 no.
      expect(legal(b, [6, 1]), isEmpty);
    });

    test('larger die must be used when only one can be played', () {
      // White single checker on 12, others home on 1. Black blocks 6 and 2.
      // 4-2: 12/8 then 8/6 blocked; 12/10 then 10/6 blocked.
      // Either die alone is playable, so the 4 must be used.
      final b = Board.fromMaps(
        white: const {12: 1, 1: 14},
        black: const {25 - 6: 2, 25 - 2: 2, 24: 11},
      );
      final moves = legal(b, [4, 2]);
      expect(moveStrings(moves), {'12/8(4)'});
    });

    test('if only the smaller die can be played, play it', () {
      final b = Board.fromMaps(
        white: const {12: 1, 1: 14},
        black: const {25 - 8: 2, 25 - 4: 2, 24: 11},
      );
      // 4-2: 12/8 blocked, 12/10 ok then 10/6 ok -> both usable.
      // Use 5-2 instead: 12/7? block 7 and 3.
      final b2 = Board.fromMaps(
        white: const {12: 1, 1: 14},
        black: const {25 - 7: 2, 25 - 5: 2, 24: 11},
      );
      // 5-2: 12/7 blocked; 12/10 ok, then 10/5 blocked -> only the 2.
      expect(moveStrings(legal(b2, [5, 2])), {'12/10(2)'});
      expect(legal(b, [4, 2]).length, greaterThan(0));
    });
  });

  group('bearing off', () {
    test('cannot bear off with a checker outside home', () {
      final b = Board.fromMaps(white: const {7: 1, 6: 14});
      final moves = legal(b, [6, 5]);
      expect(moves.any((m) => m.isBearOff && m.from == 6), isFalse);
    });

    test(
      'bringing the last checker home allows bearing off with the other die',
      () {
        final b = Board.fromMaps(white: const {7: 1, 6: 4, 5: 0});
        final s = movingState(b, [1, 6]);
        final after = play(s, [(7, 6)]);
        expect(
          Engine.legalMoves(after).any((m) => m.isBearOff && m.from == 6),
          isTrue,
        );
      },
    );

    test('exact bear-off', () {
      final b = Board.fromMaps(white: const {3: 1, 1: 1});
      expect(moveStrings(legal(b, [3, 1])), containsAll(['3/0(3)', '1/0(1)']));
    });

    test('higher die bears off from the highest point only', () {
      final b = Board.fromMaps(white: const {4: 1, 2: 1});
      final moves = legal(b, [6, 5]);
      expect(moveStrings(moves), contains('4/0(6)'));
      expect(moveStrings(moves), isNot(contains('2/0(6)')));
    });

    test(
      'higher die cannot bear off from a lower point when higher is occupied',
      () {
        final b = Board.fromMaps(
          white: const {5: 1, 2: 1},
          black: const {25 - 4: 2, 6: 13},
        );
        // Die 4: 5/1 is legal; 2/off with a 4 is not (5 is higher).
        final moves = legal(b, [4]);
        expect(moveStrings(moves), {'5/1(4)'});
      },
    );

    test('bearing off all 15 wins', () {
      final b = Board.fromMaps(white: const {1: 2});
      final s = movingState(b, [2, 1]);
      final after = play(s, [(1, 0), (1, 0)]);
      expect(after.phase, Phase.gameOver);
      expect(after.result!.winner, Side.white);
    });
  });

  group('scoring', () {
    test('gammon when loser bore off nothing', () {
      final b = Board.fromMaps(
        white: const {1: 1},
        black: const {6: 15},
        fillOff: false,
      ).withSide(Side.white, [14, 1, ...List.filled(24, 0)]);
      final s = movingState(b, [1, 2]);
      final after = play(s, [(1, 0)]);
      expect(after.result!.type, WinType.gammon);
      expect(after.result!.points, 2);
    });

    test('backgammon when loser has a checker in winner home', () {
      final white = [14, 1, ...List<int>.filled(24, 0)];
      final black = List<int>.filled(26, 0)
        ..[20] = 1
        ..[6] = 14;
      final b = Board.fromLists(white, black);
      expect(b.validate(), isNull);
      final s = movingState(b, [1, 2]);
      final after = play(s, [(1, 0)]);
      expect(after.result!.type, WinType.backgammon);
      expect(after.result!.points, 3);
    });

    test('normal win when loser bore off some', () {
      final white = [14, 1, ...List<int>.filled(24, 0)];
      final black = List<int>.filled(26, 0)
        ..[0] = 1
        ..[6] = 14;
      final s = movingState(Board.fromLists(white, black), [1, 2]);
      expect(play(s, [(1, 0)]).result!.type, WinType.normal);
    });

    test('cube multiplies the score', () {
      final white = [14, 1, ...List<int>.filled(24, 0)];
      final black = List<int>.filled(26, 0)..[6] = 15;
      final s = movingState(Board.fromLists(white, black), [
        1,
        2,
      ]).copyWith(cubeValue: 4);
      expect(play(s, [(1, 0)]).result!.points, 8);
    });
  });

  group('turn flow', () {
    test('opening roll: higher die starts and plays both', () {
      var s = GameState.initial(
        const GameConfig(mode: GameMode.classic, seed: 9),
      );
      while (s.phase == Phase.opening) {
        s = Engine.apply(s, const RollOpening()).state;
      }
      expect(s.phase, Phase.moving);
      final o = s.openingDice;
      expect(o[0], isNot(o[1]));
      expect(s.current, o[0] > o[1] ? Side.white : Side.black);
      expect(s.dice.toSet(), {o[0], o[1]});
    });

    test('end turn is refused while moves remain', () {
      final s = movingState(Board.initial(), [3, 1]);
      expect(
        () => Engine.apply(s, const EndTurn()),
        throwsA(isA<IllegalActionException>()),
      );
    });

    test('no legal moves allows ending the turn', () {
      final b = Board.fromMaps(
        white: const {25: 1, 13: 14},
        black: {for (var p = 1; p <= 6; p++) p: 2},
      );
      final s = movingState(b, [3, 5]);
      expect(Engine.legalMoves(s), isEmpty);
      final next = Engine.apply(s, const EndTurn()).state;
      expect(next.current, Side.black);
      expect(next.phase, Phase.preRoll);
    });

    test('illegal move is rejected', () {
      final s = movingState(Board.initial(), [3, 1]);
      expect(
        () => Engine.apply(s, const PlayMove(Move(24, 20, 4))),
        throwsA(isA<IllegalActionException>()),
      );
    });
  });

  group('cube', () {
    test('offer, take, then drop scores the cube', () {
      const cfg = GameConfig(mode: GameMode.classic, cubeEnabled: true);
      var s = preRollState(Board.initial(), config: cfg);
      s = Engine.apply(s, const OfferDouble()).state;
      expect(s.phase, Phase.cubeOffered);
      s = Engine.apply(s, const TakeDouble()).state;
      expect(s.cubeValue, 2);
      expect(s.cubeOwner, Side.black);
      expect(Engine.canOfferDouble(s), isFalse);
      // Black owns the cube and redoubles on their turn.
      s = s.copyWith(current: Side.black);
      s = Engine.apply(s, const OfferDouble()).state;
      s = Engine.apply(s, const DropDouble()).state;
      expect(s.result!.winner, Side.black);
      expect(s.result!.points, 2);
    });

    test('crawford game forbids doubling', () {
      const cfg = GameConfig(cubeEnabled: true, crawford: true);
      final s = preRollState(Board.initial(), config: cfg);
      expect(Engine.canOfferDouble(s), isFalse);
    });
  });

  test('allPlays agrees with legalMoves first moves', () {
    final b = Board.initial();
    for (final dice in [
      [3, 1],
      [6, 5],
      [4, 4, 4, 4],
      [2, 1],
    ]) {
      final sim = TurnSim.fromBoard(b, Side.white);
      final plays = MoveGen.allPlays(sim, dice);
      final firsts = {for (final p in plays) p.moves.first};
      final legalFirst = MoveGen.legalMoves(sim, dice).toSet();
      expect(firsts.difference(legalFirst), isEmpty, reason: '$dice');
      expect(
        plays.every((p) => p.moves.length == plays.first.moves.length),
        isTrue,
      );
    }
  });
}
