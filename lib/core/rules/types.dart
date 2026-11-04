/// Fundamental value types for the rules engine. Pure Dart.
library;

import 'package:meta/meta.dart';

/// The two players. White moves from its 24-point down to its 1-point.
enum Side {
  white,
  black;

  Side get opponent => this == Side.white ? Side.black : Side.white;
}

/// Board position constants, expressed in the mover's *relative* frame.
abstract final class Pos {
  /// Checkers borne off.
  static const int off = 0;

  /// Checkers on the bar.
  static const int bar = 25;

  /// Number of checkers per side.
  static const int checkers = 15;
}

/// Converts a mover-relative point (1..24) into absolute point numbering.
///
/// Absolute numbering is White's perspective: White's home board is 1..6,
/// Black's home board is 19..24.
int toAbsolute(Side side, int relative) =>
    side == Side.white ? relative : 25 - relative;

/// Converts an absolute point (1..24) into the side's relative frame.
int toRelative(Side side, int absolute) =>
    side == Side.white ? absolute : 25 - absolute;

/// A single checker movement, in the mover's relative frame.
///
/// [from] is 25 for the bar, 1..24 for points. [to] is 0 for bearing off.
/// [die] is the die value consumed. Flags describe side effects that are
/// deterministic consequences of the move (computed by the generator).
@immutable
class Move {
  const Move(
    this.from,
    this.to,
    this.die, {
    this.hit = false,
    this.ghost = false,
  });

  factory Move.fromJson(Map<String, Object?> json) => Move(
    json['f']! as int,
    json['t']! as int,
    json['d']! as int,
    hit: json['h'] as bool? ?? false,
    ghost: json['g'] as bool? ?? false,
  );

  final int from;
  final int to;
  final int die;
  final bool hit;
  final bool ghost;

  bool get isBearOff => to == Pos.off;
  bool get isEnter => from == Pos.bar;

  Map<String, Object?> toJson() => {
    'f': from,
    't': to,
    'd': die,
    if (hit) 'h': true,
    if (ghost) 'g': true,
  };

  @override
  bool operator ==(Object other) =>
      other is Move &&
      other.from == from &&
      other.to == to &&
      other.die == die &&
      other.ghost == ghost;

  @override
  int get hashCode => Object.hash(from, to, die, ghost);

  @override
  String toString() {
    final f = from == Pos.bar ? 'bar' : '$from';
    final t = to == Pos.off ? 'off' : '$to';
    return '$f/$t${hit ? '*' : ''}${ghost ? '~' : ''}($die)';
  }
}

/// How a finished game was won.
enum WinType {
  /// 1 point.
  normal(1),

  /// Gammon / Mars (مارس): loser bore off nothing. 2 points.
  gammon(2),

  /// Backgammon / Kup Mars: gammon plus a loser checker on the bar or in the
  /// winner's home board. 3 points.
  backgammon(3),

  /// Opponent declined a double; worth the cube value before doubling.
  dropped(1),

  /// Opponent resigned.
  resigned(1);

  WinType(this.multiplier);
  final int multiplier;
}
