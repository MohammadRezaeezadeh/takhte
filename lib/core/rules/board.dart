import 'package:haftnard/core/rules/types.dart';
import 'package:meta/meta.dart';

/// Immutable checker layout.
///
/// Each side has a 26-slot list in its own relative frame:
/// index 0 = borne off, 1..24 = points, 25 = bar.
/// A side's relative point `p` is the opponent's relative point `25 - p`.
@immutable
class Board {
  const Board._(this._w, this._b);

  /// Builds a board from explicit per-side relative arrays (copied).
  factory Board.fromLists(List<int> white, List<int> black) {
    assert(white.length == 26 && black.length == 26, 'need 26 slots');
    return Board._(List<int>.of(white), List<int>.of(black));
  }

  /// The standard backgammon starting position.
  factory Board.initial() {
    List<int> start() {
      final l = List<int>.filled(26, 0);
      l[24] = 2;
      l[13] = 5;
      l[8] = 3;
      l[6] = 5;
      return l;
    }

    return Board._(start(), start());
  }

  /// Convenience for tests: `{relativePoint: count}` per side.
  factory Board.fromMaps({
    Map<int, int> white = const {},
    Map<int, int> black = const {},
    bool fillOff = true,
  }) {
    List<int> make(Map<int, int> m) {
      final l = List<int>.filled(26, 0);
      m.forEach((k, v) => l[k] = v);
      if (fillOff) {
        final onBoard = l.sublist(1).fold<int>(0, (a, b) => a + b);
        l[0] = Pos.checkers - onBoard;
      }
      return l;
    }

    return Board._(make(white), make(black));
  }

  factory Board.fromJson(Map<String, Object?> json) => Board._(
    (json['w']! as List<Object?>).cast<int>().toList(),
    (json['b']! as List<Object?>).cast<int>().toList(),
  );

  final List<int> _w;
  final List<int> _b;

  /// Relative slot array for [side] (do not mutate).
  List<int> of(Side side) => side == Side.white ? _w : _b;

  /// Count of [side]'s checkers on its relative slot [rel].
  int count(Side side, int rel) => of(side)[rel];

  int borneOff(Side side) => of(side)[Pos.off];
  int onBar(Side side) => of(side)[Pos.bar];

  /// Pip count for [side].
  int pips(Side side) {
    final l = of(side);
    var p = 0;
    for (var i = 1; i <= 25; i++) {
      p += l[i] * i;
    }
    return p;
  }

  /// True if all of [side]'s remaining checkers are in its home board.
  bool allHome(Side side) {
    final l = of(side);
    for (var i = 7; i <= 25; i++) {
      if (l[i] > 0) return false;
    }
    return true;
  }

  /// Owner and count at absolute point [abs] (1..24). Owner null if empty.
  (Side?, int) atAbsolute(int abs) {
    final w = _w[toRelative(Side.white, abs)];
    if (w > 0) return (Side.white, w);
    final b = _b[toRelative(Side.black, abs)];
    if (b > 0) return (Side.black, b);
    return (null, 0);
  }

  /// Returns a new board with [side]'s array replaced by [list].
  Board withSide(Side side, List<int> list) =>
      side == Side.white ? Board._(list, _b) : Board._(_w, list);

  Board withBoth(List<int> white, List<int> black) => Board._(white, black);

  /// Verifies invariants: 15 checkers each, no shared points, no negatives.
  String? validate() {
    for (final side in Side.values) {
      final l = of(side);
      if (l.length != 26) return '$side array length ${l.length}';
      if (l.any((v) => v < 0)) return '$side has a negative count';
      final total = l.fold<int>(0, (a, b) => a + b);
      if (total != Pos.checkers) return '$side has $total checkers';
    }
    for (var p = 1; p <= 24; p++) {
      if (_w[p] > 0 && _b[25 - p] > 0) return 'point $p shared';
    }
    return null;
  }

  /// Compact key usable for hashing/deduplication.
  String get key => '${_w.join(',')}|${_b.join(',')}';

  Map<String, Object?> toJson() => {'w': _w, 'b': _b};

  @override
  bool operator ==(Object other) {
    if (other is! Board) return false;
    for (var i = 0; i < 26; i++) {
      if (other._w[i] != _w[i] || other._b[i] != _b[i]) return false;
    }
    return true;
  }

  @override
  int get hashCode => Object.hashAll([..._w, ..._b]);

  @override
  String toString() => 'Board($key)';
}
