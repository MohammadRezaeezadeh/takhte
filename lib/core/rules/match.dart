import 'package:haftnard/core/rng/rng.dart';
import 'package:haftnard/core/rules/record.dart';
import 'package:haftnard/core/rules/state.dart';
import 'package:haftnard/core/rules/types.dart';

/// Configuration of a match to N points.
class MatchConfig {
  const MatchConfig({
    this.mode = GameMode.seven,
    this.length = 1,
    this.cubeEnabled = false,
    this.seed = 1,
    this.p7 = 1 / 36,
    this.cardPool,
    this.white = SideMods.none,
    this.black = SideMods.none,
  });

  factory MatchConfig.fromJson(Map<String, Object?> j) => MatchConfig(
    mode: GameMode.values.byName(j['mode']! as String),
    length: j['length']! as int,
    cubeEnabled: j['cube'] as bool? ?? false,
    seed: j['seed']! as int,
    p7: (j['p7'] as num?)?.toDouble() ?? 1 / 36,
    cardPool: (j['pool'] as List<Object?>?)?.cast<String>(),
    white: SideMods.fromJson(
      ((j['wm'] as Map?) ?? const {}).cast<String, Object?>(),
    ),
    black: SideMods.fromJson(
      ((j['bm'] as Map?) ?? const {}).cast<String, Object?>(),
    ),
  );

  final GameMode mode;
  final int length;
  final bool cubeEnabled;
  final int seed;
  final double p7;
  final List<String>? cardPool;
  final SideMods white;
  final SideMods black;

  Map<String, Object?> toJson() => {
    'mode': mode.name,
    'length': length,
    'cube': cubeEnabled,
    'seed': seed,
    'p7': p7,
    if (cardPool != null) 'pool': cardPool,
    'wm': white.toJson(),
    'bm': black.toJson(),
  };
}

/// Pure match bookkeeping: scores, Crawford rule and per-game configs.
class MatchState {
  MatchState(
    this.config, {
    List<int>? scores,
    List<GameResult>? results,
    this.crawfordPlayed = false,
    GameRecord? current,
  }) : scores = scores ?? [0, 0],
       results = results ?? [] {
    this.current = current ?? GameRecord(gameConfig(0, crawford: false));
  }

  factory MatchState.fromJson(Map<String, Object?> j) {
    final cfg = MatchConfig.fromJson((j['config']! as Map).cast());
    return MatchState(
      cfg,
      scores: (j['scores']! as List<Object?>).cast<int>().toList(),
      results: [
        for (final r in j['results']! as List<Object?>)
          GameResult.fromJson((r! as Map).cast()),
      ],
      crawfordPlayed: j['crawfordPlayed'] as bool? ?? false,
      current: GameRecord.fromJson((j['current']! as Map).cast()),
    );
  }

  final MatchConfig config;
  final List<int> scores;
  final List<GameResult> results;
  bool crawfordPlayed;
  late GameRecord current;

  int score(Side s) => scores[s.index];

  int get gameIndex => results.length;

  Side? get winner {
    for (final s in Side.values) {
      if (scores[s.index] >= config.length) return s;
    }
    return null;
  }

  bool get isOver => winner != null;

  GameConfig gameConfig(int index, {required bool crawford}) => GameConfig(
    mode: config.mode,
    seed: deriveSeed(config.seed, index),
    p7: config.p7,
    cubeEnabled: config.cubeEnabled && config.length > 1,
    crawford: crawford,
    cardPool: config.cardPool,
    white: config.white,
    black: config.black,
  );

  /// Records a finished game and prepares the next one (if any).
  void recordResult(GameResult r) {
    results.add(r);
    final wasCrawford = current.config.crawford;
    if (wasCrawford) crawfordPlayed = true;
    scores[r.winner.index] += r.points;
    if (isOver) return;
    final crawford =
        config.cubeEnabled &&
        !crawfordPlayed &&
        !wasCrawford &&
        scores.any((s) => s == config.length - 1);
    current = GameRecord(gameConfig(results.length, crawford: crawford));
  }

  Map<String, Object?> toJson() => {
    'config': config.toJson(),
    'scores': scores,
    'results': [for (final r in results) r.toJson()],
    'crawfordPlayed': crawfordPlayed,
    'current': current.toJson(),
  };
}
