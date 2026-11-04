import 'package:haftnard/core/effects/card_logic.dart';
import 'package:haftnard/core/effects/cards.dart';
import 'package:haftnard/core/effects/effect_system.dart';
import 'package:haftnard/core/rng/rng.dart';
import 'package:haftnard/core/rules/actions.dart';
import 'package:haftnard/core/rules/board.dart';
import 'package:haftnard/core/rules/events.dart';
import 'package:haftnard/core/rules/move_gen.dart';
import 'package:haftnard/core/rules/seven_odds.dart';
import 'package:haftnard/core/rules/state.dart';
import 'package:haftnard/core/rules/types.dart';

/// Thrown when an action is not legal in the current state.
class IllegalActionException implements Exception {
  IllegalActionException(this.message);
  final String message;
  @override
  String toString() => 'IllegalActionException: $message';
}

/// Result of applying one action.
class StepResult {
  const StepResult(this.state, this.events);
  final GameState state;
  final List<GameEvent> events;
}

/// Mutable transaction over a [GameState] used while applying one action.
/// Effect handlers and card logic operate on it.
class Tx {
  Tx(GameState s)
    : config = s.config,
      board = s.board,
      rng = Rng.fromState(s.rng),
      phase = s.phase,
      current = s.current,
      turnNumber = s.turnNumber,
      dice = List<int>.of(s.dice),
      rolled = List<int>.of(s.rolled),
      choiceDice = List<int>.of(s.choiceDice),
      movesThisRoll = List<Move>.of(s.movesThisRoll),
      rollsThisTurn = s.rollsThisTurn,
      rollQueue = [for (final q in s.rollQueue) List<int>.of(q)],
      extraTurn = s.extraTurn,
      sevenUsed = s.sevenUsed,
      effects = List<ActiveEffect>.of(s.effects),
      nextEffectId = s.nextEffectId,
      white = s.white,
      black = s.black,
      offer = List<String>.of(s.offer),
      picksLeft = s.picksLeft,
      pendingCard = s.pendingCard,
      cubeValue = s.cubeValue,
      cubeOwner = s.cubeOwner,
      result = s.result,
      openingDice = List<int>.of(s.openingDice);

  final GameConfig config;
  Board board;
  final Rng rng;
  Phase phase;
  Side current;
  int turnNumber;
  List<int> dice;
  List<int> rolled;
  List<int> choiceDice;
  List<Move> movesThisRoll;
  int rollsThisTurn;
  List<List<int>> rollQueue;
  bool extraTurn;
  bool sevenUsed;
  List<ActiveEffect> effects;
  int nextEffectId;
  SideInv white;
  SideInv black;
  List<String> offer;
  int picksLeft;
  String? pendingCard;
  int cubeValue;
  Side? cubeOwner;
  GameResult? result;
  List<int> openingDice;

  /// Set by effect handlers during turn start to skip the turn.
  bool skipping = false;
  final List<GameEvent> events = [];

  SideInv inv(Side s) => s == Side.white ? white : black;

  void setInv(Side s, SideInv v) {
    if (s == Side.white) {
      white = v;
    } else {
      black = v;
    }
  }

  ActiveEffect addEffect(
    EffectKind kind, {
    required Side owner,
    required Side affected,
    required int turns,
    bool immediate = true,
    int point = 0,
    int count = 0,
    List<int> values = const [],
  }) {
    final e = ActiveEffect(
      id: nextEffectId++,
      kind: kind,
      owner: owner,
      affected: affected,
      turnsLeft: turns,
      createdTurn: turnNumber,
      immediate: immediate,
      point: point,
      count: count,
      values: values,
    );
    effects.add(e);
    return e;
  }

  void removeEffect(int id) => effects.removeWhere((e) => e.id == id);

  void replaceEffect(ActiveEffect e) {
    final i = effects.indexWhere((x) => x.id == e.id);
    if (i >= 0) effects[i] = e;
  }

  /// Active effects whose turns are counted on [side].
  List<ActiveEffect> activeAffecting(Side side) => [
    for (final e in effects)
      if (e.affected == side && e.isActive(turnNumber)) e,
  ]..sort(EffectSystem.compare);

  GameState freeze() => GameState(
    config: config,
    board: board,
    rng: rng.state,
    phase: phase,
    current: current,
    turnNumber: turnNumber,
    dice: List.unmodifiable(dice),
    rolled: List.unmodifiable(rolled),
    choiceDice: List.unmodifiable(choiceDice),
    movesThisRoll: List.unmodifiable(movesThisRoll),
    rollsThisTurn: rollsThisTurn,
    rollQueue: List.unmodifiable(rollQueue.map(List<int>.unmodifiable)),
    extraTurn: extraTurn,
    sevenUsed: sevenUsed,
    effects: List.unmodifiable(effects),
    nextEffectId: nextEffectId,
    white: white,
    black: black,
    offer: List.unmodifiable(offer),
    picksLeft: picksLeft,
    pendingCard: pendingCard,
    cubeValue: cubeValue,
    cubeOwner: cubeOwner,
    result: result,
    openingDice: List.unmodifiable(openingDice),
  );
}

/// Dice rolling plan assembled by `onBeforeRoll` hooks.
class RollPlan {
  RollPlan({
    required this.count,
    required this.doublesCount,
    required this.cap,
    required this.p7Multiplier,
  });
  int count;

  /// Added to every die (clamped to 1..6) before the cap.
  int bonus = 0;

  /// Forces the first die to this value.
  int? forceFirst;

  /// Odd results are raised to the next even number.
  bool evenUp = false;

  /// A rolled 1 or 2 is rerolled once.
  bool rerollOnes = false;

  /// The second die copies the first (guaranteed doubles).
  bool forceDouble = false;

  /// Minimum die value.
  int minValue = 1;

  /// Dice are halved, rounded up (6 → 3).
  bool halve = false;

  bool doublesCount;
  int cap;
  double p7Multiplier;
}

/// The pure rules engine.
abstract final class Engine {
  /// Applies [action] to [state]. Throws [IllegalActionException] if illegal.
  static StepResult apply(GameState state, GameAction action) {
    final tx = Tx(state);
    _dispatch(tx, action);
    return StepResult(tx.freeze(), tx.events);
  }

  /// Applies a sequence of actions (e.g. replaying a log).
  static GameState applyAll(GameState state, Iterable<GameAction> actions) {
    var s = state;
    for (final a in actions) {
      s = apply(s, a).state;
    }
    return s;
  }

  /// Legal single moves for the current roll.
  static List<Move> legalMoves(GameState s) {
    if (s.phase != Phase.moving || s.dice.isEmpty) return const [];
    final sim = TurnSim.fromBoard(
      s.board,
      s.current,
      moveContext(s, s.current),
    );
    return MoveGen.legalMoves(sim, s.dice);
  }

  /// Move-rule modifiers for [mover] produced by active effects.
  static MoveContext moveContext(
    GameState s,
    Side mover, {
    bool hideMines = false,
  }) => EffectSystem.moveContext(Tx(s), mover, hideMines: hideMines);

  static bool canEndTurn(GameState s) =>
      s.phase == Phase.moving && (s.dice.isEmpty || legalMoves(s).isEmpty);

  /// Whether the current roll may still be altered (reroll/lucky/fate).
  static bool canAlterRoll(GameState s) =>
      s.phase == Phase.moving && s.movesThisRoll.isEmpty && s.dice.isNotEmpty;

  static bool canSetFate(GameState s) =>
      canAlterRoll(s) &&
      s.effects.any(
        (e) =>
            e.kind == EffectKind.fateEdit &&
            e.affected == s.current &&
            e.isActive(s.turnNumber),
      );

  static bool canOfferDouble(GameState s) =>
      s.phase == Phase.preRoll &&
      s.config.cubeEnabled &&
      !s.config.crawford &&
      s.rollsThisTurn == 0 &&
      s.cubeValue < 64 &&
      (s.cubeOwner == null || s.cubeOwner == s.current);

  /// Side expected to act next (the cube taker during a cube offer).
  static Side actor(GameState s) =>
      s.phase == Phase.cubeOffered ? s.current.opponent : s.current;

  /// Every legal action (used by AI, fuzzing and tests).
  static List<GameAction> legalActions(GameState s) {
    switch (s.phase) {
      case Phase.opening:
        return const [RollOpening()];
      case Phase.preRoll:
        return [const RollDice(), if (canOfferDouble(s)) const OfferDouble()];
      case Phase.cubeOffered:
        return const [TakeDouble(), DropDouble()];
      case Phase.sevenPick:
        return [for (var i = 0; i < s.offer.length; i++) PickCard(i)];
      case Phase.cardTarget:
        final tx = Tx(s);
        return [
          for (final t in CardLogic.allTargets(tx, s.current, s.pendingCard!))
            ChooseTargets(t),
        ];
      case Phase.chooseDice:
        return const [ChooseDice(0, 1), ChooseDice(0, 2), ChooseDice(1, 2)];
      case Phase.moving:
        final out = <GameAction>[
          for (final m in legalMoves(s)) PlayMove(m),
          if (canEndTurn(s)) const EndTurn(),
        ];
        if (canAlterRoll(s)) {
          final inv = s.inv(s.current);
          if (inv.rerolls > 0) out.add(const UseReroll());
          if (inv.lucky > 0) {
            for (var i = 0; i < s.dice.length; i++) {
              if (s.dice[i] < 6 && s.dice.indexOf(s.dice[i]) == i) {
                out.add(UseLucky(i));
              }
            }
          }
          if (canSetFate(s)) {
            for (var i = 0; i < s.rolled.length; i++) {
              for (var v = 1; v <= 6; v++) {
                if (v != s.rolled[i]) out.add(SetFate(i, v));
              }
            }
          }
        }
        return out;
      case Phase.gameOver:
        return const [];
    }
  }

  // ---------------------------------------------------------------------------

  static void _dispatch(Tx tx, GameAction a) {
    if (tx.phase == Phase.gameOver) {
      throw IllegalActionException('Game is over');
    }
    switch (a) {
      case RollOpening():
        _need(tx, Phase.opening, a);
        _openingRoll(tx);
      case RollDice():
        _need(tx, Phase.preRoll, a);
        _roll(tx);
      case OfferDouble():
        if (!canOfferDouble(tx.freeze())) {
          throw IllegalActionException('Cannot double now');
        }
        tx.phase = Phase.cubeOffered;
        tx.events.add(CubeOffered(tx.current, tx.cubeValue * 2));
      case TakeDouble():
        _need(tx, Phase.cubeOffered, a);
        tx.cubeValue *= 2;
        tx.cubeOwner = tx.current.opponent;
        tx.phase = Phase.preRoll;
        tx.events.add(CubeTaken(tx.current.opponent, tx.cubeValue));
      case DropDouble():
        _need(tx, Phase.cubeOffered, a);
        endGame(tx, tx.current, WinType.dropped);
      case PickCard(:final index):
        _need(tx, Phase.sevenPick, a);
        if (index < 0 || index >= tx.offer.length) {
          throw IllegalActionException('Bad card index $index');
        }
        _pick(tx, index);
      case ChooseTargets(:final points):
        _need(tx, Phase.cardTarget, a);
        final card = tx.pendingCard!;
        if (!CardLogic.validTargets(tx, tx.current, card, points)) {
          throw IllegalActionException('Invalid targets $points for $card');
        }
        tx.pendingCard = null;
        CardLogic.apply(tx, tx.current, card, points);
        _afterPick(tx);
      case ChooseDice(a: final i, b: final j):
        _need(tx, Phase.chooseDice, a);
        if (i == j || i < 0 || j < 0 || i > 2 || j > 2) {
          throw IllegalActionException('Bad dice choice');
        }
        final chosen = [tx.choiceDice[i], tx.choiceDice[j]];
        tx.choiceDice = [];
        final plan = _plan(tx);
        _setDice(tx, chosen, doublesCount: plan.doublesCount);
      case PlayMove(:final move):
        _need(tx, Phase.moving, a);
        final legal = legalMoves(tx.freeze());
        final match = legal.where((m) => m == move).firstOrNull;
        if (match == null) {
          throw IllegalActionException('Illegal move $move; legal: $legal');
        }
        _playMove(tx, match);
      case UseReroll():
        _need(tx, Phase.moving, a);
        if (!canAlterRoll(tx.freeze()) || tx.inv(tx.current).rerolls <= 0) {
          throw IllegalActionException('Cannot reroll');
        }
        final inv = tx.inv(tx.current);
        tx.setInv(tx.current, inv.copyWith(rerolls: inv.rerolls - 1));
        final plan = _plan(tx);
        if (plan.count > 2) plan.count = 2;
        _rollNormal(tx, plan);
      case UseLucky(:final index):
        _need(tx, Phase.moving, a);
        final inv = tx.inv(tx.current);
        if (!canAlterRoll(tx.freeze()) ||
            inv.lucky <= 0 ||
            index < 0 ||
            index >= tx.dice.length ||
            tx.dice[index] >= 6) {
          throw IllegalActionException('Cannot use Lucky Charm');
        }
        tx.setInv(tx.current, inv.copyWith(lucky: inv.lucky - 1));
        tx.dice[index]++;
        if (tx.dice.length <= 2) tx.rolled = List.of(tx.dice);
        _checkNoMoves(tx);
      case SetFate(:final index, :final value):
        _need(tx, Phase.moving, a);
        if (!canSetFate(tx.freeze()) ||
            index < 0 ||
            index >= tx.rolled.length ||
            value < 1 ||
            value > 6) {
          throw IllegalActionException('Cannot use Fate');
        }
        final fate = tx.effects.firstWhere(
          (e) => e.kind == EffectKind.fateEdit && e.affected == tx.current,
        );
        tx.removeEffect(fate.id);
        final raw = List<int>.of(tx.rolled);
        raw[index] = value;
        final plan = _plan(tx);
        tx.rolled = raw;
        tx.dice = _finalize(tx, raw, doublesCount: plan.doublesCount);
        _checkNoMoves(tx);
      case EndTurn():
        _need(tx, Phase.moving, a);
        if (!canEndTurn(tx.freeze())) {
          throw IllegalActionException('Moves remain');
        }
        _endRoll(tx);
      case Resign(:final side):
        endGame(tx, side.opponent, WinType.resigned);
    }
  }

  static void _need(Tx tx, Phase p, GameAction a) {
    if (tx.phase != p) {
      throw IllegalActionException(
        '${a.runtimeType} needs $p, got ${tx.phase}',
      );
    }
  }

  static void _openingRoll(Tx tx) {
    final w = tx.rng.die();
    final b = tx.rng.die();
    tx.openingDice = [w, b];
    tx.events.add(OpeningRolled(w, b));
    if (w == b) return;
    tx.current = w > b ? Side.white : Side.black;
    tx.turnNumber = 1;
    tx.sevenUsed = true;
    tx.rollsThisTurn = 1;
    tx.rolled = [w, b];
    tx.dice = [w, b];
    tx.phase = Phase.moving;
    for (final side in Side.values) {
      for (final card in tx.config.mods(side).startCards) {
        if (cardById(card).target != TargetKind.none) continue;
        CardLogic.apply(tx, side, card, const []);
        tx.events.add(CardPicked(side, card));
      }
    }
    tx.events
      ..add(TurnStarted(tx.current))
      ..add(DiceRolled(tx.current, [w, b]));
    _checkNoMoves(tx);
  }

  static RollPlan _plan(Tx tx) {
    final mods = tx.config.mods(tx.current);
    final plan = RollPlan(
      count: 2,
      doublesCount: mods.doublesCount,
      cap: mods.capDice,
      p7Multiplier: mods.p7Multiplier,
    );
    for (final e in tx.activeAffecting(tx.current)) {
      EffectSystem.handler(e.kind).onBeforeRoll(tx, e, plan);
    }
    return plan;
  }

  static void _roll(Tx tx) {
    final plan = _plan(tx);
    final bonus = tx.rollsThisTurn > 0;
    if (tx.config.sevenEnabled && !tx.sevenUsed && !bonus) {
      final dry = tx.inv(tx.current).dry;
      final odds = tx.config.sevenPity
          ? SevenOdds.chance(dry, base: tx.config.p7)
          : tx.config.p7;
      final p = (odds * plan.p7Multiplier).clamp(0.0, 1.0);
      final seven = tx.rng.nextDouble() < p;
      final inv0 = tx.inv(tx.current);
      tx.setInv(tx.current, inv0.copyWith(dry: seven ? 0 : inv0.dry + 1));
      if (seven) {
        tx.sevenUsed = true;
        tx.rolled = [7, 7];
        tx.dice = [];
        final inv = tx.inv(tx.current);
        tx.setInv(tx.current, inv.copyWith(sevens: inv.sevens + 1));
        CardLogic.dealOffer(tx, tx.current);
        if (tx.offer.isEmpty) {
          tx.phase = Phase.preRoll;
        } else {
          tx.phase = Phase.sevenPick;
          tx.events.add(SevenRolled(tx.current, List.of(tx.offer)));
        }
        return;
      }
    }
    _rollNormal(tx, plan);
  }

  static void _rollNormal(Tx tx, RollPlan plan) {
    int one() {
      var v = tx.rng.die();
      if (plan.rerollOnes && v <= 2) v = tx.rng.die();
      v = (v + plan.bonus).clamp(1, 6);
      if (v < plan.minValue) v = plan.minValue;
      if (plan.evenUp && v.isOdd) v = v + 1 > 6 ? 6 : v + 1;
      if (plan.halve) v = (v + 1) ~/ 2;
      return v.clamp(1, plan.cap);
    }

    final values = [for (var i = 0; i < plan.count; i++) one()];
    if (plan.forceFirst != null && values.isNotEmpty) {
      values[0] = plan.forceFirst!.clamp(1, plan.cap);
    }
    if (plan.forceDouble && values.length == 2) values[1] = values[0];
    tx.movesThisRoll = [];
    if (values.length == 3) {
      tx.choiceDice = values;
      tx.rolled = List.of(values);
      tx.dice = [];
      tx.phase = Phase.chooseDice;
      tx.events.add(DiceRolled(tx.current, values));
      return;
    }
    _setDice(tx, values, doublesCount: plan.doublesCount);
  }

  static List<int> _finalize(
    Tx tx,
    List<int> raw, {
    required bool doublesCount,
  }) {
    if (raw.length == 1) return [raw[0]];
    if (raw[0] == raw[1] && doublesCount) {
      return [raw[0], raw[0], raw[0], raw[0]];
    }
    return List.of(raw);
  }

  /// Installs a fresh roll [raw] (1 or 2 values) and enters [Phase.moving].
  static void _setDice(
    Tx tx,
    List<int> raw, {
    required bool doublesCount,
    bool fixedBonus = false,
  }) {
    tx.rolled = List.of(raw);
    tx.dice = _finalize(tx, raw, doublesCount: doublesCount);
    tx.rollsThisTurn++;
    tx.movesThisRoll = [];
    tx.phase = Phase.moving;
    tx.events.add(DiceRolled(tx.current, List.of(raw), bonus: fixedBonus));
    if (tx.dice.length == 4) {
      final mods = tx.config.mods(tx.current);
      final inv = tx.inv(tx.current);
      final doubles = inv.doubles + 1;
      var rerolls = inv.rerolls;
      if (mods.rerollEveryNthDouble > 0 &&
          doubles % mods.rerollEveryNthDouble == 0) {
        rerolls++;
        tx.events.add(TokenGranted(tx.current, 'reroll'));
      }
      tx.setInv(tx.current, inv.copyWith(doubles: doubles, rerolls: rerolls));
    }
    if (!fixedBonus) {
      for (final e in tx.activeAffecting(tx.current)) {
        EffectSystem.handler(e.kind).onRoll(tx, e, raw);
      }
    }
    _checkNoMoves(tx);
  }

  static void _checkNoMoves(Tx tx) {
    if (tx.phase == Phase.moving && legalMoves(tx.freeze()).isEmpty) {
      tx.events.add(NoLegalMoves(tx.current));
    }
  }

  static void _pick(Tx tx, int index) {
    final side = tx.current;
    final card = tx.offer.removeAt(index);
    final inv = tx.inv(side);
    tx.setInv(side, inv.copyWith(cards: [...inv.cards, card]));
    tx.events.add(CardPicked(side, card));
    final def = cardById(card);
    if (def.target != TargetKind.none) {
      if (CardLogic.allTargets(tx, side, card).isEmpty) {
        tx.events.add(CardFizzled(side, card));
        _afterPick(tx);
        return;
      }
      tx.pendingCard = card;
      tx.phase = Phase.cardTarget;
      return;
    }
    CardLogic.apply(tx, side, card, const []);
    _afterPick(tx);
  }

  static void _afterPick(Tx tx) {
    if (tx.phase == Phase.gameOver) return;
    tx.picksLeft--;
    if (tx.picksLeft > 0 && tx.offer.isNotEmpty) {
      tx.phase = Phase.sevenPick;
      return;
    }
    tx.offer = [];
    tx.picksLeft = 0;
    tx.phase = Phase.preRoll;
  }

  static void _playMove(Tx tx, Move move) {
    applyBoardMove(tx, tx.current, move);
    if (tx.phase == Phase.gameOver) return;
    tx.dice.remove(move.die);
    tx.movesThisRoll.add(move);
  }

  /// Applies a checker movement (also used by Teleport) with every side
  /// effect: hits, phoenix, landmines, bear-off bookkeeping, effect hooks and
  /// the win check.
  static void applyBoardMove(Tx tx, Side side, Move move) {
    final opp = side.opponent;
    final ctx = EffectSystem.moveContext(tx, side);
    final sim = TurnSim.fromBoard(tx.board, side, ctx);
    final hit = move.to != Pos.off && sim.theirs[25 - move.to] == 1;
    final outcome = sim.apply(move);
    tx.board = sim.toBoard(side);
    tx.events.add(MovePlayed(side, move));
    if (move.ghost) {
      final inv = tx.inv(side);
      tx.setInv(side, inv.copyWith(ghost: inv.ghost - 1));
    }
    final toAbs = move.to == Pos.off ? 0 : toAbsolute(side, move.to);
    final fromAbs = move.from == Pos.bar ? 0 : toAbsolute(side, move.from);
    if (hit) {
      final inv = tx.inv(side);
      tx.setInv(side, inv.copyWith(hits: inv.hits + 1));
      tx.events.add(CheckerHit(opp, toAbs));
      if (outcome.phoenixUsed) {
        final oi = tx.inv(opp);
        tx.setInv(opp, oi.copyWith(phoenix: oi.phoenix - 1));
        if (outcome.phoenixPoint != 0) {
          tx.events.add(
            PhoenixRose(opp, toAbsolute(opp, outcome.phoenixPoint)),
          );
        }
      }
      for (final e in List.of(tx.effects)) {
        EffectSystem.handler(e.kind).onHit(tx, e, opp, toAbs);
      }
    }
    if (outcome.mined) {
      tx.effects.removeWhere(
        (e) =>
            e.kind == EffectKind.landmine && e.owner == opp && e.point == toAbs,
      );
      tx.events.add(MineTriggered(side, toAbs));
    }
    if (move.to == Pos.off) {
      tx.events.add(CheckerBorneOff(side, fromAbs));
      final inv = tx.inv(side);
      if (!inv.borneFirst) {
        var rerolls = inv.rerolls;
        if (tx.config.mods(side).firstBearOffReroll) {
          rerolls++;
          tx.events.add(TokenGranted(side, 'reroll'));
        }
        tx.setInv(side, inv.copyWith(borneFirst: true, rerolls: rerolls));
      }
    }
    for (final e in List.of(tx.effects)) {
      EffectSystem.handler(e.kind)
          .onMoveApplied(tx, e, side, fromAbs, toAbs, mined: outcome.mined);
    }
    EffectSystem.cleanup(tx);
    if (tx.board.borneOff(side) == Pos.checkers) {
      endGame(tx, side, null);
    }
  }

  static void _endRoll(Tx tx) {
    if (tx.rollQueue.isNotEmpty) {
      final next = tx.rollQueue.removeAt(0);
      tx.movesThisRoll = [];
      if (next.isEmpty) {
        tx.dice = [];
        tx.rolled = [];
        tx.phase = Phase.preRoll;
      } else {
        final plan = _plan(tx);
        _setDice(tx, next, doublesCount: plan.doublesCount, fixedBonus: true);
      }
      return;
    }
    finishTurn(tx);
  }

  /// Ticks effects for the current side and hands the turn over.
  static void finishTurn(Tx tx) {
    final side = tx.current;
    final kept = <ActiveEffect>[];
    for (final e in tx.effects) {
      if (e.affected == side && e.isActive(tx.turnNumber)) {
        final left = e.turnsLeft - 1;
        if (left > 0) kept.add(e.copyWith(turnsLeft: left));
      } else {
        kept.add(e);
      }
    }
    tx.effects = kept;
    final extra = tx.extraTurn;
    startTurn(tx, extra ? side : side.opponent, extra: extra);
  }

  static void startTurn(Tx tx, Side side, {bool extra = false}) {
    tx
      ..current = side
      ..turnNumber += 1
      ..phase = Phase.preRoll
      ..dice = []
      ..rolled = []
      ..choiceDice = []
      ..movesThisRoll = []
      ..rollsThisTurn = 0
      ..rollQueue = []
      ..extraTurn = false
      ..sevenUsed = false
      ..offer = []
      ..picksLeft = 0
      ..pendingCard = null
      ..skipping = false;
    tx.events.add(TurnStarted(side, extra: extra));
    for (final e in tx.activeAffecting(side)) {
      EffectSystem.handler(e.kind).onTurnStart(tx, e);
    }
    if (tx.skipping) {
      tx.skipping = false;
      tx.events.add(TurnSkipped(side));
      finishTurn(tx);
    }
  }

  /// Ends the game. [type] null computes normal / gammon / backgammon.
  static void endGame(Tx tx, Side winner, WinType? type) {
    final loser = winner.opponent;
    var t = type;
    if (t == null) {
      if (tx.board.borneOff(loser) > 0) {
        t = WinType.normal;
      } else {
        final l = tx.board.of(loser);
        var back = l[Pos.bar] > 0;
        for (var p = 19; p <= 24 && !back; p++) {
          if (l[p] > 0) back = true;
        }
        t = back ? WinType.backgammon : WinType.gammon;
      }
    }
    final points = t.multiplier * tx.cubeValue;
    tx.result = GameResult(winner, t, points);
    tx.phase = Phase.gameOver;
    tx.dice = [];
    tx.events.add(GameEnded(winner, t, points));
  }
}
