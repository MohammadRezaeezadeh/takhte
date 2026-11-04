import 'dart:convert';
import 'dart:io';

import 'package:haftnard/meta/cosmetics.dart';
import 'package:haftnard/meta/profile.dart';
import 'package:haftnard/meta/save.dart';
import 'package:haftnard/meta/settings.dart';
import 'package:haftnard/ui/widgets/fps_overlay.dart';
import 'package:test/test.dart';

void main() {
  test('save round-trips through the store', () async {
    final store = MemorySaveStore();
    final svc = SaveService(store);
    await svc.load();
    svc.data.profile.coins = 1234;
    svc.data.profile.owned.add('board_neon');
    svc.data.settings = const Settings(language: 'fa', sound: false);
    await svc.save();
    final svc2 = SaveService(store);
    final d = await svc2.load();
    expect(d.profile.coins, 1234);
    expect(d.profile.owned, contains('board_neon'));
    expect(d.settings.language, 'fa');
    expect(d.settings.sound, isFalse);
  });

  test('v1 saves migrate', () async {
    final store = MemorySaveStore(
      jsonEncode({
        'version': 1,
        'prefs': {'language': 'en', 'haptics': false},
        'profile': {'coins': 50},
      }),
    );
    final d = await SaveService(store).load();
    expect(d.settings.haptics, isFalse);
    expect(d.profile.coins, 50);
  });

  test('corrupt save falls back to defaults', () async {
    final d = await SaveService(MemorySaveStore('{not json')).load();
    expect(d.profile.coins, 300);
  });

  test('new profiles own every free item and equip defaults', () {
    final p = Profile();
    for (final e in kDefaultLoadout.entries) {
      expect(p.owned, contains(e.value));
      expect(itemById(e.value)!.type, e.key);
    }
  });

  test('levels follow the xp curve', () {
    final p = Profile();
    expect(p.level, 1);
    p.xp = Profile.xpForNext(1);
    expect(p.level, 2);
    p.xp += Profile.xpForNext(2) - 1;
    expect(p.level, 2);
    expect(p.levelProgress, greaterThan(0.9));
  });

  test('economy rewards scale with difficulty and points', () {
    final easy = Economy.gameCoins(won: true, points: 1, difficulty: 'easy');
    final master = Economy.gameCoins(
      won: true,
      points: 1,
      difficulty: 'master',
    );
    final gammon = Economy.gameCoins(won: true, points: 2, difficulty: 'easy');
    expect(master, greaterThan(easy));
    expect(gammon, greaterThan(easy));
    expect(
      Economy.gameCoins(won: false, points: 1, difficulty: 'medium'),
      greaterThan(0),
    );
  });

  test('catalogue is consistent', () {
    expect(kItems.map((i) => i.id).toSet().length, kItems.length);
    expect(itemsOfType(ItemType.board).length, greaterThanOrEqualTo(8));
    for (final b in kBundles) {
      final sum = b.items.fold<int>(0, (a, id) => a + itemById(id)!.coins);
      expect(b.coins, lessThan(sum), reason: '${b.id} must be a discount');
    }
  });

  test('displayed app version matches pubspec', () {
    final pubspec = File('pubspec.yaml').readAsStringSync();
    final v = RegExp(
      r'^version:\s*([0-9.]+)',
      multiLine: true,
    ).firstMatch(pubspec)!.group(1);
    expect(kAppVersion, v);
  });
}
