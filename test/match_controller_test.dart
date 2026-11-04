import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:haftnard/core/ai/personality.dart';
import 'package:haftnard/core/rules/actions.dart';
import 'package:haftnard/core/rules/engine.dart';
import 'package:haftnard/core/rules/match.dart';
import 'package:haftnard/core/rules/state.dart';
import 'package:haftnard/game/match_controller.dart';

MatchSession aiSession({int length = 1, int seed = 5}) => MatchSession(
  match: MatchState(MatchConfig(length: length, seed: seed, p7: 0.2)),
  white: const SeatConfig.ai(
    personalityId: 'sage',
    difficulty: Difficulty.easy,
  ),
  black: const SeatConfig.ai(
    personalityId: 'hammer',
    difficulty: Difficulty.easy,
  ),
);

void main() {
  test('AI vs AI match runs to completion through the controller', () async {
    var finished = 0;
    final c = MatchController(
      aiSession(length: 3),
      pacing: Duration.zero,
      useIsolates: false,
      onGameFinished: (_, _, _) => finished++,
    );
    await c.begin();
    while (!c.match.isOver) {
      expect(c.state.isOver, isTrue);
      await c.nextGame();
    }
    expect(finished, greaterThanOrEqualTo(2));
    expect(c.match.winner, isNotNull);
  });

  test('human moves, undo and done', () async {
    final session = MatchSession(
      match: MatchState(const MatchConfig(mode: GameMode.classic, seed: 3)),
      white: const SeatConfig.human('A'),
      black: const SeatConfig.human('B'),
    );
    final c = MatchController(
      session,
      pacing: Duration.zero,
      useIsolates: false,
      autoMove: false,
    );
    await c.begin();
    expect(c.waitingForHuman, isTrue);
    expect(await c.act(const RollOpening()), isTrue);
    while (c.state.phase == Phase.opening) {
      await c.act(const RollOpening());
    }
    expect(c.state.phase, Phase.moving);
    final before = c.state.board;
    final m = Engine.legalMoves(c.state).first;
    expect(await c.act(PlayMove(m)), isTrue);
    expect(c.canUndo, isTrue);
    c.undo();
    expect(c.state.board, before);
    expect(c.match.current.actions.whereType<PlayMove>(), isEmpty);
    // Illegal actions are rejected.
    expect(await c.act(const EndTurn()), isFalse);
  });

  test('session JSON resumes to the identical state', () async {
    final c = MatchController(
      aiSession(),
      pacing: Duration.zero,
      useIsolates: false,
    );
    await c.begin();
    final json = jsonEncode(c.session.toJson());
    final restored = MatchSession.fromJson(
      (jsonDecode(json) as Map).cast<String, Object?>(),
    );
    final c2 = MatchController(restored, useIsolates: false);
    expect(jsonEncode(c2.state.toJson()), jsonEncode(c.state.toJson()));
  });
}
