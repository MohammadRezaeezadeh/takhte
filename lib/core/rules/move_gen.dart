import 'package:haftnard/core/rules/board.dart';
import 'package:haftnard/core/rules/types.dart';

/// Rule modifiers in effect for the mover during one roll, produced by the
/// effect system. All point masks use bits 1..24 in the *mover's* relative
/// frame.
class MoveContext {
  const MoveContext({
    this.frozen = const {},
    this.protectedMask = 0,
    this.tollMask = 0,
    this.mineMask = 0,
    this.ghostCharges = 0,
    this.opponentPhoenix = false,
  });

  /// Mover's relative point -> number of checkers that cannot move.
  final Map<int, int> frozen;

  /// Points where an opponent's lone checker cannot be hit (acts as blocked).
  final int protectedMask;

  /// Toll points: crossing one strictly costs one extra pip.
  final int tollMask;

  /// Opponent's hidden landmines: landing there sends the mover to the bar.
  final int mineMask;

  /// Ghost Step charges: a blocked destination may be passed to the next
  /// open point beyond it.
  final int ghostCharges;

  /// Opponent holds Phoenix: their next hit checker re-enters immediately.
  final bool opponentPhoenix;

  static const MoveContext none = MoveContext();

  bool get isPlain =>
      frozen.isEmpty &&
      protectedMask == 0 &&
      tollMask == 0 &&
      mineMask == 0 &&
      ghostCharges == 0 &&
      !opponentPhoenix;
}

/// Mutable working copy of a position used for move generation and search.
class TurnSim {
  TurnSim({
    required this.mine,
    required this.theirs,
    required this.ctx,
    int? ghost,
    int? mines,
    bool? phoenix,
  }) : ghost = ghost ?? ctx.ghostCharges,
       mines = mines ?? ctx.mineMask,
       phoenix = phoenix ?? ctx.opponentPhoenix;

  factory TurnSim.fromBoard(
    Board board,
    Side mover, [
    MoveContext ctx = MoveContext.none,
  ]) => TurnSim(
    mine: List<int>.of(board.of(mover)),
    theirs: List<int>.of(board.of(mover.opponent)),
    ctx: ctx,
  );

  final List<int> mine;
  final List<int> theirs;
  final MoveContext ctx;
  int ghost;
  int mines;
  bool phoenix;

  /// Board for [mover] with this sim's arrays.
  Board toBoard(Side mover) => mover == Side.white
      ? Board.fromLists(mine, theirs)
      : Board.fromLists(theirs, mine);

  TurnSim copy() => TurnSim(
    mine: List<int>.of(mine),
    theirs: List<int>.of(theirs),
    ctx: ctx,
    ghost: ghost,
    mines: mines,
    phoenix: phoenix,
  );

  String get key =>
      '${mine.join(',')}|${theirs.join(',')}|$ghost|$mines|$phoenix';

  bool _allHome() {
    for (var i = 7; i <= 25; i++) {
      if (mine[i] > 0) return false;
    }
    return true;
  }

  bool _blocked(int dest) {
    final opp = theirs[25 - dest];
    if (opp >= 2) return true;
    return opp >= 1 && (ctx.protectedMask & (1 << dest)) != 0;
  }

  int _movable(int p) {
    final n = mine[p];
    if (n == 0) return 0;
    final f = ctx.frozen[p];
    return f == null ? n : (n - f).clamp(0, n);
  }

  /// All single-checker moves using die [d] from this position.
  List<Move> stepMoves(int d) {
    final out = <Move>[];
    if (mine[Pos.bar] > 0) {
      _tryFrom(Pos.bar, d, out);
      return out;
    }
    final home = _allHome();
    for (var p = 24; p >= 1; p--) {
      if (_movable(p) > 0) _tryFrom(p, d, out, allHome: home);
    }
    return out;
  }

  void _tryFrom(int from, int d, List<Move> out, {bool allHome = false}) {
    final natural = from - d;
    var dest = natural;
    if (ctx.tollMask != 0) {
      for (var t = natural + 1; t < from; t++) {
        if (t >= 1 && t <= 24 && (ctx.tollMask & (1 << t)) != 0) dest++;
      }
    }
    if (dest >= from) return;
    if (dest >= 1) {
      if (_blocked(dest)) {
        if (ghost > 0) {
          for (var g = dest - 1; g >= 1; g--) {
            if (!_blocked(g)) {
              out.add(Move(from, g, d, hit: theirs[25 - g] == 1, ghost: true));
              return;
            }
          }
        }
        return;
      }
      out.add(Move(from, dest, d, hit: theirs[25 - dest] == 1));
      return;
    }
    // Bearing off.
    if (from == Pos.bar || !allHome) return;
    if (dest == 0) {
      out.add(Move(from, Pos.off, d));
      return;
    }
    for (var h = from + 1; h <= 6; h++) {
      if (mine[h] > 0) return;
    }
    out.add(Move(from, Pos.off, d));
  }

  /// Applies [m] in place. Returns flags describing triggered side effects.
  MoveOutcome apply(Move m) {
    mine[m.from]--;
    var phoenixUsed = false;
    var mined = false;
    var phoenixPoint = 0;
    if (m.to == Pos.off) {
      mine[Pos.off]++;
    } else {
      mine[m.to]++;
      if (theirs[25 - m.to] == 1) {
        theirs[25 - m.to] = 0;
        var placed = false;
        if (phoenix) {
          // Opponent re-enters at the most advanced open point of the
          // mover's home board (opponent relative 19..24).
          for (var oppRel = 19; oppRel <= 24; oppRel++) {
            if (mine[25 - oppRel] == 0) {
              theirs[oppRel]++;
              placed = true;
              phoenixPoint = oppRel;
              break;
            }
          }
          phoenix = false;
          phoenixUsed = true;
        }
        if (!placed) theirs[Pos.bar]++;
      }
      if ((mines & (1 << m.to)) != 0) {
        mines &= ~(1 << m.to);
        mine[m.to]--;
        mine[Pos.bar]++;
        mined = true;
      }
    }
    if (m.ghost) ghost--;
    return MoveOutcome(
      mined: mined,
      phoenixUsed: phoenixUsed,
      phoenixPoint: phoenixPoint,
    );
  }
}

/// Side effects of applying a move.
class MoveOutcome {
  const MoveOutcome({
    this.mined = false,
    this.phoenixUsed = false,
    this.phoenixPoint = 0,
  });

  /// Mover's checker hit a landmine and went to the bar.
  final bool mined;

  /// Opponent's Phoenix consumed.
  final bool phoenixUsed;

  /// Opponent-relative point the Phoenix checker re-entered on (0 if none).
  final int phoenixPoint;
}

/// A complete play for one roll.
class TurnPlay {
  const TurnPlay(this.moves, this.result);
  final List<Move> moves;
  final TurnSim result;
}

/// Legal move generation enforcing the full-turn rules:
/// use as many dice as possible; if only one die can be used, the larger one
/// must be used when possible.
abstract final class MoveGen {
  /// Maximum number of dice from [dice] that can be played from [sim].
  static int maxPlayable(TurnSim sim, List<int> dice) {
    final memo = <String, int>{};
    return _best(sim, dice, memo);
  }

  static int _best(TurnSim sim, List<int> dice, Map<String, int> memo) {
    if (dice.isEmpty) return 0;
    final k = '${sim.key}#${_diceKey(dice)}';
    final cached = memo[k];
    if (cached != null) return cached;
    var best = 0;
    for (final v in _distinct(dice)) {
      final rest = _without(dice, v);
      for (final m in sim.stepMoves(v)) {
        final next = sim.copy()..apply(m);
        final depth = 1 + _best(next, rest, memo);
        if (depth > best) best = depth;
        if (best == dice.length) break;
      }
      if (best == dice.length) break;
    }
    memo[k] = best;
    return best;
  }

  /// Legal next single moves for the remaining [dice].
  static List<Move> legalMoves(TurnSim sim, List<int> dice) {
    if (dice.isEmpty) return const [];
    final memo = <String, int>{};
    final scored = <(Move, int)>[];
    var max = 0;
    for (final v in _distinct(dice)) {
      final rest = _without(dice, v);
      for (final m in sim.stepMoves(v)) {
        final next = sim.copy()..apply(m);
        final depth = 1 + _best(next, rest, memo);
        scored.add((m, depth));
        if (depth > max) max = depth;
      }
    }
    if (max == 0) return const [];
    var moves = [
      for (final (m, d) in scored)
        if (d == max) m,
    ];
    if (max == 1 && dice.length == 2 && dice[0] != dice[1]) {
      final hi = dice[0] > dice[1] ? dice[0] : dice[1];
      final big = moves.where((m) => m.die == hi).toList();
      if (big.isNotEmpty) moves = big;
    }
    return moves;
  }

  /// Every distinct legal complete play (deduplicated by resulting position).
  static List<TurnPlay> allPlays(TurnSim sim, List<int> dice) {
    final results = <String, TurnPlay>{};
    var maxLen = 0;
    final visited = <String>{};

    void dfs(TurnSim s, List<int> remaining, List<Move> path) {
      var moved = false;
      if (remaining.isNotEmpty) {
        for (final v in _distinct(remaining)) {
          final rest = _without(remaining, v);
          for (final m in s.stepMoves(v)) {
            final next = s.copy()..apply(m);
            final vk = '${next.key}#${_diceKey(rest)}';
            moved = true;
            if (!visited.add(vk)) continue;
            dfs(next, rest, [...path, m]);
          }
        }
      }
      if (!moved) {
        final len = path.length;
        if (len < maxLen) return;
        if (len > maxLen) {
          maxLen = len;
          results.clear();
        }
        results.putIfAbsent(s.key, () => TurnPlay(path, s));
      }
    }

    dfs(sim, dice, const []);
    var plays = results.values.toList();
    // A path that stops early because of a dedup hit is still recorded via
    // the other branch that reached the same node, so lengths stay correct.
    if (maxLen == 1 && dice.length == 2 && dice[0] != dice[1]) {
      final hi = dice[0] > dice[1] ? dice[0] : dice[1];
      final big = plays.where((p) => p.moves.first.die == hi).toList();
      if (big.isNotEmpty) plays = big;
    }
    if (plays.isEmpty) return [TurnPlay(const [], sim.copy())];
    return plays;
  }

  static Iterable<int> _distinct(List<int> dice) => dice.toSet();

  static List<int> _without(List<int> dice, int v) {
    final l = List<int>.of(dice);
    l.remove(v);
    return l;
  }

  static String _diceKey(List<int> dice) {
    final l = List<int>.of(dice)..sort();
    return l.join();
  }
}
