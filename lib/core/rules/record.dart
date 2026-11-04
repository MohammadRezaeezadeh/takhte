import 'dart:convert';

import 'package:haftnard/core/rules/actions.dart';
import 'package:haftnard/core/rules/engine.dart';
import 'package:haftnard/core/rules/state.dart';
import 'package:haftnard/core/rules/types.dart';

/// A replayable game: configuration (including the seed) plus every action.
class GameRecord {
  GameRecord(this.config, [List<GameAction>? actions])
    : actions = actions ?? [];

  factory GameRecord.fromJson(Map<String, Object?> j) => GameRecord(
    GameConfig.fromJson((j['config']! as Map).cast<String, Object?>()),
    [
      for (final a in j['actions']! as List<Object?>)
        GameAction.fromJson((a! as Map).cast<String, Object?>()),
    ],
  );

  static const int formatVersion = 1;

  final GameConfig config;
  final List<GameAction> actions;

  GameState get initial => GameState.initial(config);

  /// Replays every action from the initial state.
  GameState replay() => Engine.applyAll(initial, actions);

  /// Replays and returns every intermediate state (index 0 = initial).
  List<GameState> replayStates() {
    final out = [initial];
    for (final a in actions) {
      out.add(Engine.apply(out.last, a).state);
    }
    return out;
  }

  /// `(turnNumber, stateHash)` at the end of every turn, for desync checks:
  /// a client submits the hash it reached; the server compares.
  List<(int, int)> turnChecksums() {
    final out = <(int, int)>[];
    var s = initial;
    for (final a in actions) {
      final next = Engine.apply(s, a).state;
      if (next.turnNumber != s.turnNumber || next.isOver) {
        out.add((s.turnNumber, stateHash(next)));
      }
      s = next;
    }
    return out;
  }

  Map<String, Object?> toJson() => {
    'v': formatVersion,
    'config': config.toJson(),
    'actions': [for (final a in actions) a.toJson()],
  };
}

/// [state] as [viewer] may see it: the opponent's hidden traps are removed.
/// Servers must send this (not the raw state) to each remote client.
GameState redactedFor(GameState state, Side viewer) => state.copyWith(
  effects: [
    for (final e in state.effects)
      if (!(e.kind == EffectKind.landmine && e.owner != viewer)) e,
  ],
);

/// 32-bit FNV-1a hash of the canonical JSON of [state]. Used as a per-turn
/// checksum so a server and clients can detect desyncs cheaply.
int stateHash(GameState state) {
  final bytes = utf8.encode(jsonEncode(state.toJson()));
  var h = 0x811C9DC5;
  for (final b in bytes) {
    h ^= b;
    h = (h * 0x01000193) & 0xFFFFFFFF;
  }
  return h;
}
