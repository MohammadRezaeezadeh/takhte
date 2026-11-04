import 'dart:convert';

import 'package:haftnard/core/rng/rng.dart';
import 'package:haftnard/core/rules/actions.dart';
import 'package:haftnard/core/rules/engine.dart';
import 'package:haftnard/core/rules/record.dart';
import 'package:haftnard/core/rules/state.dart';
import 'package:haftnard/core/rules/types.dart';
import 'package:test/test.dart';

/// Plays a full game choosing uniformly random legal actions.
GameRecord randomGame(GameConfig cfg, int pickSeed, {int maxSteps = 6000}) {
  final rec = GameRecord(cfg);
  final pick = Rng.seeded(pickSeed);
  var s = rec.initial;
  var steps = 0;
  while (!s.isOver && steps < maxSteps) {
    final actions = Engine.legalActions(s);
    expect(actions, isNotEmpty, reason: 'stuck in ${s.phase}');
    // Prefer real moves over alterations so games finish.
    final moves = actions.whereType<PlayMove>().toList();
    final GameAction a;
    if (moves.isNotEmpty && pick.nextInt(10) < 8) {
      a = moves[pick.nextInt(moves.length)];
    } else {
      a = actions[pick.nextInt(actions.length)];
    }
    // Never drop doubles in fuzzing most of the time, to keep games long.
    final chosen = a is DropDouble && pick.nextInt(4) != 0
        ? const TakeDouble()
        : a;
    s = Engine.apply(s, chosen).state;
    rec.actions.add(chosen);
    final err = s.board.validate();
    expect(err, isNull, reason: 'invalid board after $chosen: $err');
    steps++;
  }
  return rec;
}

void main() {
  test('random classic games always finish with valid states', () {
    for (var g = 0; g < 40; g++) {
      final rec = randomGame(GameConfig(mode: GameMode.classic, seed: g), g);
      final end = rec.replay();
      expect(end.isOver, isTrue, reason: 'game $g did not finish');
      expect(end.board.borneOff(end.result!.winner), anyOf(15, lessThan(15)));
    }
  });

  test('random seven-mode games with frequent 7-7 stay valid', () {
    for (var g = 0; g < 60; g++) {
      final cfg = GameConfig(seed: 1000 + g, p7: 0.35, cubeEnabled: g.isEven);
      final rec = randomGame(cfg, g);
      final end = rec.replay();
      expect(end.isOver, isTrue, reason: 'game $g did not finish');
    }
  });

  test('replay is deterministic and state JSON round-trips', () {
    const cfg = GameConfig(seed: 77, p7: 0.3);
    final rec = randomGame(cfg, 5);
    final states = rec.replayStates();
    for (final s in states) {
      final json = jsonEncode(s.toJson());
      final back = GameState.fromJson(
        (jsonDecode(json) as Map).cast<String, Object?>(),
      );
      expect(jsonEncode(back.toJson()), json);
    }
    // Record JSON round-trip.
    final rec2 = GameRecord.fromJson(
      (jsonDecode(jsonEncode(rec.toJson())) as Map).cast<String, Object?>(),
    );
    expect(stateHash(rec2.replay()), stateHash(rec.replay()));
    expect(rec2.actions.length, rec.actions.length);
  });

  test('restored mid-game state continues identically', () {
    final rec = randomGame(const GameConfig(seed: 3, p7: 0.3), 9);
    final half = rec.actions.length ~/ 2;
    var s = Engine.applyAll(rec.initial, rec.actions.take(half));
    s = GameState.fromJson(
      (jsonDecode(jsonEncode(s.toJson())) as Map).cast<String, Object?>(),
    );
    s = Engine.applyAll(s, rec.actions.skip(half));
    expect(stateHash(s), stateHash(rec.replay()));
  });

  test('checker conservation holds in every state', () {
    final rec = randomGame(const GameConfig(seed: 11, p7: 0.4), 2);
    for (final s in rec.replayStates()) {
      for (final side in Side.values) {
        final total = s.board.of(side).fold<int>(0, (a, b) => a + b);
        expect(total, 15);
      }
    }
  });

  test(
    'per-turn checksums are reproducible and redaction hides enemy mines',
    () {
      final rec = randomGame(const GameConfig(seed: 31, p7: 0.4), 4);
      final a = rec.turnChecksums();
      final b = GameRecord.fromJson(
        (jsonDecode(jsonEncode(rec.toJson())) as Map).cast<String, Object?>(),
      ).turnChecksums();
      expect(a, isNotEmpty);
      expect(a, b);
      for (final s in rec.replayStates()) {
        for (final viewer in Side.values) {
          final r = redactedFor(s, viewer);
          expect(
            r.effects.any(
              (e) => e.kind == EffectKind.landmine && e.owner != viewer,
            ),
            isFalse,
          );
        }
      }
    },
  );
}
