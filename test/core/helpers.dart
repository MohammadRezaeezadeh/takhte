import 'package:haftnard/core/rules/actions.dart';
import 'package:haftnard/core/rules/board.dart';
import 'package:haftnard/core/rules/engine.dart';
import 'package:haftnard/core/rules/move_gen.dart';
import 'package:haftnard/core/rules/state.dart';
import 'package:haftnard/core/rules/types.dart';

/// Builds a game state already in the moving phase with given dice.
GameState movingState(
  Board board,
  List<int> dice, {
  Side side = Side.white,
  GameMode mode = GameMode.classic,
}) {
  final cfg = GameConfig(mode: mode, startingBoard: board);
  final s0 = GameState.initial(cfg);
  final raw = dice.length == 4 ? [dice[0], dice[0]] : dice;
  return s0.copyWith(
    phase: Phase.moving,
    current: side,
    turnNumber: 1,
    dice: dice,
    rolled: raw,
    rollsThisTurn: 1,
    sevenUsed: true,
  );
}

/// A state in pre-roll for [side].
GameState preRollState(
  Board board, {
  Side side = Side.white,
  GameConfig? config,
}) {
  final cfg = (config ?? const GameConfig()).copyWith(startingBoard: board);
  return GameState.initial(cfg)
      .copyWith(phase: Phase.preRoll, current: side, turnNumber: 1);
}

Set<String> moveStrings(Iterable<Move> moves) => {
  for (final m in moves) '${m.from}/${m.to}(${m.die})',
};

List<Move> legal(Board b, List<int> dice, [Side side = Side.white]) =>
    MoveGen.legalMoves(TurnSim.fromBoard(b, side), dice);

/// Plays [moves] (as "from/to" strings, relative) for the current side.
GameState play(GameState s, List<(int, int)> moves) {
  var st = s;
  for (final (f, t) in moves) {
    final m = Engine.legalMoves(st).firstWhere(
      (m) => m.from == f && m.to == t,
      orElse: () =>
          throw StateError('$f/$t not legal: ${Engine.legalMoves(st)}'),
    );
    st = Engine.apply(st, PlayMove(m)).state;
  }
  return st;
}
