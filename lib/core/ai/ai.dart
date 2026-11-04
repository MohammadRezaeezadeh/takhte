import 'dart:isolate';

import 'package:haftnard/core/ai/eval.dart';
import 'package:haftnard/core/ai/personality.dart';
import 'package:haftnard/core/effects/card_logic.dart';
import 'package:haftnard/core/effects/cards.dart';
import 'package:haftnard/core/rng/rng.dart';
import 'package:haftnard/core/rules/actions.dart';
import 'package:haftnard/core/rules/board.dart';
import 'package:haftnard/core/rules/engine.dart';
import 'package:haftnard/core/rules/move_gen.dart';
import 'package:haftnard/core/rules/state.dart';
import 'package:haftnard/core/rules/types.dart';

/// AI configuration (sendable to isolates).
class AiConfig {
  const AiConfig({
    this.difficulty = Difficulty.medium,
    this.personalityId = 'sage',
    this.seed = 0,
  });

  final Difficulty difficulty;
  final String personalityId;
  final int seed;

  AiPersonality get personality => personalityById(personalityId);
}

/// Decision-making for one AI player. Pure and synchronous; use
/// [AiBrain.decideAsync] from UI code so the main isolate never blocks.
class AiBrain {
  AiBrain(this.config) : _p = config.personality;

  final AiConfig config;
  final AiPersonality _p;

  EvalWeights get _w => _p.weights;

  /// Runs [decide] on a background isolate.
  static Future<List<GameAction>> decideAsync(GameState s, AiConfig cfg) =>
      Isolate.run(() => AiBrain(cfg).decide(s));

  Rng _rngFor(GameState s) => Rng.seeded(
    config.seed ^
        (s.turnNumber * 7919) ^
        (s.movesThisRoll.length * 104729) ^
        s.rng[0],
  );

  /// Actions to perform at the current decision point, for the side that has
  /// to act. In the moving phase this is a full play followed by [EndTurn];
  /// callers should re-ask if any move turns out to be illegal (hidden mines).
  List<GameAction> decide(GameState s) {
    switch (s.phase) {
      case Phase.opening:
        return const [RollOpening()];
      case Phase.preRoll:
        if (Engine.canOfferDouble(s) && _shouldDouble(s)) {
          return const [OfferDouble()];
        }
        return const [RollDice()];
      case Phase.cubeOffered:
        return [if (_shouldTake(s)) const TakeDouble() else const DropDouble()];
      case Phase.sevenPick:
        return [PickCard(pickCard(s))];
      case Phase.cardTarget:
        return [ChooseTargets(chooseTargets(s, s.current, s.pendingCard!))];
      case Phase.chooseDice:
        return [_chooseDice(s)];
      case Phase.moving:
        final alter = _alteration(s);
        if (alter != null) return [alter];
        var play = bestPlay(s);
        if (play.isNotEmpty && !Engine.legalMoves(s).contains(play.first)) {
          // A hidden trap changes what is legal; plan with the true rules.
          play = bestPlay(s, revealTraps: true);
        }
        return [for (final m in play) PlayMove(m), const EndTurn()];
      case Phase.gameOver:
        return const [];
    }
  }

  // --- Moves -----------------------------------------------------------------

  TurnSim _sim(GameState s, Side side, {bool revealTraps = false}) {
    final ctx = Engine.moveContext(s, side, hideMines: !revealTraps);
    return TurnSim.fromBoard(s.board, side, ctx);
  }

  double _eval1(TurnSim t) => Evaluator.evaluate(t.mine, t.theirs, _w);

  /// Best complete play for the current dice.
  List<Move> bestPlay(GameState s, {bool revealTraps = false}) {
    final side = s.current;
    final sim = _sim(s, side, revealTraps: revealTraps);
    final plays = MoveGen.allPlays(sim, s.dice);
    if (plays.length == 1) return plays.first.moves;
    final rng = _rngFor(s);
    final d = config.difficulty;
    if (d == Difficulty.beginner && rng.nextInt(10) < 4) {
      return plays[rng.nextInt(plays.length)].moves;
    }
    final noise = switch (d) {
      Difficulty.beginner => 0.3,
      Difficulty.easy => 0.12,
      Difficulty.medium => 0.025,
      _ => 0.0,
    };
    final scored = [
      for (final p in plays)
        (
          p,
          _eval1(p.result) + (noise > 0 ? (rng.nextDouble() - 0.5) * noise : 0),
        ),
    ]..sort((a, b) => b.$2.compareTo(a.$2));
    if (d.index < Difficulty.hard.index) return scored.first.$1.moves;

    final k = d == Difficulty.master ? 9 : 5;
    var best = scored.first.$1;
    var bestV = -9.0;
    for (final (p, _) in scored.take(k)) {
      final v = _twoPly(p.result, bestV);
      if (v > bestV) {
        bestV = v;
        best = p;
      }
    }
    return best.moves;
  }

  /// Expected value after the opponent's best 1-ply reply, averaged over all
  /// rolls. Star1-style cutoff: stop once the upper bound falls below [alpha].
  double _twoPly(TurnSim after, double alpha) {
    if (after.mine[0] == 15) return _eval1(after);
    var sum = 0.0;
    var remaining = 36;
    for (final (a, b, w) in kRolls) {
      final dice = a == b ? [a, a, a, a] : [a, b];
      final opp = TurnSim(
        mine: List.of(after.theirs),
        theirs: List.of(after.mine),
        ctx: MoveContext.none,
      );
      var oppBest = -9.0;
      for (final p in MoveGen.allPlays(opp, dice)) {
        final v = Evaluator.evaluate(p.result.mine, p.result.theirs);
        if (v > oppBest) oppBest = v;
        if (oppBest >= 1.0) break;
      }
      sum += -oppBest * w;
      remaining -= w;
      if ((sum + remaining * 1.5) / 36 < alpha) return -9;
    }
    return sum / 36;
  }

  List<int> _diceFor(GameState s, List<int> raw) {
    if (raw.length == 1) return [raw[0]];
    final fog = s.effects.any(
      (e) =>
          e.kind == EffectKind.fog &&
          e.affected == s.current &&
          e.isActive(s.turnNumber),
    );
    final doubles = s.config.mods(s.current).doublesCount && !fog;
    return raw[0] == raw[1] && doubles
        ? [raw[0], raw[0], raw[0], raw[0]]
        : List.of(raw);
  }

  /// Value of the best play with [dice] (1-ply).
  double _bestValue(GameState s, List<int> dice) {
    final sim = _sim(s, s.current);
    var best = -9.0;
    for (final p in MoveGen.allPlays(sim, dice)) {
      final v = _eval1(p.result);
      if (v > best) best = v;
    }
    return best;
  }

  GameAction _chooseDice(GameState s) {
    final c = s.choiceDice;
    var best = const ChooseDice(0, 1);
    var bestV = -9.0;
    for (final (i, j) in [(0, 1), (0, 2), (1, 2)]) {
      final v = _bestValue(s, _diceFor(s, [c[i], c[j]]));
      if (v > bestV) {
        bestV = v;
        best = ChooseDice(i, j);
      }
    }
    return best;
  }

  GameAction? _alteration(GameState s) {
    if (!Engine.canAlterRoll(s)) return null;
    final d = config.difficulty;
    final inv = s.inv(s.current);
    final noMoves = Engine.legalMoves(s).isEmpty;
    if (!noMoves && d.index <= Difficulty.easy.index) return null;
    final current = _bestValue(s, s.dice);
    GameAction? best;
    var bestV = current + 0.02;
    if (Engine.canSetFate(s)) {
      for (var i = 0; i < s.rolled.length; i++) {
        for (var v = 1; v <= 6; v++) {
          if (v == s.rolled[i]) continue;
          final raw = List.of(s.rolled)..[i] = v;
          final val = _bestValue(s, _diceFor(s, raw));
          if (val > bestV) {
            bestV = val;
            best = SetFate(i, v);
          }
        }
      }
    }
    if (inv.lucky > 0) {
      for (var i = 0; i < s.dice.length; i++) {
        if (s.dice[i] >= 6 || s.dice.indexOf(s.dice[i]) != i) continue;
        final dice = List.of(s.dice)..[i] += 1;
        final val = _bestValue(s, dice);
        if (val > bestV + 0.03) {
          bestV = val;
          best = UseLucky(i);
        }
      }
    }
    if (best != null) return best;
    if (inv.rerolls > 0) {
      if (noMoves) return const UseReroll();
      // Compare against the average roll.
      var avg = 0.0;
      for (final (a, b, w) in kRolls) {
        avg += _bestValue(s, _diceFor(s, a == b ? [a, a] : [a, b])) * w;
      }
      avg /= 36;
      if (current < avg - 0.18) return const UseReroll();
    }
    return null;
  }

  // --- Cube ------------------------------------------------------------------

  /// Equity for the side to roll in [s].
  double _preRollEquity(GameState s, Side side) {
    final b = s.board;
    return -Evaluator.evaluate(b.of(side.opponent), b.of(side), _w);
  }

  bool _shouldDouble(GameState s) {
    if (config.difficulty == Difficulty.beginner) return false;
    final e = _preRollEquity(s, s.current);
    return e > 0.42 && e < 0.88;
  }

  bool _shouldTake(GameState s) {
    final taker = s.current.opponent;
    final e = -_preRollEquity(s, s.current);
    final threshold = config.difficulty == Difficulty.beginner ? -0.7 : -0.5;
    return e > threshold || s.board.borneOff(taker) > 12;
  }

  // --- Cards -----------------------------------------------------------------

  int pickCard(GameState s) {
    final rng = _rngFor(s);
    var best = 0;
    var bestV = -99.0;
    for (var i = 0; i < s.offer.length; i++) {
      var v = cardValue(s, s.current, s.offer[i]);
      if (config.difficulty == Difficulty.beginner) {
        v += rng.nextDouble() * 0.8;
      } else if (config.difficulty == Difficulty.easy) {
        v += rng.nextDouble() * 0.3;
      }
      if (v > bestV) {
        bestV = v;
        best = i;
      }
    }
    return best;
  }

  bool _contact(Board b, Side side) {
    final mine = b.of(side);
    final theirs = b.of(side.opponent);
    var myBack = 0;
    for (var i = 25; i >= 1; i--) {
      if (mine[i] > 0) {
        myBack = i;
        break;
      }
    }
    var theirBack = 0;
    for (var i = 25; i >= 1; i--) {
      if (theirs[i] > 0) {
        theirBack = i;
        break;
      }
    }
    return myBack > 25 - theirBack;
  }

  /// Heuristic value of taking [card] now (higher is better).
  double cardValue(GameState s, Side side, String card) {
    final def = cardById(card);
    final b = s.board;
    final contact = _contact(b, side);
    final opp = side.opponent;
    double v;
    switch (card) {
      case CardId.loadedHand:
        v = 0.45;
      case CardId.doubleDown:
        v = 0.7;
      case CardId.fatesEdit:
        v = 0.5;
      case CardId.secondChance:
        v = 0.3;
      case CardId.luckyCharm:
        v = 0.2;
      case CardId.sevenMagnet:
        v = 0.25;
      case CardId.brokenDie:
        v = 0.45;
      case CardId.chains:
        v = contact ? 0.55 : 0.25;
      case CardId.fog:
        v = 0.2;
      case CardId.curse:
        v = contact ? 0.3 : 0.4;
      case CardId.mirror:
        v = 0.5;
      case CardId.thief:
        v = 0.15 + (s.inv(opp).stealable > 0 ? 0.3 : 0.1);
      case CardId.holyShield:
        v = contact ? 0.3 : 0.02;
      case CardId.ironGate:
        v = contact ? 0.35 : 0.02;
      case CardId.ghostStep:
        v = contact ? 0.3 : 0.05;
      case CardId.phoenix:
        v = contact ? 0.3 : 0.02;
      case CardId.teleport:
        v = 0.45;
      case CardId.landmine:
        v = contact ? 0.4 : 0.05;
      case CardId.quicksand:
        v = contact ? 0.35 : 0.2;
      case CardId.tollGate:
        v = contact ? 0.2 : 0.25;
      case CardId.timeStop:
        v = 0.9;
      case CardId.bloodPact:
        v = b.allHome(side) ? 0.95 : -0.6 + _p.riskLove * 0.3;
      case CardId.gamblersCoin:
        v = 0.05 + _p.riskLove * 0.45;
      case CardId.greed:
        final lead = b.pips(opp) - b.pips(side);
        v = 0.1 + (lead > 20 ? 0.15 : 0);
      default:
        v = 0.2;
    }
    v *= _p.categoryBias[def.category] ?? 1.0;
    if (def.rarity == Rarity.legendary) v += _p.riskLove * 0.15;
    // Targeted cards: reward a good available target.
    if (def.target != TargetKind.none && v > 0) {
      final t = chooseTargets(s, side, card);
      if (t.isEmpty) return -1;
      v += _targetScore(s, side, card, t) * 0.15;
    }
    return v;
  }

  /// Best targets for [card]; empty if none.
  List<int> chooseTargets(GameState s, Side side, String card) {
    final tx = Tx(s);
    final options = CardLogic.allTargets(tx, side, card);
    if (options.isEmpty) return const [];
    var best = options.first;
    var bestV = -1e9;
    for (final t in options) {
      final v = _targetScore(s, side, card, t);
      if (v > bestV) {
        bestV = v;
        best = t;
      }
    }
    return best;
  }

  double _targetScore(GameState s, Side side, String card, List<int> t) {
    final b = s.board;
    final opp = side.opponent;
    final mine = b.of(side);
    final theirs = b.of(opp);
    final oppPos = [
      for (var q = 1; q <= 25; q++)
        if (theirs[q] > 0) 25 - q,
    ];
    switch (card) {
      case CardId.holyShield:
      case CardId.ironGate:
        final rel = toRelative(side, t.first);
        if (mine[rel] != 1) return 0.1;
        final shots = Evaluator.shots(rel, oppPos, mine, theirs[25] > 0);
        return shots / 36 * (1 + (25 - rel) / 25) * 3;
      case CardId.chains:
        var sc = 0.0;
        for (final abs in t) {
          final rel = toRelative(opp, abs);
          sc += rel / 24 + (rel >= 19 ? 0.5 : 0) + (theirs[rel] == 1 ? 0.4 : 0);
        }
        return sc;
      case CardId.landmine:
        // Likelihood an opponent checker lands here soon.
        final myFrame = toRelative(side, t.first);
        var sc = 0.0;
        for (final x in oppPos) {
          final dist = myFrame - x;
          if (dist >= 1 && dist <= 12) {
            sc += theirs[25 - x] * (dist <= 6 ? 1.0 : 0.4);
          }
        }
        return sc / 3;
      case CardId.quicksand:
        final rel = toRelative(opp, t.first);
        return theirs[rel] * (rel >= 13 ? 1.2 : 0.6) / 2;
      case CardId.tollGate:
        final myFrame = toRelative(side, t.first);
        var behind = 0;
        for (final x in oppPos) {
          if (x < myFrame) behind += theirs[25 - x];
        }
        return behind / 5;
      case CardId.teleport:
        final tx = Tx(s);
        CardLogic.apply(tx, side, card, t);
        return (Evaluator.evaluate(tx.board.of(side), tx.board.of(opp), _w) -
                Evaluator.evaluate(mine, theirs, _w)) *
            6;
      default:
        return 0;
    }
  }
}
