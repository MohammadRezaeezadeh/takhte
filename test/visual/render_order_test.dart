// Regression: a moving checker must never be painted under the stack it
// lands on, and resting stacks must always paint in index order.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:haftnard/core/ai/personality.dart';
import 'package:haftnard/core/rules/match.dart';
import 'package:haftnard/game/audio.dart';
import 'package:haftnard/game/match_controller.dart';
import 'package:haftnard/game/scene/board_game.dart';
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

  testWidgets('paint order: stacks by index, travelling checkers on top', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(400, 860);
    addTearDown(tester.view.reset);
    final svc = SaveService(MemorySaveStore());
    svc.data.settings = const Settings(sound: false, music: false);
    final session = MatchSession(
      match: MatchState(const MatchConfig(seed: 11, p7: 0)),
      white: const SeatConfig.ai(
        personalityId: 'hammer',
        difficulty: Difficulty.medium,
        name: 'W',
      ),
      black: const SeatConfig.ai(
        personalityId: 'fox',
        difficulty: Difficulty.medium,
        name: 'B',
      ),
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [saveServiceProvider.overrideWithValue(svc)],
        child: HaftNardApp(home: GameScreen(session: session)),
      ),
    );
    var movingFrames = 0;
    var frames = 0;
    for (var i = 0; i < 4000 && !session.match.isOver; i++) {
      await tester.pump(const Duration(milliseconds: 16));
      final g = BoardGame.current;
      if (g == null || !g.isLoaded) continue;
      final order = g.debugPaintOrder();
      frames++;
      final firstTop = order.indexWhere((e) => e.onTop);
      if (firstTop >= 0) {
        movingFrames++;
        expect(
          order.skip(firstTop).every((e) => e.onTop),
          isTrue,
          reason: 'a resting checker painted above a moving one',
        );
      }
      // Resting checkers of each slot paint bottom (0) to top.
      final lastIndex = <Object, int>{};
      for (final e in order.where((e) => !e.onTop)) {
        final prev = lastIndex[e.slot];
        if (prev != null) {
          expect(e.index, greaterThan(prev), reason: 'stack ${e.slot}');
        }
        lastIndex[e.slot] = e.index;
      }
      if (movingFrames > 300) break;
    }
    expect(frames, greaterThan(100));
    expect(movingFrames, greaterThan(20), reason: 'saw checkers travel');
    expect(tester.takeException(), isNull);
  });
}
