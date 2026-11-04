import 'package:haftnard/core/ai/ai.dart';
import 'package:haftnard/core/rules/actions.dart';
import 'package:haftnard/core/rules/state.dart';

/// Who controls a side. Game flow talks only to this interface, so AI, local
/// humans and (future) remote players are interchangeable.
abstract interface class Opponent {
  /// Local humans act through the UI; [decide] is never called for them.
  bool get isLocalHuman;

  /// Actions for the current decision point (see [AiBrain.decide]).
  Future<List<GameAction>> decide(GameState state);
}

class LocalHumanOpponent implements Opponent {
  const LocalHumanOpponent();
  @override
  bool get isLocalHuman => true;
  @override
  Future<List<GameAction>> decide(GameState state) =>
      throw UnsupportedError('Local humans act through the UI');
}

class AiOpponent implements Opponent {
  AiOpponent(this.config, {this.useIsolate = true});
  final AiConfig config;

  /// Tests and the simulator run synchronously.
  final bool useIsolate;

  @override
  bool get isLocalHuman => false;

  @override
  Future<List<GameAction>> decide(GameState state) => useIsolate
      ? AiBrain.decideAsync(state, config)
      : Future.value(AiBrain(config).decide(state));
}
