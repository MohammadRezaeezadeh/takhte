import 'package:haftnard/core/opponent.dart';
import 'package:haftnard/core/rules/actions.dart';
import 'package:haftnard/core/rules/state.dart';

/// A player on another device. Their actions arrive through a
/// [RemoteTransport]: today the LAN link (lib/net/lan), later perhaps an
/// authoritative server (docs/ONLINE_PLAN.md).
class RemoteOpponent implements Opponent {
  RemoteOpponent(this.transport);

  final RemoteTransport transport;

  @override
  bool get isLocalHuman => false;

  @override
  Future<List<GameAction>> decide(GameState state) =>
      transport.nextActions(state);
}

/// Network seam.
abstract interface class RemoteTransport {
  /// The remote player's next actions from [state] (waits for them).
  Future<List<GameAction>> nextActions(GameState state);
  Future<void> submit(List<GameAction> actions, {required int stateHash});
}
