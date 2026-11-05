// Playtest round 3: a checker landing on a stack must fly straight to the
// top and stay there; checkers already on the stack never move, re-order or
// animate. Tracked by checker identity over 1,000 moves (normal moves, hits,
// bar entry, undo, AI moves and bear-off).
import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:haftnard/core/ai/ai.dart';
import 'package:haftnard/core/ai/personality.dart';
import 'package:haftnard/core/rules/actions.dart';
import 'package:haftnard/core/rules/match.dart';
import 'package:haftnard/core/rules/state.dart';
import 'package:haftnard/game/audio.dart';
import 'package:haftnard/game/layout.dart';
import 'package:haftnard/game/match_controller.dart';
import 'package:haftnard/game/scene/board_game.dart';
import 'package:haftnard/meta/meta_state.dart';
import 'package:haftnard/meta/save.dart';
import 'package:haftnard/meta/settings.dart';
import 'package:haftnard/ui/app.dart';
import 'package:haftnard/ui/game/seven_overlay.dart';
import 'package:haftnard/ui/screens/game_screen.dart';

typedef Chk = ({
  int id,
  Slot slot,
  int index,
  Offset pos,
  bool moving,
  bool onTop,
});

void main() {
  setUpAll(() {
    Sfx.instance.available = false;
    SevenOverlay.useSensors = false;
    kAiUseIsolates = false;
  });

  testWidgets('1,000 moves: stacks keep identity, arrivals land on top', (
    t,
  ) async {
    t.view.devicePixelRatio = 1;
    t.view.physicalSize = const Size(400, 860);
    addTearDown(t.view.reset);
    final svc = SaveService(MemorySaveStore());
    svc.data.settings = const Settings(
      sound: false,
      music: false,
      animSpeed: 2,
      tutorialDone: true,
    );
    final rng = math.Random(5);
    final brain = AiBrain(const AiConfig(difficulty: Difficulty.easy));
    var checkedMoves = 0;
    var undos = 0;
    var hits = 0;
    var bearOffs = 0;
    var game = 0;

    while (checkedMoves < 1000 && game < 30) {
      final session = MatchSession(
        match: MatchState(
          MatchConfig(mode: GameMode.classic, seed: 700 + game),
        ),
        white: const SeatConfig.human('Me'),
        black: const SeatConfig.ai(
          personalityId: 'fox',
          difficulty: Difficulty.easy,
          name: 'B',
        ),
      );
      await t.pumpWidget(
        ProviderScope(
          overrides: [saveServiceProvider.overrideWithValue(svc)],
          child: HaftNardApp(
            home: GameScreen(key: ValueKey(game), session: session),
          ),
        ),
      );
      game++;
      List<Chk>? settled;
      Rect? settledField;
      final animated = <int>{};
      var undidThisTurn = false;
      for (var i = 0; i < 20000 && !session.match.isOver; i++) {
        await t.pump(const Duration(milliseconds: 16));
        final g = BoardGame.current;
        if (g == null || !g.isLoaded) continue;
        // The end-of-game presentation is not a move.
        if (g.controller.state.phase == Phase.gameOver) break;
        final now = g.debugCheckers();
        for (final c in now) {
          if (c.moving) animated.add(c.id);
        }
        final idle = now.every((c) => !c.moving);
        if (idle) {
          final before = settled;
          // Only compare under the same board geometry (a resize, e.g. the
          // game-over panel, legitimately re-lays everything out).
          if (before != null && settledField == g.layout.field) {
            final r = _check(before, now, animated, g);
            checkedMoves += r.moved;
            hits += r.toBar;
            bearOffs += r.toOff;
          }
          settled = now;
          settledField = g.layout.field;
          animated.clear();
        }
        // Drive the human seat (with undos) once the scene is idle.
        final c = g.controller;
        final s = c.state;
        if (!c.waitingForHuman || !idle) continue;
        switch (s.phase) {
          case Phase.opening:
            unawaited(c.act(const RollOpening()));
          case Phase.preRoll:
            undidThisTurn = false;
            unawaited(c.act(const RollDice()));
          case Phase.moving:
            if (c.canUndo && !undidThisTurn && rng.nextDouble() < 0.35) {
              undidThisTurn = true;
              undos++;
              c.undo();
            } else {
              unawaited(c.act(brain.decide(s).first));
            }
          default:
            break;
        }
      }
      for (var i = 0; i < 40; i++) {
        await t.pump(const Duration(milliseconds: 100));
      }
    }
    expect(checkedMoves, greaterThanOrEqualTo(1000));
    expect(undos, greaterThan(20), reason: 'undo exercised');
    expect(hits, greaterThan(10), reason: 'hits and bar entry exercised');
    expect(bearOffs, greaterThan(15), reason: 'bear-off exercised');
    expect(t.takeException(), isNull);
    await t.pumpWidget(const SizedBox());
    await t.pump(const Duration(seconds: 5));
  }, timeout: const Timeout(Duration(minutes: 20)));
}

({int moved, int toBar, int toOff}) _check(
  List<Chk> before,
  List<Chk> after,
  Set<int> animated,
  BoardGame g,
) {
  final b = {for (final c in before) c.id: c};
  final changed = {
    for (final c in after)
      if (b[c.id]!.slot != c.slot) c.id,
  };
  if (changed.isEmpty && animated.isEmpty) {
    return (moved: 0, toBar: 0, toOff: 0);
  }
  // (c) Only checkers that changed slot may have animated.
  expect(
    animated.difference(changed),
    isEmpty,
    reason:
        'existing checkers animated: ${animated.difference(changed)} '
        'phase ${g.controller.state.phase} '
        '${[for (final id in animated.difference(changed)) '${b[id]} -> ${after.firstWhere((c) => c.id == id)}']}',
  );
  final count = <Slot, int>{};
  for (final c in after) {
    count[c.slot] = (count[c.slot] ?? 0) + 1;
  }
  final arrivals = <Slot, int>{};
  for (final id in changed) {
    final s = after.firstWhere((c) => c.id == id).slot;
    arrivals[s] = (arrivals[s] ?? 0) + 1;
  }
  final paint = g.debugPaintOrder();
  var toBar = 0;
  var toOff = 0;
  for (final c in after) {
    final was = b[c.id]!;
    if (!changed.contains(c.id)) {
      // (a) Non-moved checkers keep their stack index (and position, unless
      // a tall stack or the bar compressed).
      if (was.slot == c.slot) {
        expect(c.index, was.index, reason: 'checker ${c.id} re-ordered');
        final compressible = c.slot is BarSlot || (count[c.slot] ?? 0) > 5;
        if (!compressible) {
          expect(
            (c.pos - was.pos).distance,
            lessThan(0.6),
            reason: 'checker ${c.id} moved on its stack',
          );
        }
      }
    } else {
      // (b) Arrivals sit at the top of their stack and paint above it.
      final n = count[c.slot]!;
      expect(
        c.index,
        greaterThanOrEqualTo(n - arrivals[c.slot]!),
        reason: 'arrival ${c.id} not on top of ${c.slot}',
      );
      final onSlot = [
        for (final p in paint)
          if (p.slot == c.slot) p.index,
      ];
      expect(onSlot, [for (var i = 0; i < onSlot.length; i++) i]);
      if (c.slot is BarSlot) toBar++;
      if (c.slot is OffSlot) toOff++;
    }
  }
  return (moved: changed.length, toBar: toBar, toOff: toOff);
}
