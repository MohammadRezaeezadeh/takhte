// Headless AI-vs-AI balance simulation.
//
//   dart run tool/simulate.dart --games 2000 [--p7 0.15] [--difficulty medium]
//                               [--out docs/balance/report.md] [--quiet]
//
// Reports win rate per card / rarity, first-player advantage, game length and
// 7–7 frequency.
// ignore_for_file: avoid_print
import 'dart:io';

import 'package:haftnard/core/ai/ai.dart';
import 'package:haftnard/core/ai/personality.dart';
import 'package:haftnard/core/effects/cards.dart';
import 'package:haftnard/core/rules/actions.dart';
import 'package:haftnard/core/rules/engine.dart';
import 'package:haftnard/core/rules/events.dart';
import 'package:haftnard/core/rules/state.dart';
import 'package:haftnard/core/rules/types.dart';

class GameStats {
  Side? winner;
  Side? starter;
  int turns = 0;
  int rolls = 0;
  int sevens = 0;
  WinType? type;
  final Map<Side, Set<String>> cards = {Side.white: {}, Side.black: {}};
  final Map<Side, int> cardCount = {Side.white: 0, Side.black: 0};
}

GameStats playOne(GameConfig cfg, AiConfig w, AiConfig b) {
  final st = GameStats();
  var s = GameState.initial(cfg);
  final brains = {Side.white: AiBrain(w), Side.black: AiBrain(b)};
  var guard = 0;
  while (!s.isOver && guard++ < 4000) {
    final actor = Engine.actor(s);
    for (final a in brains[actor]!.decide(s)) {
      if (s.isOver) break;
      if (a is PlayMove && !Engine.legalMoves(s).contains(a.move)) break;
      if (a is EndTurn && !Engine.canEndTurn(s)) break;
      final r = Engine.apply(s, a);
      for (final e in r.events) {
        switch (e) {
          case TurnStarted():
            st.turns++;
            st.starter ??= e.side;
          case DiceRolled(bonus: false):
            st.rolls++;
          case SevenRolled():
            st.sevens++;
            st.rolls++;
          case CardPicked():
            st.cards[e.side]!.add(e.cardId);
            st.cardCount[e.side] = st.cardCount[e.side]! + 1;
          default:
        }
      }
      s = r.state;
    }
  }
  st.winner = s.result?.winner;
  st.type = s.result?.type;
  return st;
}

String pct(num x) => '${(x * 100).toStringAsFixed(1)}%';

void main(List<String> args) {
  var games = 1000;
  var p7 = 0.15;
  var difficulty = Difficulty.medium;
  var out = 'docs/balance/report.md';
  var quiet = false;
  var forced = 0;
  for (var i = 0; i < args.length; i++) {
    switch (args[i]) {
      case '--games':
        games = int.parse(args[++i]);
      case '--p7':
        p7 = double.parse(args[++i]);
      case '--difficulty':
        difficulty = Difficulty.values.byName(args[++i]);
      case '--out':
        out = args[++i];
      case '--quiet':
        quiet = true;
      case '--forced':
        forced = int.parse(args[++i]);
    }
  }

  final sw = Stopwatch()..start();
  // Pass 1: realistic 7–7 frequency and classic baseline.
  final baseGames = (games / 4).ceil();
  var baseSevens = 0;
  var baseRolls = 0;
  var classicStarterWins = 0;
  var classicTurns = 0;
  for (var g = 0; g < baseGames; g++) {
    final st = playOne(
      GameConfig(seed: 90000 + g),
      AiConfig(difficulty: difficulty, seed: g),
      AiConfig(difficulty: difficulty, seed: g + 7),
    );
    baseSevens += st.sevens;
    baseRolls += st.rolls;
    final c = playOne(
      GameConfig(mode: GameMode.classic, seed: 70000 + g),
      AiConfig(difficulty: difficulty, seed: g),
      AiConfig(difficulty: difficulty, seed: g + 7),
    );
    if (c.winner == c.starter) classicStarterWins++;
    classicTurns += c.turns;
  }

  // Pass 2: card statistics with a boosted p7 for sample size.
  final cardTaken = <String, int>{};
  final cardWins = <String, int>{};
  final rarityTaken = <Rarity, int>{};
  final rarityWins = <Rarity, int>{};
  var starterWins = 0;
  var totalTurns = 0;
  var gammons = 0;
  var finished = 0;
  final personalities = kPersonalities.map((p) => p.id).toList();
  for (var g = 0; g < games; g++) {
    final st = playOne(
      GameConfig(seed: 10000 + g, p7: p7),
      AiConfig(
        difficulty: difficulty,
        seed: g,
        personalityId: personalities[g % personalities.length],
      ),
      AiConfig(
        difficulty: difficulty,
        seed: g * 3 + 1,
        personalityId: personalities[(g + 2) % personalities.length],
      ),
    );
    if (st.winner == null) continue;
    finished++;
    totalTurns += st.turns;
    if (st.winner == st.starter) starterWins++;
    if (st.type == WinType.gammon || st.type == WinType.backgammon) gammons++;
    for (final side in Side.values) {
      final mine = st.cards[side]!;
      final theirs = st.cards[side.opponent]!;
      for (final c in mine) {
        if (theirs.contains(c)) continue; // both took it: no signal
        cardTaken[c] = (cardTaken[c] ?? 0) + 1;
        if (st.winner == side) cardWins[c] = (cardWins[c] ?? 0) + 1;
        final r = cardById(c).rarity;
        rarityTaken[r] = (rarityTaken[r] ?? 0) + 1;
        if (st.winner == side) rarityWins[r] = (rarityWins[r] ?? 0) + 1;
      }
    }
    if (!quiet && g % 100 == 99) {
      print('  ${g + 1}/$games games (${sw.elapsed.inSeconds}s)');
    }
  }

  final b = StringBuffer()
    ..writeln('# Balance report')
    ..writeln()
    ..writeln(
      'Generated by `dart run tool/simulate.dart --games $games '
      '--p7 $p7 --difficulty ${difficulty.name}` '
      'on ${DateTime.now().toUtc().toIso8601String().substring(0, 10)}.',
    )
    ..writeln()
    ..writeln('## Baseline')
    ..writeln()
    ..writeln('| Metric | Value |')
    ..writeln('| --- | --- |')
    ..writeln(
      '| 7–7 per roll at base p7 (1/36 = 2.8%) | '
      '${pct(baseRolls == 0 ? 0 : baseSevens / baseRolls)} |',
    )
    ..writeln(
      '| 7–7 per game at base p7 | '
      '${(baseSevens / baseGames).toStringAsFixed(2)} |',
    )
    ..writeln(
      '| Classic: starter win rate | '
      '${pct(classicStarterWins / baseGames)} |',
    )
    ..writeln(
      '| Classic: avg turns | '
      '${(classicTurns / baseGames).toStringAsFixed(1)} |',
    )
    ..writeln(
      '| Seven (p7=$p7): starter win rate | '
      '${pct(finished == 0 ? 0 : starterWins / finished)} |',
    )
    ..writeln(
      '| Seven (p7=$p7): avg turns | '
      '${(finished == 0 ? 0 : totalTurns / finished).toStringAsFixed(1)} |',
    )
    ..writeln(
      '| Seven (p7=$p7): gammon+ rate | '
      '${pct(finished == 0 ? 0 : gammons / finished)} |',
    )
    ..writeln()
    ..writeln('## Win rate of the side that took a card')
    ..writeln()
    ..writeln(
      'Games where both sides took the same card are excluded. '
      'Target: no card above ~58% (+8%).',
    )
    ..writeln()
    ..writeln('| Card | Rarity | Taken | Win rate | Flag |')
    ..writeln('| --- | --- | --- | --- | --- |');
  final ids = cardTaken.keys.toList()
    ..sort(
      (x, y) =>
          (cardWins[y] ?? 0) / cardTaken[y]! -
                  (cardWins[x] ?? 0) / cardTaken[x]! >
              0
          ? 1
          : -1,
    );
  for (final c in ids) {
    final n = cardTaken[c]!;
    final wr = (cardWins[c] ?? 0) / n;
    final flag = n < 30
        ? 'low sample'
        : wr > 0.58
        ? '**strong**'
        : wr < 0.42
        ? 'weak'
        : '';
    b.writeln(
      '| ${cardById(c).nameEn} | ${cardById(c).rarity.name} | $n | '
      '${pct(wr)} | $flag |',
    );
  }
  b
    ..writeln()
    ..writeln('## By rarity')
    ..writeln()
    ..writeln('| Rarity | Taken | Win rate |')
    ..writeln('| --- | --- | --- |');
  for (final r in Rarity.values) {
    final n = rarityTaken[r] ?? 0;
    if (n == 0) continue;
    b.writeln('| ${r.name} | $n | ${pct((rarityWins[r] ?? 0) / n)} |');
  }
  if (forced > 0) {
    // Intrinsic power: White can only ever be offered card c; Black never
    // rolls 7–7. Lift per pick = (win rate - baseline) / picks per game.
    var baseWins = 0;
    for (var g = 0; g < forced; g++) {
      final st = playOne(
        GameConfig(
          seed: 50000 + g,
          p7: p7,
          black: const SideMods(p7Multiplier: 0),
          white: const SideMods(p7Multiplier: 0),
        ),
        AiConfig(difficulty: difficulty, seed: g),
        AiConfig(difficulty: difficulty, seed: g + 99),
      );
      if (st.winner == Side.white) baseWins++;
    }
    final base = baseWins / forced;
    b
      ..writeln()
      ..writeln('## Forced-pick power (selection-bias free)')
      ..writeln()
      ..writeln(
        'White may only be offered one card (p7=$p7), Black never rolls 7–7, '
        '$forced games per card. Baseline (no cards either side): ${pct(base)}. '
        'Target: lift per pick ≤ +8%.',
      )
      ..writeln()
      ..writeln(
        '| Card | Rarity | Win rate | Picks/game | Lift per pick | Flag |',
      )
      ..writeln('| --- | --- | --- | --- | --- | --- |');
    final rows = <(String, double, double, double)>[];
    for (final c in kCards) {
      var wins = 0;
      var picks = 0;
      for (var g = 0; g < forced; g++) {
        final st = playOne(
          GameConfig(
            seed: 50000 + g,
            p7: p7,
            white: SideMods(cardPool: [c.id]),
            black: const SideMods(p7Multiplier: 0),
          ),
          AiConfig(difficulty: difficulty, seed: g),
          AiConfig(difficulty: difficulty, seed: g + 99),
        );
        if (st.winner == Side.white) wins++;
        picks += st.cardCount[Side.white]!;
      }
      final wr = wins / forced;
      final ppg = picks / forced;
      rows.add((c.id, wr, ppg, ppg == 0 ? 0 : (wr - base) / ppg));
      if (!quiet) print('  forced ${c.id}: ${pct(wr)}');
    }
    rows.sort((x, y) => y.$4.compareTo(x.$4));
    for (final (id, wr, ppg, lift) in rows) {
      final flag = lift > 0.08 ? '**strong**' : (lift < -0.02 ? 'harmful' : '');
      b.writeln(
        '| ${cardById(id).nameEn} | ${cardById(id).rarity.name} | ${pct(wr)} | '
        '${ppg.toStringAsFixed(2)} | ${lift >= 0 ? '+' : ''}${pct(lift)} | $flag |',
      );
    }
  }
  b
    ..writeln()
    ..writeln('Simulated in ${sw.elapsed.inSeconds}s.');

  final file = File(out)..parent.createSync(recursive: true);
  file.writeAsStringSync(b.toString());
  if (!quiet) print(b);
  print(
    'Wrote $out ($finished/$games games finished, ${sw.elapsed.inSeconds}s)',
  );
}
