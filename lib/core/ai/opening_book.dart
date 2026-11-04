import 'package:haftnard/core/rules/actions.dart';
import 'package:haftnard/core/rules/board.dart';
import 'package:haftnard/core/rules/engine.dart';
import 'package:haftnard/core/rules/state.dart';
import 'package:haftnard/core/rules/types.dart';

/// Standard opening replies from the initial position, in the mover's
/// relative frame (from, to). Used by Hard and Master.
abstract final class OpeningBook {
  static const Map<String, List<(int, int)>> _book = {
    '21': [(13, 11), (6, 5)],
    '31': [(8, 5), (6, 5)],
    '41': [(24, 23), (13, 9)],
    '51': [(13, 8), (6, 5)],
    '61': [(13, 7), (8, 7)],
    '32': [(24, 21), (13, 11)],
    '42': [(8, 4), (6, 4)],
    '52': [(13, 8), (13, 11)],
    '62': [(24, 18), (13, 11)],
    '43': [(24, 20), (13, 10)],
    '53': [(8, 3), (6, 3)],
    '63': [(24, 18), (13, 10)],
    '54': [(24, 20), (13, 8)],
    '64': [(8, 2), (6, 2)],
    '65': [(24, 18), (18, 13)],
    '11': [(8, 7), (8, 7), (6, 5), (6, 5)],
    '22': [(13, 11), (13, 11), (6, 4), (6, 4)],
    '33': [(8, 5), (8, 5), (6, 3), (6, 3)],
    '44': [(24, 20), (24, 20), (13, 9), (13, 9)],
    '55': [(13, 8), (13, 8), (8, 3), (8, 3)],
    '66': [(24, 18), (24, 18), (13, 7), (13, 7)],
  };

  /// The book play for [s] if the mover is still in the starting position,
  /// with no effects in play, and the play is legal; otherwise null.
  static List<Move>? lookup(GameState s) {
    if (s.phase != Phase.moving || s.movesThisRoll.isNotEmpty) return null;
    if (s.effects.isNotEmpty) return null;
    final start = Board.initial();
    if (s.board.of(s.current).join() != start.of(s.current).join()) return null;
    if (s.dice.isEmpty) return null;
    final hi = s.dice.reduce((a, b) => a > b ? a : b);
    final lo = s.dice.reduce((a, b) => a < b ? a : b);
    final plan = _book['$hi$lo'];
    if (plan == null || (s.dice.length == 4) != (hi == lo)) return null;
    var st = s;
    final out = <Move>[];
    for (final (f, t) in plan) {
      final m = Engine.legalMoves(st)
          .where((m) => m.from == f && m.to == t)
          .firstOrNull;
      if (m == null) return null;
      out.add(m);
      st = Engine.apply(st, PlayMove(m)).state;
    }
    return out;
  }
}
