import 'package:haftnard/core/rules/types.dart';

/// Player commands. Every state transition is caused by exactly one action,
/// so a game is fully described by `config + List<GameAction>`.
sealed class GameAction {
  const GameAction();

  factory GameAction.fromJson(Map<String, Object?> j) {
    final t = j['t']! as String;
    return switch (t) {
      'open' => const RollOpening(),
      'roll' => const RollDice(),
      'dbl' => const OfferDouble(),
      'take' => const TakeDouble(),
      'drop' => const DropDouble(),
      'pick' => PickCard(j['i']! as int),
      'tgt' => ChooseTargets((j['p']! as List<Object?>).cast<int>()),
      'cd' => ChooseDice(j['a']! as int, j['b']! as int),
      'mv' => PlayMove(
        Move.fromJson(
          (j['m']! as Map<Object?, Object?>).cast<String, Object?>(),
        ),
      ),
      'rr' => const UseReroll(),
      'lk' => UseLucky(j['i']! as int),
      'fate' => SetFate(j['i']! as int, j['v']! as int),
      'end' => const EndTurn(),
      'resign' => Resign(Side.values.byName(j['s']! as String)),
      _ => throw FormatException('Unknown action $t'),
    };
  }

  Map<String, Object?> toJson();
}

/// Both sides roll one die to decide who starts.
class RollOpening extends GameAction {
  const RollOpening();
  @override
  Map<String, Object?> toJson() => {'t': 'open'};
}

/// Roll the dice for the current turn.
class RollDice extends GameAction {
  const RollDice();
  @override
  Map<String, Object?> toJson() => {'t': 'roll'};
}

class OfferDouble extends GameAction {
  const OfferDouble();
  @override
  Map<String, Object?> toJson() => {'t': 'dbl'};
}

class TakeDouble extends GameAction {
  const TakeDouble();
  @override
  Map<String, Object?> toJson() => {'t': 'take'};
}

class DropDouble extends GameAction {
  const DropDouble();
  @override
  Map<String, Object?> toJson() => {'t': 'drop'};
}

/// Pick card [index] from the current 7–7 offer.
class PickCard extends GameAction {
  const PickCard(this.index);
  final int index;
  @override
  Map<String, Object?> toJson() => {'t': 'pick', 'i': index};
}

/// Targets for the pending card, as absolute points (0 = own bar).
class ChooseTargets extends GameAction {
  const ChooseTargets(this.points);
  final List<int> points;
  @override
  Map<String, Object?> toJson() => {'t': 'tgt', 'p': points};
}

/// Loaded Hand: keep dice [a] and [b] (indices into the three rolled).
class ChooseDice extends GameAction {
  const ChooseDice(this.a, this.b);
  final int a;
  final int b;
  @override
  Map<String, Object?> toJson() => {'t': 'cd', 'a': a, 'b': b};
}

class PlayMove extends GameAction {
  const PlayMove(this.move);
  final Move move;
  @override
  Map<String, Object?> toJson() => {'t': 'mv', 'm': move.toJson()};
}

/// Spend a Second Chance token to reroll before moving.
class UseReroll extends GameAction {
  const UseReroll();
  @override
  Map<String, Object?> toJson() => {'t': 'rr'};
}

/// Spend a Lucky Charm: +1 to the remaining die at [index].
class UseLucky extends GameAction {
  const UseLucky(this.index);
  final int index;
  @override
  Map<String, Object?> toJson() => {'t': 'lk', 'i': index};
}

/// Fate's Edit: set the die at [index] to [value].
class SetFate extends GameAction {
  const SetFate(this.index, this.value);
  final int index;
  final int value;
  @override
  Map<String, Object?> toJson() => {'t': 'fate', 'i': index, 'v': value};
}

/// Finish the current roll / turn.
class EndTurn extends GameAction {
  const EndTurn();
  @override
  Map<String, Object?> toJson() => {'t': 'end'};
}

/// [side] resigns the game (allowed at any time before game over).
class Resign extends GameAction {
  const Resign(this.side);
  final Side side;
  @override
  Map<String, Object?> toJson() => {'t': 'resign', 's': side.name};
}
