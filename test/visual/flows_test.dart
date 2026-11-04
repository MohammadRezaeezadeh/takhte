import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:haftnard/game/audio.dart';
import 'package:haftnard/meta/journey.dart';
import 'package:haftnard/meta/meta_state.dart';
import 'package:haftnard/meta/save.dart';
import 'package:haftnard/meta/settings.dart';
import 'package:haftnard/ui/app.dart';
import 'package:haftnard/ui/screens/journey_screen.dart';
import 'package:haftnard/ui/screens/locker_screen.dart';
import 'package:haftnard/ui/screens/settings_screen.dart';
import 'package:haftnard/ui/screens/store_screen.dart';

Future<SaveService> pump(
  WidgetTester t,
  Widget home, {
  SaveService? svc,
  Size size = const Size(420, 900),
}) async {
  Sfx.instance.available = false;
  t.view.devicePixelRatio = 1;
  t.view.physicalSize = size;
  await t.binding.setSurfaceSize(size);
  final s = svc ?? SaveService(MemorySaveStore());
  s.data.settings = const Settings(
    language: 'en',
    sound: false,
    music: false,
    tutorialDone: true,
  );
  await t.pumpWidget(
    ProviderScope(
      overrides: [saveServiceProvider.overrideWithValue(s)],
      child: HaftNardApp(key: UniqueKey(), home: home),
    ),
  );
  for (var i = 0; i < 10; i++) {
    await t.pump(const Duration(milliseconds: 50));
  }
  return s;
}

void main() {
  testWidgets('store: open an item and buy it', (t) async {
    final svc = SaveService(MemorySaveStore());
    svc.data.profile.coins = 5000;
    await pump(t, const StoreScreen(), svc: svc);
    DefaultTabController.of(t.element(find.byType(TabBarView))).index = 3;
    for (var i = 0; i < 10; i++) {
      await t.pump(const Duration(milliseconds: 50));
    }
    await t.tap(find.text('Glass').first);
    await t.pump(const Duration(milliseconds: 300));
    await t.tap(find.text('Buy').last);
    for (var i = 0; i < 10; i++) {
      await t.pump(const Duration(milliseconds: 50));
    }
    expect(svc.data.profile.owned, contains('chk_glass'));
    expect(svc.data.profile.coins, 5000 - 500);
  });

  testWidgets('locker: equip an owned item and randomize', (t) async {
    final svc = SaveService(MemorySaveStore());
    svc.data.profile.owned.add('dice_crystal');
    await pump(t, const LockerScreen(), svc: svc, size: const Size(420, 1800));
    await t.tap(find.text('Crystal'));
    await t.pump(const Duration(milliseconds: 100));
    expect(svc.data.profile.equipped.values, contains('dice_crystal'));
    await t.tap(find.byIcon(Icons.shuffle));
    await t.pump(const Duration(milliseconds: 100));
    expect(t.takeException(), isNull);
  });

  testWidgets('journey: start a run, buy in the shop, leave', (t) async {
    final svc = SaveService(MemorySaveStore());
    await pump(t, const JourneyScreen(), svc: svc);
    await t.tap(find.text('New journey'));
    await t.pump(const Duration(milliseconds: 200));
    expect(find.text('Fight'), findsOneWidget);
    // Jump into the shop state with coins.
    final run = JourneyRun.fromJson(svc.data.journey!)
      ..coins = 500
      ..stage = 1
      ..openShop();
    svc.data.journey = run.toJson();
    await pump(t, const JourneyScreen(), svc: svc);
    expect(find.text('Bazaar stall'), findsOneWidget);
    final price = run.shop.first.price;
    await t.tap(find.text('$price').first);
    await t.pump(const Duration(milliseconds: 200));
    final after = JourneyRun.fromJson(svc.data.journey!);
    expect(after.talismans.length, 1);
    await t.tap(find.text('Continue'));
    await t.pump(const Duration(milliseconds: 200));
    expect(JourneyRun.fromJson(svc.data.journey!).inShop, isFalse);
  });

  testWidgets('settings: toggles persist', (t) async {
    final svc = await pump(t, const SettingsScreen());
    await t.dragUntilVisible(
      find.text('Reduced motion'),
      find.byType(ListView).first,
      const Offset(0, -150),
    );
    await t.ensureVisible(find.text('Reduced motion'));
    await t.pump(const Duration(milliseconds: 100));
    await t.tap(find.text('Reduced motion'));
    await t.pump(const Duration(milliseconds: 100));
    expect(svc.data.settings.reducedMotion, isTrue);
    await t.dragUntilVisible(
      find.text('فارسی'),
      find.byType(ListView).first,
      const Offset(0, 150),
    );
    await t.ensureVisible(find.text('فارسی'));
    await t.pump(const Duration(milliseconds: 100));
    await t.tap(find.text('فارسی'));
    await t.pump(const Duration(milliseconds: 200));
    expect(svc.data.settings.language, 'fa');
  });
}
