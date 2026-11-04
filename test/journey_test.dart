import 'dart:convert';

import 'package:haftnard/core/effects/cards.dart';
import 'package:haftnard/meta/journey.dart';
import 'package:test/test.dart';

void main() {
  test('map has 8 stages with bosses at 3, 6 and 8', () {
    final run = JourneyRun(seed: 42);
    final m = run.map;
    expect(m.length, 8);
    expect(m[2].boss, isNotNull);
    expect(m[5].boss, isNotNull);
    expect(m[7].boss!.id, 'shah');
    expect(m.where((s) => s.boss != null).length, 3);
    expect(
      JourneyRun(seed: 42).map.map((s) => s.personality),
      m.map((s) => s.personality),
    );
  });

  test('winning opens a shop and talismans change mods', () {
    final run = JourneyRun(seed: 1)..recordMatch(won: true, coinsEarned: 200);
    expect(run.stage, 1);
    expect(run.inShop, isTrue);
    expect(run.shop.where((o) => o.kind == 'talisman').length, 3);
    final t = run.shop.firstWhere((o) => o.kind == 'talisman');
    expect(run.buy(t), isTrue);
    expect(run.talismans, contains(t.talisman));
    run.talismans
      ..clear()
      ..addAll(['fourth_card', 'lucky_star', 'iron_will']);
    final mods = run.playerMods(null);
    expect(mods.offerBonus, 1);
    expect(mods.p7Multiplier, closeTo(1.5, 1e-9));
    expect(mods.startRerolls, 2);
  });

  test('banish removes a card from the pool', () {
    final run = JourneyRun(seed: 2, coins: 100)..openShop();
    final ban = run.shop.firstWhere((o) => o.kind == 'banish');
    expect(run.buy(ban, banishCard: CardId.fog), isTrue);
    expect(run.cardPool([CardId.fog, CardId.curse]), [CardId.curse]);
    // Banishing only shrinks the player's own offers.
    expect(run.playerMods(null, pool: [CardId.fog, CardId.curse]).cardPool, [
      CardId.curse,
    ]);
    expect(run.opponentMods(null).cardPool, isNull);
  });

  test('losing ends the run unless Second Wind', () {
    final a = JourneyRun(seed: 3)..recordMatch(won: false);
    expect(a.over, isTrue);
    final b = JourneyRun(seed: 3, talismans: ['second_wind'])
      ..recordMatch(won: false);
    expect(b.over, isFalse);
    b.recordMatch(won: false);
    expect(b.over, isTrue);
  });

  test('completing all stages wins and JSON round-trips', () {
    final run = JourneyRun(seed: 9);
    for (var i = 0; i < 8; i++) {
      run.recordMatch(won: true, coinsEarned: 10);
    }
    expect(run.won, isTrue);
    expect(run.keptCoins, greaterThan(300));
    final back = JourneyRun.fromJson(
      (jsonDecode(jsonEncode(run.toJson())) as Map).cast(),
    );
    expect(back.stage, 8);
    expect(back.won, isTrue);
  });

  test('talisman catalogue is consistent', () {
    expect(kTalismans.map((t) => t.id).toSet().length, kTalismans.length);
    for (final t in kTalismans) {
      expect(t.descFa, isNotEmpty);
      expect(t.price, greaterThan(0));
    }
  });
}
