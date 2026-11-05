// Plays complete AI-vs-AI games through the real GameScreen + Flame scene,
// exercising every presentation path (dice, sevens, cards, hits, bear-off,
// game over overlay, rewards).
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:haftnard/core/ai/personality.dart';
import 'package:haftnard/core/effects/cards.dart';
import 'package:haftnard/core/rules/match.dart';
import 'package:haftnard/game/audio.dart';
import 'package:haftnard/game/match_controller.dart';
import 'package:haftnard/meta/meta_state.dart';
import 'package:haftnard/meta/save.dart';
import 'package:haftnard/meta/settings.dart';
import 'package:haftnard/ui/app.dart';
import 'package:haftnard/ui/game/seven_overlay.dart';
import 'package:haftnard/ui/screens/game_screen.dart';

void main() {
  setUpAll(() {
    Sfx.instance.available = false;
    SevenOverlay.useSensors = false;
    kAiUseIsolates = false;
  });

  testWidgets('AI vs AI match plays to the game-over overlay', (tester) async {
    await tester.binding.setSurfaceSize(const Size(400, 860));
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(400, 860);
    final svc = SaveService(MemorySaveStore());
    svc.data.settings = const Settings(
      animSpeed: 2,
      sound: false,
      music: false,
    );
    final session = MatchSession(
      match: MatchState(const MatchConfig(seed: 3, p7: 0.25)),
      white: const SeatConfig.ai(
        personalityId: 'hammer',
        difficulty: Difficulty.easy,
        name: 'W',
      ),
      black: const SeatConfig.ai(
        personalityId: 'fox',
        difficulty: Difficulty.easy,
        name: 'B',
      ),
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [saveServiceProvider.overrideWithValue(svc)],
        child: HaftNardApp(home: GameScreen(session: session)),
      ),
    );
    var over = false;
    for (var i = 0; i < 9000 && !over; i++) {
      await tester.pump(const Duration(milliseconds: 120));
      over = session.match.isOver;
    }
    expect(over, isTrue, reason: 'match did not finish');
    for (var i = 0; i < 40; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(tester.takeException(), isNull);
    expect(svc.data.lastRecord, isNotNull);
    expect(svc.data.profile.stats.games, 1);
    expect(find.byIcon(Icons.replay), findsOneWidget);
  });

  testWidgets('7-7 overlay: inspect then confirm', (tester) async {
    await tester.binding.setSurfaceSize(const Size(400, 860));
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(400, 860);
    int? picked;
    final svc = SaveService(MemorySaveStore());
    svc.data.settings = const Settings(language: 'en');
    await tester.pumpWidget(
      ProviderScope(
        overrides: [saveServiceProvider.overrideWithValue(svc)],
        child: HaftNardApp(
          home: Scaffold(
            body: SevenOverlay(
              offer: const [CardId.fog, CardId.timeStop, CardId.chains],
              picksLeft: 1,
              onPick: (i) => picked = i,
              backId: 'back_boteh',
              frameId: 'frame_enamel',
            ),
          ),
        ),
      ),
    );
    for (var i = 0; i < 30; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    await tester.tap(find.text('Time Stop').first);
    await tester.pump(const Duration(milliseconds: 300));
    expect(picked, isNull);
    expect(find.textContaining('one more full turn'), findsWidgets);
    await tester.tap(find.text('Choose'));
    await tester.pump(const Duration(milliseconds: 300));
    expect(picked, 1);
  });
}
