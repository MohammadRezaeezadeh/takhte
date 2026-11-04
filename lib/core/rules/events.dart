import 'package:haftnard/core/rules/types.dart';

/// Things that happened while applying an action. The presentation layer uses
/// these to drive animation, sound and haptics; they carry no authority.
sealed class GameEvent {
  const GameEvent();
}

class OpeningRolled extends GameEvent {
  const OpeningRolled(this.white, this.black);
  final int white;
  final int black;
  bool get tie => white == black;
}

class DiceRolled extends GameEvent {
  const DiceRolled(this.side, this.dice, {this.bonus = false});
  final Side side;
  final List<int> dice;
  final bool bonus;
}

class SevenRolled extends GameEvent {
  const SevenRolled(this.side, this.offer);
  final Side side;
  final List<String> offer;
}

class CardPicked extends GameEvent {
  const CardPicked(this.side, this.cardId);
  final Side side;
  final String cardId;
}

class CardFizzled extends GameEvent {
  const CardFizzled(this.side, this.cardId);
  final Side side;
  final String cardId;
}

class MovePlayed extends GameEvent {
  const MovePlayed(this.side, this.move);
  final Side side;
  final Move move;
}

/// A checker was hit. [point] is absolute.
class CheckerHit extends GameEvent {
  const CheckerHit(this.victim, this.point);
  final Side victim;
  final int point;
}

class CheckerBorneOff extends GameEvent {
  const CheckerBorneOff(this.side, this.fromAbsolute);
  final Side side;
  final int fromAbsolute;
}

class MineTriggered extends GameEvent {
  const MineTriggered(this.victim, this.point);
  final Side victim;
  final int point;
}

class PhoenixRose extends GameEvent {
  const PhoenixRose(this.side, this.point);
  final Side side;
  final int point;
}

class Teleported extends GameEvent {
  const Teleported(this.side, this.fromAbsolute, this.toAbsolute);
  final Side side;
  final int fromAbsolute;
  final int toAbsolute;
}

class TurnSkipped extends GameEvent {
  const TurnSkipped(this.side);
  final Side side;
}

class CoinFlipped extends GameEvent {
  const CoinFlipped(this.owner, {required this.ownerWins});
  final Side owner;
  final bool ownerWins;
}

class ItemStolen extends GameEvent {
  const ItemStolen(this.thief, this.item);
  final Side thief;
  final String item;
}

class NoLegalMoves extends GameEvent {
  const NoLegalMoves(this.side);
  final Side side;
}

class TurnStarted extends GameEvent {
  const TurnStarted(this.side, {this.extra = false});
  final Side side;
  final bool extra;
}

class CubeOffered extends GameEvent {
  const CubeOffered(this.by, this.value);
  final Side by;
  final int value;
}

class CubeTaken extends GameEvent {
  const CubeTaken(this.by, this.value);
  final Side by;
  final int value;
}

class GameEnded extends GameEvent {
  const GameEnded(this.winner, this.type, this.points);
  final Side winner;
  final WinType type;
  final int points;
}

class QuicksandGripped extends GameEvent {
  const QuicksandGripped(this.side, this.point);
  final Side side;
  final int point;
}

class TokenGranted extends GameEvent {
  const TokenGranted(this.side, this.item);
  final Side side;
  final String item;
}
