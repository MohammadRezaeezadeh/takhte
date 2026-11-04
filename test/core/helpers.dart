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

/// State in the 7–7 pick phase offering exactly [offer] to [side].
GameState sevenState(
  Board board,
  List<String> offer, {
  Side side = Side.white,
  GameConfig config = const GameConfig(),
}) {
  return GameState.initial(config.copyWith(startingBoard: board)).copyWith(
    phase: Phase.sevenPick,
    current: side,
    turnNumber: 1,
    offer: offer,
    picksLeft: 1,
    sevenUsed: true,
    rolled: [7, 7],
  );
}

/// Picks the single offered card and supplies [targets] if needed.
GameState pickOnly(GameState s, [List<int>? targets]) {
  var st = Engine.apply(s, const PickCard(0)).state;
  if (st.phase == Phase.cardTarget) {
    st = Engine.apply(st, ChooseTargets(targets!)).state;
  }
  return st;
}

/// Plays one simple, deterministic step for whoever must act.
GameState autoStep(GameState s) {
  final actions = Engine.legalActions(s);
  GameAction? pickType<T>() =>
      actions.whereType<T>().cast<GameAction?>().firstOrNull;
  final a =
      pickType<PlayMove>() ??
      pickType<EndTurn>() ??
      pickType<PickCard>() ??
      pickType<ChooseTargets>() ??
      pickType<ChooseDice>() ??
      pickType<TakeDouble>() ??
      pickType<RollDice>() ??
      actions.first;
  return Engine.apply(s, a).state;
}

/// Advances with [autoStep] until [until] holds (or the game ends).
GameState advance(
  GameState s,
  bool Function(GameState) until, {
  int max = 500,
}) {
  var st = s;
  for (var i = 0; i < max && !st.isOver; i++) {
    if (until(st)) return st;
    st = autoStep(st);
  }
  if (!until(st)) {
    throw StateError('condition never reached (phase ${st.phase})');
  }
  return st;
}

/// Ends the current side's turn by auto-playing moves.
GameState finishCurrentTurn(GameState s) {
  final side = s.current;
  final turn = s.turnNumber;
  return advance(s, (x) => x.turnNumber != turn || x.current != side);
}
