import 'package:haftnard/core/opponent.dart';
import 'package:haftnard/core/rules/actions.dart';
import 'package:haftnard/core/rules/state.dart';

/// Placeholder for online play. A future implementation will send the local
/// player's actions to an authoritative server and receive the remote
/// player's actions from it; see docs/ONLINE_PLAN.md.
class RemoteOpponent implements Opponent {
  RemoteOpponent(this.transport);

  final RemoteTransport transport;

  @override
  bool get isLocalHuman => false;

  @override
  Future<List<GameAction>> decide(GameState state) =>
      transport.nextActions(turn: state.turnNumber);
}

/// Network seam (not implemented in v1).
abstract interface class RemoteTransport {
  Future<List<GameAction>> nextActions({required int turn});
  Future<void> submit(List<GameAction> actions, {required int stateHash});
}
