// The redesigned 7–7 choice: tap selects and previews, Choose confirms,
// long-press shows details, tags state duration and target, and the first
// 7–7 walks the player through the screen.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:haftnard/core/effects/cards.dart';
import 'package:haftnard/ui/game/hud.dart';
import 'package:haftnard/ui/game/seven_overlay.dart';

import 'flows_test.dart' show pump;

void main() {
  setUpAll(() => SevenOverlay.useSensors = false);

  Future<(List<String?>, List<int>)> open(
    WidgetTester t, {
    bool guide = false,
    VoidCallback? onGuideDone,
  }) async {
    final previews = <String?>[];
    final picks = <int>[];
    await pump(
      t,
      Scaffold(
        body: SevenOverlay(
          offer: const [CardId.fog, CardId.chains, CardId.timeStop],
          picksLeft: 1,
          onPick: picks.add,
          onPreview: previews.add,
          showGuide: guide,
          onGuideDone: onGuideDone,
          backId: 'back_boteh',
          frameId: 'frame_enamel',
        ),
      ),
    );
    for (var i = 0; i < 30; i++) {
      await t.pump(const Duration(milliseconds: 100));
    }
    return (previews, picks);
  }

  testWidgets('tap previews, another tap switches, Choose confirms', (t) async {
    final (previews, picks) = await open(t);
    expect(find.textContaining('Tap a card'), findsOneWidget);
    await t.tap(find.byKey(const ValueKey('offer-0')));
    await t.pump(const Duration(milliseconds: 300));
    expect(previews.last, CardId.fog);
    expect(picks, isEmpty, reason: 'one tap only previews');
    // Tags: duration and target in plain words.
    expect(find.text('3 turns'), findsOneWidget);
    expect(find.text('Opponent'), findsOneWidget);
    await t.tap(find.byKey(const ValueKey('offer-1')));
    await t.pump(const Duration(milliseconds: 300));
    expect(previews.last, CardId.chains);
    await t.tap(find.byKey(const ValueKey('pick-card')));
    await t.pump(const Duration(milliseconds: 300));
    expect(picks, [1]);
    expect(previews.last, isNull, reason: 'preview cleared on confirm');
  });

  testWidgets('long-press shows the full details', (t) async {
    await open(t);
    await t.longPress(find.byKey(const ValueKey('offer-2')));
    for (var i = 0; i < 6; i++) {
      await t.pump(const Duration(milliseconds: 100));
    }
    expect(find.textContaining('one more full turn'), findsWidgets);
    expect(find.textContaining('extra card at their next 7–7'), findsWidgets);
    expect(find.text('Legendary'), findsWidgets);
  });

  testWidgets('first 7-7 shows a three-step guide', (t) async {
    var done = false;
    await open(t, guide: true, onGuideDone: () => done = true);
    for (var step = 0; step < 3; step++) {
      expect(find.byKey(const ValueKey('seven-guide')), findsOneWidget);
      await t.tap(find.textContaining('Got it'));
      await t.pump(const Duration(milliseconds: 100));
    }
    expect(find.byKey(const ValueKey('seven-guide')), findsNothing);
    expect(done, isTrue);
  });

  testWidgets('effect chips explain themselves on tap; pending is marked', (
    t,
  ) async {
    await pump(
      t,
      const Scaffold(
        body: Center(
          child: EffectChip(
            cardId: CardId.brokenDie,
            buff: false,
            turns: 2,
            pending: "Opponent's next turn",
          ),
        ),
      ),
    );
    expect(find.byIcon(Icons.schedule), findsOneWidget);
    await t.tap(find.byType(EffectChip));
    await t.pump(const Duration(milliseconds: 400));
    expect(find.textContaining("⏳ Opponent's next turn"), findsOneWidget);
    expect(find.textContaining('rolls only one die'), findsOneWidget);
    await t.pump(const Duration(seconds: 5));
  });
}
