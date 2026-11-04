import 'dart:convert';
import 'dart:io';

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

  test('attuning a card makes it more likely in your offers', () {
    final run = JourneyRun(seed: 5, coins: 200)..openShop();
    final att = run.shop.firstWhere((o) => o.kind == 'attune');
    expect(run.buy(att, banishCard: CardId.fog), isTrue);
    expect(run.attuned, [CardId.fog]);
    expect(run.playerMods(null).favored, [CardId.fog]);
    final back = JourneyRun.fromJson(
      (jsonDecode(jsonEncode(run.toJson())) as Map).cast(),
    );
    expect(back.attuned, [CardId.fog]);
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
    expect(kTalismans.length, greaterThanOrEqualTo(60));
    expect(kTalismans.map((t) => t.id).toSet().length, kTalismans.length);
    for (final t in kTalismans) {
      expect(t.descFa, isNotEmpty);
      expect(t.nameFa, isNotEmpty);
      expect(t.price, greaterThan(0));
    }
  });

  test('every talisman hook in the code has a catalogue entry', () {
    final src = File('lib/meta/journey.dart').readAsStringSync();
    final ids = {
      for (final m in RegExp(r"has\('([a-z_]+)'\)").allMatches(src)) m[1]!,
    };
    final defined = kTalismans.map((t) => t.id).toSet();
    expect(ids.difference(defined), isEmpty);
  });

  test('start-card relics deal untargeted cards that open the match', () {
    for (final t in kTalismans) {
      final run = JourneyRun(seed: 3)..talismans.add(t.id);
      for (final c in run.playerMods(null).startCards) {
        expect(cardById(c).target, TargetKind.none, reason: t.id);
      }
    }
    final run = JourneyRun(seed: 3)..talismans.add('serpent_eye');
    expect(run.playerMods(null).startCards, [CardId.curse]);
  });

  test('new talisman hooks', () {
    JourneyRun with_(String id) => JourneyRun(seed: 5)..talismans.add(id);
    final base = JourneyRun(seed: 5);
    expect(
      with_('clover').playerMods(null).p7Multiplier,
      closeTo(base.playerMods(null).p7Multiplier * 1.25, 1e-9),
    );
    final lens = with_('mosaic_lens').playerMods(null);
    expect(lens.offerBonus, base.playerMods(null).offerBonus + 1);
    expect(lens.p7Multiplier, lessThan(base.playerMods(null).p7Multiplier));
    expect(
      with_('witch_knot').opponentMods(null).offerBonus,
      base.opponentMods(null).offerBonus - 1,
    );
    final ring = with_('sultan_ring').playerMods(null);
    expect(ring.startLucky, 1);
    expect(ring.startRerolls, 1);
    final miser = with_('miser_chest')..coins = 100;
    final plain = JourneyRun(seed: 5)..coins = 100;
    expect(miser.keptCoins - plain.keptCoins, 20);
    final map = with_('treasure_map')..coins = 100;
    expect(map.keptCoins - plain.keptCoins, 60);
  });
}
