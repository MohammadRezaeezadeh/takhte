import 'dart:math' as math;

import 'package:haftnard/core/effects/cards.dart';
import 'package:haftnard/meta/cosmetics.dart';

/// Lifetime statistics.
class Stats {
  Stats({
    this.games = 0,
    this.wins = 0,
    this.mars = 0,
    this.kupMars = 0,
    this.sevens = 0,
    this.hits = 0,
    this.streak = 0,
    this.bestStreak = 0,
    this.journeysWon = 0,
    this.bestJourneyStage = 0,
    this.minesTriggered = 0,
    this.phoenixes = 0,
    this.coinWins = 0,
    this.classicWins = 0,
    this.passPlayGames = 0,
    this.legendaries = 0,
    this.bossesBeaten = 0,
    this.dailyJourneys = 0,
    Map<String, int>? cardCounts,
    Map<String, int>? winsByDifficulty,
  }) : cardCounts = cardCounts ?? {},
       winsByDifficulty = winsByDifficulty ?? {};

  factory Stats.fromJson(Map<String, Object?> j) {
    Map<String, int> mi(Object? o) => {
      for (final e in ((o as Map?) ?? const {}).entries)
        e.key as String: e.value as int,
    };
    return Stats(
      games: j['games'] as int? ?? 0,
      wins: j['wins'] as int? ?? 0,
      mars: j['mars'] as int? ?? 0,
      kupMars: j['kupMars'] as int? ?? 0,
      sevens: j['sevens'] as int? ?? 0,
      hits: j['hits'] as int? ?? 0,
      streak: j['streak'] as int? ?? 0,
      bestStreak: j['bestStreak'] as int? ?? 0,
      journeysWon: j['journeysWon'] as int? ?? 0,
      bestJourneyStage: j['bestJourneyStage'] as int? ?? 0,
      minesTriggered: j['mines'] as int? ?? 0,
      phoenixes: j['phoenixes'] as int? ?? 0,
      coinWins: j['coinWins'] as int? ?? 0,
      classicWins: j['classicWins'] as int? ?? 0,
      passPlayGames: j['passPlay'] as int? ?? 0,
      legendaries: j['legendaries'] as int? ?? 0,
      bossesBeaten: j['bosses'] as int? ?? 0,
      dailyJourneys: j['dailies'] as int? ?? 0,
      cardCounts: mi(j['cards']),
      winsByDifficulty: mi(j['winsByDiff']),
    );
  }

  int games;
  int wins;
  int mars;
  int kupMars;
  int sevens;
  int hits;
  int streak;
  int bestStreak;
  int journeysWon;
  int bestJourneyStage;
  int minesTriggered;
  int phoenixes;
  int coinWins;
  int classicWins;
  int passPlayGames;
  int legendaries;
  int bossesBeaten;
  int dailyJourneys;
  final Map<String, int> cardCounts;
  final Map<String, int> winsByDifficulty;

  String? get favoriteCard {
    if (cardCounts.isEmpty) return null;
    return cardCounts.entries.reduce((a, b) => a.value >= b.value ? a : b).key;
  }

  Map<String, Object?> toJson() => {
    'games': games,
    'wins': wins,
    'mars': mars,
    'kupMars': kupMars,
    'sevens': sevens,
    'hits': hits,
    'streak': streak,
    'bestStreak': bestStreak,
    'journeysWon': journeysWon,
    'bestJourneyStage': bestJourneyStage,
    'mines': minesTriggered,
    'phoenixes': phoenixes,
    'coinWins': coinWins,
    'classicWins': classicWins,
    'passPlay': passPlayGames,
    'legendaries': legendaries,
    'bosses': bossesBeaten,
    'dailies': dailyJourneys,
    'cards': cardCounts,
    'winsByDiff': winsByDifficulty,
  };
}

/// Cards available from the start; the rest unlock by level.
const List<String> kStarterCards = [
  CardId.loadedHand,
  CardId.secondChance,
  CardId.luckyCharm,
  CardId.brokenDie,
  CardId.fog,
  CardId.curse,
  CardId.holyShield,
  CardId.phoenix,
  CardId.quicksand,
  CardId.tollGate,
  CardId.chains,
  CardId.landmine,
  CardId.fatesEdit,
  CardId.doubleDown,
  CardId.timeStop,
  CardId.greed,
];

/// Level at which each non-starter card unlocks.
const Map<String, int> kCardUnlockLevel = {
  CardId.sevenMagnet: 2,
  CardId.thief: 2,
  CardId.ironGate: 3,
  CardId.gamblersCoin: 3,
  CardId.mirror: 4,
  CardId.ghostStep: 5,
  CardId.teleport: 6,
  CardId.bloodPact: 7,
  CardId.bargain: 2,
  CardId.luckySix: 2,
  CardId.tailwind: 3,
  CardId.headwind: 3,
  CardId.nightfall: 4,
  CardId.lantern: 4,
  CardId.twinAnchors: 5,
  CardId.hourglassSand: 5,
  CardId.vortex: 6,
  CardId.simorgh: 6,
  CardId.earthquake: 7,
  CardId.minefield: 8,
  CardId.truce: 9,
  CardId.evenOdds: 2,
  CardId.wardOnes: 2,
  CardId.silkPurse: 3,
  CardId.shackle: 3,
  CardId.pickpocket: 4,
  CardId.hexSevens: 4,
  CardId.fortuneTeller: 5,
  CardId.oasis: 5,
  CardId.leadenDice: 6,
  CardId.sprint: 6,
  CardId.royalRoll: 7,
  CardId.bait: 7,
  CardId.caltrops: 8,
  CardId.destiny: 8,
  CardId.reentry: 9,
  CardId.rally: 9,
  CardId.stoneSkin: 10,
  CardId.doubleAgent: 10,
  CardId.homecoming: 11,
  CardId.exile: 12,
  CardId.shieldWall: 12,
  CardId.highStakes: 13,
  CardId.twinDice: 14,
  CardId.sandstorm: 3,
  CardId.caravan: 2,
  CardId.spiritWard: 6,
  CardId.mirage: 7,
  CardId.mountainPass: 8,
  CardId.saffron: 5,
  CardId.treasury: 9,
  CardId.starReader: 11,
  CardId.sevenfold: 12,
  CardId.hailstorm: 13,
  CardId.falconEye: 4,
  CardId.ironDice: 3,
  CardId.eclipse: 6,
  CardId.sultansFavor: 12,
  CardId.bandit: 7,
  CardId.desertRose: 4,
  CardId.twinSuns: 15,
  CardId.coldSnap: 8,
  CardId.pilgrimage: 2,
  CardId.stormEye: 13,
};

/// The player's persistent profile.
class Profile {
  Profile({
    this.xp = 0,
    this.coins = 300,
    this.gems = 10,
    Set<String>? owned,
    Map<ItemType, String>? equipped,
    Stats? stats,
    Set<String>? achievements,
    this.lastDailyClaim,
    Map<String, List<String>>? dailyBought,
    this.name = '',
  }) : owned =
           owned ??
           {
             for (final i in kItems)
               if (i.isFree) i.id,
           },
       equipped = equipped ?? Map.of(kDefaultLoadout),
       stats = stats ?? Stats(),
       achievements = achievements ?? {},
       dailyBought = dailyBought ?? {};

  factory Profile.fromJson(Map<String, Object?> j) => Profile(
    xp: j['xp'] as int? ?? 0,
    coins: j['coins'] as int? ?? 300,
    gems: j['gems'] as int? ?? 10,
    owned: {
      ...((j['owned'] as List<Object?>?) ?? const []).cast<String>(),
      for (final i in kItems)
        if (i.isFree) i.id,
    },
    equipped: {
      ...kDefaultLoadout,
      for (final e in ((j['equipped'] as Map?) ?? const {}).entries)
        if (ItemType.values.any((t) => t.name == e.key))
          ItemType.values.byName(e.key as String): e.value as String,
    },
    stats: Stats.fromJson(
      ((j['stats'] as Map?) ?? const {}).cast<String, Object?>(),
    ),
    achievements: ((j['achievements'] as List<Object?>?) ?? const [])
        .cast<String>()
        .toSet(),
    lastDailyClaim: j['lastDaily'] as String?,
    dailyBought: {
      for (final e in ((j['dailyBought'] as Map?) ?? const {}).entries)
        e.key as String: (e.value as List<Object?>).cast<String>(),
    },
    name: j['name'] as String? ?? '',
  );

  int xp;
  int coins;
  int gems;
  final Set<String> owned;
  final Map<ItemType, String> equipped;
  final Stats stats;
  final Set<String> achievements;
  String? lastDailyClaim;
  final Map<String, List<String>> dailyBought;
  String name;

  /// XP needed to go from level n to n+1.
  static int xpForNext(int level) => 250 + 150 * (level - 1);

  int get level {
    var l = 1;
    var rest = xp;
    while (rest >= xpForNext(l)) {
      rest -= xpForNext(l);
      l++;
    }
    return l;
  }

  /// Progress within the current level (0..1).
  double get levelProgress {
    var l = 1;
    var rest = xp;
    while (rest >= xpForNext(l)) {
      rest -= xpForNext(l);
      l++;
    }
    return rest / xpForNext(l);
  }

  List<String> get unlockedCards => [
    ...kStarterCards,
    for (final e in kCardUnlockLevel.entries)
      if (level >= e.value) e.key,
  ];

  bool canAfford(CosmeticItem i, {bool withGems = false}) =>
      withGems ? gems >= i.gems : coins >= i.coins;

  Map<String, Object?> toJson() => {
    'xp': xp,
    'coins': coins,
    'gems': gems,
    'owned': owned.toList()..sort(),
    'equipped': {for (final e in equipped.entries) e.key.name: e.value},
    'stats': stats.toJson(),
    'achievements': achievements.toList()..sort(),
    if (lastDailyClaim != null) 'lastDaily': lastDailyClaim,
    'dailyBought': dailyBought,
    'name': name,
  };
}

/// Pure economy rules. See docs/ECONOMY.md.
abstract final class Economy {
  static const Map<String, double> difficultyMultiplier = {
    'beginner': 0.6,
    'easy': 0.8,
    'medium': 1.0,
    'hard': 1.3,
    'master': 1.7,
    'human': 0.5,
  };

  /// Coins for finishing a game.
  static int gameCoins({
    required bool won,
    required int points,
    required String difficulty,
    int greed = 0,
  }) {
    final m = difficultyMultiplier[difficulty] ?? 1.0;
    final base = won ? 30 + 12 * points : 10;
    return (base * m).round() + (won ? greed * kGreedCoins : 0);
  }

  /// Bonus coins for winning a whole match of [length] points.
  static int matchBonus({required int length, required String difficulty}) {
    final m = difficultyMultiplier[difficulty] ?? 1.0;
    return length <= 1 ? 0 : (25 * length * m).round();
  }

  static int gameXp({required bool won, required int points}) =>
      40 + (won ? 40 + 10 * math.min(points, 6) : 0);

  /// Gems granted on reaching [level].
  static int levelGems(int level) => level % 5 == 0 ? 20 : 5;

  static const int dailyBonusCoins = 100;

  /// Daily shop discount.
  static const double dailyDiscount = 0.25;
}
