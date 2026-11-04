import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:haftnard/core/rules/board.dart';
import 'package:haftnard/core/rules/state.dart';
import 'package:haftnard/core/rules/types.dart';
import 'package:haftnard/meta/achievements.dart';
import 'package:haftnard/meta/cosmetics.dart';
import 'package:haftnard/meta/meta_state.dart';
import 'package:haftnard/meta/profile.dart';
import 'package:haftnard/meta/save.dart';
import 'package:haftnard/meta/settings.dart';

(ProviderContainer, MetaNotifier, SaveService) make() {
  final svc = SaveService(MemorySaveStore());
  final c = ProviderContainer(
    overrides: [saveServiceProvider.overrideWithValue(svc)],
  );
  return (c, c.read(metaProvider.notifier), svc);
}

GameState finished(Side winner, WinType type, {int points = 1}) =>
    GameState.initial(
      GameConfig(startingBoard: Board.initial()),
    ).copyWith(phase: Phase.gameOver, result: GameResult(winner, type, points));

void main() {
  test('buying spends coins, requires level and equips', () {
    final (c, n, _) = make();
    final p = n.profile..coins = 5000;
    final glass = itemById('chk_glass')!;
    expect(n.buy(glass), isTrue);
    expect(p.owned, contains('chk_glass'));
    expect(p.coins, 5000 - glass.coins);
    expect(n.buy(glass), isFalse, reason: 'already owned');
    final locked = itemById('board_garden')!;
    expect(n.buy(locked), isFalse, reason: 'level gate');
    n.equip(ItemType.checker, 'chk_glass');
    expect(
      c.read(metaProvider).profile.equipped[ItemType.checker],
      'chk_glass',
    );
    n.equip(ItemType.board, 'board_neon');
    expect(
      p.equipped[ItemType.board],
      isNot('board_neon'),
      reason: 'not owned',
    );
  });

  test('gem items and bundles', () {
    final (_, n, _) = make();
    final p = n.profile
      ..gems = 100
      ..coins = 10000
      ..xp = 99999;
    expect(n.buy(itemById('board_cosmic')!), isTrue);
    expect(p.owned, contains('board_cosmic'));
    // 100 - 60, plus gems from level achievements unlocked on the way.
    final achievementGems = kAchievements
        .where((a) => p.achievements.contains(a.id))
        .fold<int>(0, (a, b) => a + b.gems);
    expect(p.gems, 40 + achievementGems);
    expect(n.buyBundle(kBundles.first), isTrue);
    expect(p.owned.containsAll(kBundles.first.items), isTrue);
    expect(n.buyBundle(kBundles.first), isFalse);
  });

  test('daily shop and daily bonus', () {
    final (_, n, _) = make();
    final day = DateTime(2026, 11, 4);
    final shop = n.dailyShop(day);
    expect(shop.length, lessThanOrEqualTo(4));
    expect(shop.every((i) => i.unlockLevel <= n.profile.level), isTrue);
    expect(n.dailyShop(day).map((i) => i.id), shop.map((i) => i.id));
    expect(n.canClaimDaily(day), isTrue);
    final before = n.profile.coins;
    expect(n.claimDaily(day), Economy.dailyBonusCoins);
    expect(n.profile.coins, before + Economy.dailyBonusCoins);
    expect(n.claimDaily(day), 0);
    expect(n.canClaimDaily(day.add(const Duration(days: 1))), isTrue);
  });

  test('recording games pays rewards, levels up and unlocks achievements', () {
    final (_, n, _) = make();
    final r = n.recordGame(
      GameOutcome(
        end: finished(Side.white, WinType.gammon, points: 2),
        humanSides: {Side.white},
        difficulty: 'hard',
        passAndPlay: false,
      ),
    );
    expect(r.coins, greaterThan(0));
    expect(r.xp, greaterThan(0));
    expect(
      r.achievements.map((a) => a.id),
      containsAll(['first_win', 'mars_1', 'beat_hard']),
    );
    expect(n.profile.stats.wins, 1);
    expect(n.profile.stats.mars, 1);
    final loss = n.recordGame(
      GameOutcome(
        end: finished(Side.black, WinType.normal),
        humanSides: {Side.white},
        difficulty: 'easy',
        passAndPlay: false,
      ),
    );
    expect(loss.coins, greaterThan(0));
    expect(n.profile.stats.streak, 0);
    final pp = n.recordGame(
      GameOutcome(
        end: finished(Side.black, WinType.normal),
        humanSides: {Side.white, Side.black},
        difficulty: 'human',
        passAndPlay: true,
      ),
    );
    expect(pp.coins, greaterThan(0));
    expect(n.profile.stats.passPlayGames, 1);
    for (var i = 0; i < 12; i++) {
      n.recordGame(
        GameOutcome(
          end: finished(Side.white, WinType.normal),
          humanSides: {Side.white},
          difficulty: 'master',
          passAndPlay: false,
        ),
      );
    }
    expect(n.profile.level, greaterThan(1));
    expect(
      n.profile.achievements,
      containsAll(['win_10', 'streak_7', 'beat_master']),
    );
  });

  test('match bonus, journey records, event notes, settings, saves', () {
    final (_, n, svc) = make();
    final r = n.recordGame(
      GameOutcome(
        end: finished(Side.white, WinType.normal),
        humanSides: {Side.white},
        difficulty: 'medium',
        passAndPlay: false,
        matchOver: true,
        matchWon: true,
        matchLength: 5,
      ),
    );
    expect(
      r.coins,
      greaterThan(
        Economy.gameCoins(won: true, points: 1, difficulty: 'medium'),
      ),
    );
    n
      ..recordJourney(stage: 3, won: false, keptCoins: 50, bossBeaten: true)
      ..recordJourney(
        stage: 8,
        won: true,
        keptCoins: 50,
        bossBeaten: true,
        daily: true,
      )
      ..noteEvent(mine: true, phoenix: true, coinWin: true)
      ..updateSettings(const Settings(language: 'fa'))
      ..saveActiveMatch({'x': 1})
      ..saveLastRecord({'y': 2})
      ..saveJourney({'z': 3})
      ..addCoins(10)
      ..randomizeLoadout();
    expect(n.profile.stats.bestJourneyStage, 8);
    expect(n.profile.stats.bossesBeaten, 2);
    expect(n.profile.achievements, contains('daily_1'));
    expect(n.profile.stats.minesTriggered, 1);
    expect(svc.data.settings.language, 'fa');
    expect(svc.data.activeMatch, {'x': 1});
    n.resetProgress();
    expect(n.profile.coins, 300);
    expect(svc.data.activeMatch, isNull);
  });
}
