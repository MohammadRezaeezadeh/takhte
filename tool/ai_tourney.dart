// Head-to-head AI strength measurement (classic rules, colours alternated).
//
//   dart compile exe tool/ai_tourney.dart -o build/tourney
//   build/tourney --a hard --b medium --games 2000 [--a-noise 0.05]
//       [--b-noise 0.15] [--a-plies 2] [--a-net 1] [--b-net 0]
//       [--nn-file build/nn.txt] [--out docs/balance/ai-tiers.md]
// ignore_for_file: avoid_print
import 'dart:io';
import 'dart:isolate';
import 'dart:math' as math;

import 'package:haftnard/core/ai/ai.dart';
import 'package:haftnard/core/ai/nn_eval.dart';
import 'package:haftnard/core/ai/personality.dart';
import 'package:haftnard/core/rules/actions.dart';
import 'package:haftnard/core/rules/engine.dart';
import 'package:haftnard/core/rules/state.dart';
import 'package:haftnard/core/rules/types.dart';

/// Thinking time of side A in moving decisions (this isolate).
int aMicros = 0;
int aMoves = 0;

Side playOne(int seed, AiConfig white, AiConfig black, Side aSide) {
  var s = GameState.initial(GameConfig(mode: GameMode.classic, seed: seed));
  final brains = {Side.white: AiBrain(white), Side.black: AiBrain(black)};
  final sw = Stopwatch();
  var guard = 0;
  while (!s.isOver && guard++ < 3000) {
    final actor = Engine.actor(s);
    final timed = actor == aSide && s.phase == Phase.moving;
    sw
      ..reset()
      ..start();
    final actions = brains[actor]!.decide(s);
    if (timed) {
      aMicros += sw.elapsedMicroseconds;
      aMoves++;
    }
    for (final a in actions) {
      if (s.isOver) break;
      if (a is PlayMove && !Engine.legalMoves(s).contains(a.move)) break;
      if (a is EndTurn && !Engine.canEndTurn(s)) break;
      s = Engine.apply(s, a).state;
    }
  }
  return s.result?.winner ?? Side.white;
}

/// [wins, A thinking µs, A moving decisions] over games [from, to).
List<int> chunk(
  int from,
  int to,
  AiConfig a,
  AiConfig b,
  int seedBase,
  String? nnFile,
) {
  if (nnFile != null) {
    final flat = [
      for (final x in File(nnFile).readAsStringSync().split(','))
        double.parse(x),
    ];
    final hidden = (flat.length - 1) ~/ (NnEval.inputs + 2);
    AiBrain.network = NnEval.fromFlat(flat, hidden);
  }
  var wins = 0;
  for (var g = from; g < to; g++) {
    final aWhite = g.isEven;
    final seed = seedBase + g ~/ 2; // same dice for both colour assignments
    final w = aWhite
        ? playOne(
            seed,
            AiConfig(
              difficulty: a.difficulty,
              noise: a.noise,
              plies: a.plies,
              net: a.net,
              seed: g,
            ),
            AiConfig(
              difficulty: b.difficulty,
              noise: b.noise,
              plies: b.plies,
              net: b.net,
              seed: g + 1,
            ),
            Side.white,
          )
        : playOne(
            seed,
            AiConfig(
              difficulty: b.difficulty,
              noise: b.noise,
              plies: b.plies,
              net: b.net,
              seed: g + 1,
            ),
            AiConfig(
              difficulty: a.difficulty,
              noise: a.noise,
              plies: a.plies,
              net: a.net,
              seed: g,
            ),
            Side.black,
          );
    if ((w == Side.white) == aWhite) wins++;
  }
  return [wins, aMicros, aMoves];
}

Future<void> main(List<String> args) async {
  String arg(String k, String d) {
    final i = args.indexOf(k);
    return i >= 0 && i + 1 < args.length ? args[i + 1] : d;
  }

  double? num0(String k) => args.contains(k) ? double.parse(arg(k, '0')) : null;
  int? int0(String k) => args.contains(k) ? int.parse(arg(k, '0')) : null;
  final a = AiConfig(
    difficulty: Difficulty.values.byName(arg('--a', 'hard')),
    noise: num0('--a-noise'),
    plies: int0('--a-plies'),
    net: int0('--a-net')?.isOdd,
  );
  final b = AiConfig(
    difficulty: Difficulty.values.byName(arg('--b', 'medium')),
    noise: num0('--b-noise'),
    plies: int0('--b-plies'),
    net: int0('--b-net')?.isOdd,
  );
  final nnFile = args.contains('--nn-file') ? arg('--nn-file', '') : null;
  final games = int.parse(arg('--games', '400'));
  final procs = int.parse(arg('--procs', '${Platform.numberOfProcessors}'));
  final seedBase = int.parse(arg('--seed', '50000'));
  final per = (games / procs).ceil();
  final futures = <Future<List<int>>>[];
  for (var p = 0; p < procs; p++) {
    final from = p * per;
    final to = math.min(games, from + per);
    if (from >= to) break;
    futures.add(Isolate.run(() => chunk(from, to, a, b, seedBase, nnFile)));
  }
  final parts = await Future.wait(futures);
  final wins = parts.fold<int>(0, (x, y) => x + y[0]);
  final micros = parts.fold<int>(0, (x, y) => x + y[1]);
  final moves = parts.fold<int>(0, (x, y) => x + y[2]);
  final ms = moves == 0 ? 0 : micros / moves / 1000;
  final rate = wins / games;
  final se = math.sqrt(rate * (1 - rate) / games);
  final line =
      '| ${a.difficulty.name}${a.noise != null ? ' n=${a.noise}' : ''}${a.plies != null ? ' p=${a.plies}' : ''}${a.net != null ? ' net=${a.net}' : ''} '
      '| ${b.difficulty.name}${b.noise != null ? ' n=${b.noise}' : ''}${b.plies != null ? ' p=${b.plies}' : ''}${b.net != null ? ' net=${b.net}' : ''} '
      '| $games | ${(rate * 100).toStringAsFixed(1)}% ± ${(se * 196).toStringAsFixed(1)} | ${ms.toStringAsFixed(1)} ms |';
  print(line);
  final out = arg('--out', '');
  if (out.isNotEmpty) {
    final f = File(out);
    if (!f.existsSync()) {
      f.writeAsStringSync(
        '# AI tier head-to-head\n\nClassic rules, colours alternated, paired dice seeds. '
        'Generated by `tool/ai_tourney.dart`.\n\n| A | B | Games | A win rate (95% CI) | A ms/move |\n| --- | --- | --- | --- | --- |\n',
      );
    }
    f.writeAsStringSync('$line\n', mode: FileMode.append);
  }
}
