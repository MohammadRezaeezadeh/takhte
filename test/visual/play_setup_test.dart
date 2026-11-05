// Play setup: no opponent picker — the computer opponent is a random
// personality each game; the 7–7 chance level goes into the match config.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:haftnard/core/ai/personality.dart';
import 'package:haftnard/core/rules/seven_odds.dart';
import 'package:haftnard/game/audio.dart';
import 'package:haftnard/game/match_controller.dart';
import 'package:haftnard/game/scene/board_game.dart';
import 'package:haftnard/ui/game/seven_overlay.dart';
import 'package:haftnard/ui/screens/play_setup.dart';

import 'screens_test.dart' show harness;

void main() {
  setUpAll(() {
    Sfx.instance.available = false;
    SevenOverlay.useSensors = false;
    kAiUseIsolates = false;
  });

  final vertical = find.byWidgetPredicate(
    (w) => w is Scrollable && w.axisDirection == AxisDirection.down,
  );

  Future<void> reveal(WidgetTester t, Finder f) =>
      t.scrollUntilVisible(f, 150, scrollable: vertical.first);

  Future<MatchController> start(WidgetTester t, {String? level}) async {
    await t.pumpWidget(harness(const PlaySetupScreen()));
    await t.pump(const Duration(milliseconds: 300));
    if (level != null) {
      final chip = find.byKey(ValueKey('seven-$level'));
      await reveal(t, chip);
      await t.tap(find.descendant(of: chip, matching: find.byType(ChoiceChip)));
      await t.pump(const Duration(milliseconds: 200));
    }
    final go = find.byKey(const ValueKey('start-button'));
    await reveal(t, go);
    await t.tap(go);
    for (var i = 0; i < 20 && BoardGame.current == null; i++) {
      await t.pump(const Duration(milliseconds: 100));
    }
    return BoardGame.current!.controller;
  }

  Future<void> leave(WidgetTester t) async {
    await t.pumpWidget(const SizedBox());
    await t.pump(const Duration(seconds: 5));
  }

  testWidgets('no opponent list; the computer is a random personality', (
    t,
  ) async {
    t.view.devicePixelRatio = 1;
    t.view.physicalSize = const Size(420, 900);
    addTearDown(t.view.reset);
    await t.pumpWidget(harness(const PlaySetupScreen()));
    await t.pump(const Duration(milliseconds: 300));
    for (final p in kPersonalities) {
      expect(find.text(p.name('en')), findsNothing, reason: p.id);
    }
    expect(find.byKey(const ValueKey('ai-tile')), findsOneWidget);

    final seen = <String>{};
    for (var i = 0; i < 12 && seen.length < 2; i++) {
      final c = await start(t);
      seen.add(c.session.black.personalityId!);
      expect(c.session.black.ai, isTrue);
      await leave(t);
    }
    expect(seen.length, greaterThan(1), reason: 'always the same opponent');
  });

  testWidgets('the 7–7 chance level sets the match odds', (t) async {
    t.view.devicePixelRatio = 1;
    t.view.physicalSize = const Size(420, 900);
    addTearDown(t.view.reset);
    var c = await start(t);
    expect(c.match.config.p7, SevenLevel.normal.base);
    await leave(t);
    c = await start(t, level: 'veryHigh');
    expect(c.match.config.p7, SevenLevel.veryHigh.base);
    await leave(t);
    c = await start(t, level: 'low');
    expect(c.match.config.p7, SevenLevel.low.base);
    await leave(t);
  });
}
