// Screenshot sequences of a checker landing on a 3-stack and a 6-stack
// (playtest round 3). Writes PNG frames when SHOT_OUT is set:
//   flutter test test/visual/landing_shots_test.dart --dart-define=SHOT_OUT=dir
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:haftnard/core/ai/personality.dart';
import 'package:haftnard/core/rules/actions.dart';
import 'package:haftnard/core/rules/board.dart';
import 'package:haftnard/core/rules/engine.dart';
import 'package:haftnard/core/rules/match.dart';
import 'package:haftnard/game/audio.dart';
import 'package:haftnard/game/match_controller.dart';
import 'package:haftnard/game/scene/board_game.dart';
import 'package:haftnard/ui/game/seven_overlay.dart';
import 'package:haftnard/ui/screens/game_screen.dart';
import 'package:haftnard/ui/tutorial.dart';

import '../core/helpers.dart';
import 'screens_test.dart' show harness, loadFonts, settle, shot;

void main() {
  setUpAll(() async {
    kAiUseIsolates = false;
    Sfx.instance.available = false;
    SevenOverlay.useSensors = false;
    await loadFonts();
  });

  for (final (name, white, from, die, to, height) in [
    ('stack3', const {13: 1, 8: 3, 6: 5, 24: 2, 18: 4}, 13, 5, 8, 3),
    ('stack6', const {11: 1, 6: 6, 8: 3, 24: 2, 18: 3}, 11, 5, 6, 6),
  ]) {
    testWidgets('landing on a $height-stack', (t) async {
      t.view.devicePixelRatio = 1;
      t.view.physicalSize = const Size(420, 860);
      addTearDown(t.view.reset);
      final board = Board.fromMaps(
        white: white,
        black: const {24: 2, 13: 5, 6: 8},
      );
      final state = movingState(board, [die, 1]);
      final session = MatchSession(
        match: MatchState(const MatchConfig()),
        white: const SeatConfig.human('Me'),
        black: const SeatConfig.ai(
          personalityId: 'fox',
          difficulty: Difficulty.easy,
          name: 'B',
        ),
      );
      await t.pumpWidget(
        harness(
          GameScreen(
            session: session,
            tutorial: [
              TutorialStep(
                titleEn: 'Landing',
                titleFa: 'فرود',
                bodyEn: '',
                bodyFa: '',
                build: () => state,
              ),
            ],
          ),
        ),
      );
      await settle(t);
      final g = BoardGame.current!;
      final before = g.debugCheckers();
      final move = Engine.legalMoves(g.controller.state)
          .firstWhere((m) => m.from == from && m.to == to);
      await shot(t, '${name}_0');
      unawaited(g.controller.act(PlayMove(move)));
      for (var f = 1; f <= 6; f++) {
        await t.pump(const Duration(milliseconds: 60));
        await shot(t, '${name}_$f');
      }
      await settle(t, frames: 10);
      await shot(t, '${name}_7');
      // Same guarantees as the identity test, on these exact stacks.
      final after = g.debugCheckers();
      final moved = after.where(
        (c) => before.firstWhere((b) => b.id == c.id).slot != c.slot,
      );
      expect(moved, hasLength(1));
      expect(moved.single.index, height, reason: 'lands on top');
      for (final c in after) {
        final b = before.firstWhere((x) => x.id == c.id);
        if (c.id != moved.single.id && c.slot == b.slot) {
          expect(c.index, b.index);
        }
      }
      expect(t.takeException(), isNull);
    });
  }
}
