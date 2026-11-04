import 'dart:async';
import 'dart:math' as math;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:haftnard/core/effects/cards.dart';
import 'package:haftnard/core/rng/rng.dart';
import 'package:haftnard/core/rules/state.dart';
import 'package:haftnard/core/rules/types.dart';
import 'package:haftnard/meta/achievements.dart';
import 'package:haftnard/meta/cosmetics.dart';
import 'package:haftnard/meta/profile.dart';
import 'package:haftnard/meta/save.dart';
import 'package:haftnard/meta/settings.dart';

/// Immutable snapshot handed to widgets; [rev] changes on every mutation.
class MetaState {
  const MetaState(this.settings, this.profile, this.rev);
  final Settings settings;
  final Profile profile;
  final int rev;
}

/// Summary of a finished game for rewards/stats.
class GameOutcome {
  const GameOutcome({
    required this.end,
    required this.humanSides,
    required this.difficulty,
    required this.passAndPlay,
    this.matchOver = false,
    this.matchWon = false,
    this.matchLength = 1,
    this.journey = false,
  });

  final GameState end;

  /// Sides played by the local human(s).
  final Set<Side> humanSides;

  /// AI difficulty name, or 'human'.
  final String difficulty;
  final bool passAndPlay;
  final bool matchOver;
  final bool matchWon;
  final int matchLength;
  final bool journey;
}

class Rewards {
  Rewards({
    this.coins = 0,
    this.xp = 0,
    this.gems = 0,
    List<int>? levelUps,
    List<Achievement>? achievements,
  }) : levelUps = levelUps ?? [],
       achievements = achievements ?? [];
  int coins;
  int xp;
  int gems;
  final List<int> levelUps;
  final List<Achievement> achievements;
}

final saveServiceProvider = Provider<SaveService>(
  (ref) => throw UnimplementedError('overridden in main'),
);

final metaProvider = NotifierProvider<MetaNotifier, MetaState>(
  MetaNotifier.new,
);

class MetaNotifier extends Notifier<MetaState> {
  SaveService get _svc => ref.read(saveServiceProvider);
  SaveData get data => _svc.data;

  @override
  MetaState build() => MetaState(_svc.data.settings, _svc.data.profile, 0);

  void _commit() {
    state = MetaState(data.settings, data.profile, state.rev + 1);
    unawaited(_svc.save());
  }

  Profile get profile => data.profile;

  void updateSettings(Settings s) {
    data.settings = s;
    _commit();
  }

  // --- Store ---------------------------------------------------------------

  bool canBuy(CosmeticItem i) =>
      !profile.owned.contains(i.id) && profile.level >= i.unlockLevel;

  /// Buys [item] for coins (or gems if it has only a gem price).
  bool buy(CosmeticItem item, {int? priceOverride}) {
    if (!canBuy(item)) return false;
    final p = profile;
    if (item.gems > 0 && item.coins == 0) {
      if (p.gems < item.gems) return false;
      p.gems -= item.gems;
    } else {
      final price = priceOverride ?? item.coins;
      if (p.coins < price) return false;
      p.coins -= price;
    }
    p.owned.add(item.id);
    _checkAchievements(Rewards());
    _commit();
    return true;
  }

  bool buyBundle(Bundle b) {
    final p = profile;
    final missing = b.items.where((id) => !p.owned.contains(id)).toList();
    if (missing.isEmpty || p.coins < b.coins) return false;
    p.coins -= b.coins;
    p.owned.addAll(b.items);
    _checkAchievements(Rewards());
    _commit();
    return true;
  }

  void equip(ItemType t, String id) {
    if (!profile.owned.contains(id)) return;
    profile.equipped[t] = id;
    _commit();
  }

  void randomizeLoadout() {
    final r = math.Random();
    for (final t in ItemType.values) {
      if (t == ItemType.emote) continue;
      final owned = itemsOfType(t)
          .where((i) => profile.owned.contains(i.id))
          .toList();
      if (owned.isNotEmpty) {
        profile.equipped[t] = owned[r.nextInt(owned.length)].id;
      }
    }
    _commit();
  }

  /// Four discounted unowned items, seeded by the date (offline).
  List<CosmeticItem> dailyShop(DateTime now) {
    final key = now.year * 10000 + now.month * 100 + now.day;
    final rng = Rng.seeded(key);
    final level = profile.level;
    final pool = kItems
        .where(
          (i) =>
              !i.isFree &&
              i.coins > 0 &&
              i.unlockLevel <= level &&
              !profile.owned.contains(i.id),
        )
        .toList();
    rng.shuffle(pool);
    return pool.take(4).toList();
  }

  int dailyPrice(CosmeticItem i) =>
      (i.coins * (1 - Economy.dailyDiscount)).round();

  static String dayKey(DateTime d) => '${d.year}-${d.month}-${d.day}';

  bool canClaimDaily(DateTime now) => profile.lastDailyClaim != dayKey(now);

  int claimDaily(DateTime now) {
    if (!canClaimDaily(now)) return 0;
    profile
      ..lastDailyClaim = dayKey(now)
      ..coins += Economy.dailyBonusCoins;
    _commit();
    return Economy.dailyBonusCoins;
  }

  // --- Saves ---------------------------------------------------------------

  void saveActiveMatch(Map<String, Object?>? json) {
    data.activeMatch = json;
    unawaited(_svc.save());
  }

  void saveLastRecord(Map<String, Object?> json) {
    data.lastRecord = json;
    unawaited(_svc.save());
  }

  void saveJourney(Map<String, Object?>? json) {
    data.journey = json;
    unawaited(_svc.save());
  }

  void addCoins(int n) {
    profile.coins += n;
    _commit();
  }

  void resetProgress() {
    data
      ..profile = Profile()
      ..activeMatch = null
      ..journey = null
      ..lastRecord = null;
    _commit();
  }

  // --- Results -------------------------------------------------------------

  Rewards recordGame(GameOutcome o) {
    final p = profile;
    final st = p.stats;
    final res = o.end.result!;
    final rewards = Rewards();
    final levelBefore = p.level;
    st.games++;
    for (final side in o.humanSides) {
      final inv = o.end.inv(side);
      st.sevens += inv.sevens;
      st.hits += inv.hits;
      for (final c in inv.cards) {
        st.cardCounts[c] = (st.cardCounts[c] ?? 0) + 1;
        if (cardById(c).rarity == Rarity.legendary) st.legendaries++;
      }
    }
    if (o.passAndPlay) {
      st.passPlayGames++;
      rewards.coins = Economy.gameCoins(
        won: true,
        points: res.points,
        difficulty: 'human',
      );
      rewards.xp = Economy.gameXp(won: false, points: 0);
    } else {
      final won = o.humanSides.contains(res.winner);
      if (won) {
        st.wins++;
        st.streak++;
        st.bestStreak = math.max(st.bestStreak, st.streak);
        if (res.type == WinType.gammon) st.mars++;
        if (res.type == WinType.backgammon) st.kupMars++;
        if (o.end.config.mode == GameMode.classic) st.classicWins++;
        st.winsByDifficulty[o.difficulty] =
            (st.winsByDifficulty[o.difficulty] ?? 0) + 1;
      } else {
        st.streak = 0;
      }
      if (!o.journey) {
        final greed = o.end.inv(res.winner).greed;
        rewards.coins = Economy.gameCoins(
          won: won,
          points: res.points,
          difficulty: o.difficulty,
          greed: won ? greed : 0,
        );
        if (o.matchOver && o.matchWon) {
          rewards.coins += Economy.matchBonus(
            length: o.matchLength,
            difficulty: o.difficulty,
          );
        }
      }
      rewards.xp = Economy.gameXp(won: won, points: res.points);
    }
    p
      ..coins += rewards.coins
      ..xp += rewards.xp;
    for (var l = levelBefore + 1; l <= p.level; l++) {
      rewards.levelUps.add(l);
      final g = Economy.levelGems(l);
      rewards.gems += g;
      p.gems += g;
    }
    _checkAchievements(rewards);
    _commit();
    return rewards;
  }

  /// Journey bookkeeping: stage reached and completion.
  void recordJourney({
    required int stage,
    required bool won,
    required int keptCoins,
    bool bossBeaten = false,
    bool daily = false,
  }) {
    final st = profile.stats;
    st.bestJourneyStage = math.max(st.bestJourneyStage, stage);
    if (bossBeaten) st.bossesBeaten++;
    if (won) st.journeysWon++;
    if (won && daily) st.dailyJourneys++;
    profile.coins += keptCoins;
    _checkAchievements(Rewards());
    _commit();
  }

  void noteEvent({
    bool mine = false,
    bool phoenix = false,
    bool coinWin = false,
  }) {
    final st = profile.stats;
    if (mine) st.minesTriggered++;
    if (phoenix) st.phoenixes++;
    if (coinWin) st.coinWins++;
  }

  void _checkAchievements(Rewards r) {
    for (final a in kAchievements) {
      if (profile.achievements.contains(a.id)) continue;
      if (a.check(profile)) {
        profile.achievements.add(a.id);
        profile.gems += a.gems;
        r
          ..gems += a.gems
          ..achievements.add(a);
      }
    }
  }
}
