// Self-play hill climbing for the static evaluator weights.
//
//   dart compile exe tool/tune_eval.dart -o build/tune && build/tune 30 300
//
// Each iteration perturbs one weight, plays N 1-ply games (colours
// alternated) against the current best, and keeps the change if it wins
// > 52%. Prints the final weights to paste into EvalWeights.standard.
// ignore_for_file: avoid_print
import 'dart:math' as math;

import 'package:haftnard/core/ai/eval.dart';
import 'package:haftnard/core/rng/rng.dart';
import 'package:haftnard/core/rules/board.dart';
import 'package:haftnard/core/rules/move_gen.dart';
import 'package:haftnard/core/rules/types.dart';

/// Plays a classic game where each side picks its 1-ply best play.
Side play(int seed, EvalWeights w, EvalWeights b) {
  final rng = Rng.seeded(seed);
  var board = Board.initial();
  var side = rng.nextInt(2) == 0 ? Side.white : Side.black;
  for (var turn = 0; turn < 400; turn++) {
    final a = rng.die();
    final c = rng.die();
    final dice = a == c ? [a, a, a, a] : [a, c];
    final sim = TurnSim.fromBoard(board, side);
    final weights = side == Side.white ? w : b;
    var best = -9.0;
    TurnPlay? bestPlay;
    for (final p in MoveGen.allPlays(sim, dice)) {
      final v = Evaluator.evaluate(p.result.mine, p.result.theirs, weights);
      if (v > best) {
        best = v;
        bestPlay = p;
      }
    }
    board = bestPlay!.result.toBoard(side);
    if (board.borneOff(side) == 15) return side;
    side = side.opponent;
  }
  return board.pips(Side.white) < board.pips(Side.black)
      ? Side.white
      : Side.black;
}

double score(EvalWeights cand, EvalWeights base, int games, int seed) {
  var wins = 0;
  for (var g = 0; g < games; g++) {
    final candWhite = g.isEven;
    final winner = play(
      seed + g ~/ 2,
      candWhite ? cand : base,
      candWhite ? base : cand,
    );
    if ((winner == Side.white) == candWhite) wins++;
  }
  return wins / games;
}

EvalWeights mutate(EvalWeights w, int field, double factor) {
  final v = [
    w.pip,
    w.blot,
    w.homePoint,
    w.point,
    w.prime,
    w.anchor,
    w.oppBar,
    w.myBar,
    w.borneOff,
    w.stack,
  ];
  v[field] *= factor;
  return EvalWeights(
    pip: v[0],
    blot: v[1],
    homePoint: v[2],
    point: v[3],
    prime: v[4],
    anchor: v[5],
    oppBar: v[6],
    myBar: v[7],
    borneOff: v[8],
    stack: v[9],
  );
}

void main(List<String> args) {
  final iterations = args.isNotEmpty ? int.parse(args[0]) : 20;
  final games = args.length > 1 ? int.parse(args[1]) : 200;
  final rnd = math.Random(7);
  var best = EvalWeights.standard;
  const names = [
    'pip',
    'blot',
    'homePoint',
    'point',
    'prime',
    'anchor',
    'oppBar',
    'myBar',
    'borneOff',
    'stack',
  ];
  for (var i = 0; i < iterations; i++) {
    final field = rnd.nextInt(names.length);
    final factor = rnd.nextBool() ? 1.3 : 1 / 1.3;
    final cand = mutate(best, field, factor);
    final s = score(cand, best, games, 1000 * (i + 1));
    final keep = s > 0.52;
    print(
      'iter $i ${names[field]} x${factor.toStringAsFixed(2)}: ${(s * 100).toStringAsFixed(1)}%${keep ? '  KEEP' : ''}',
    );
    if (keep) best = cand;
  }
  print(
    'final: pip=${best.pip.toStringAsFixed(3)} blot=${best.blot.toStringAsFixed(3)} '
    'homePoint=${best.homePoint.toStringAsFixed(3)} point=${best.point.toStringAsFixed(3)} '
    'prime=${best.prime.toStringAsFixed(3)} anchor=${best.anchor.toStringAsFixed(3)} '
    'oppBar=${best.oppBar.toStringAsFixed(3)} myBar=${best.myBar.toStringAsFixed(3)} '
    'borneOff=${best.borneOff.toStringAsFixed(3)} stack=${best.stack.toStringAsFixed(3)}',
  );
  print(
    'validation vs standard: ${(score(best, EvalWeights.standard, games * 2, 777777) * 100).toStringAsFixed(1)}%',
  );
}
