import 'dart:async';
import 'dart:collection';

import 'package:flutter/foundation.dart';
import 'package:haftnard/core/rules/actions.dart';
import 'package:haftnard/core/rules/engine.dart';
import 'package:haftnard/core/rules/record.dart';
import 'package:haftnard/core/rules/state.dart';
import 'package:haftnard/core/rules/types.dart';
import 'package:haftnard/net/lan/channel.dart';
import 'package:haftnard/net/remote_opponent.dart';

/// Wire protocol version; peers with another version refuse to play.
const int kLanProtocol = 1;

enum LanStatus { connecting, connected, lost, left, desync }

/// What the link needs from the match it plays (implemented by
/// MatchController; kept as an interface so the link is testable alone).
abstract interface class LanMatchHost {
  /// Finished games so far (the current game's number).
  int get gameNumber;

  /// Every action of the current game so far.
  List<GameAction> get gameLog;

  /// The current game's configuration (to replay its log).
  GameConfig get gameConfig;

  /// Applies a resignation coming from the peer.
  Future<void> remoteResign(Side side);

  /// Replaces the current game's log (desync recovery; host's log wins).
  Future<void> adoptLog(List<GameAction> log);
}

/// One device's end of a LAN game.
///
/// Both devices run the same deterministic engine from the same seed, so
/// only actions travel. The local player's actions are sent in committed
/// batches: moves stay local (and undoable) until the next non-move action
/// (Done, a roll, a card pick…), then go out together with the hash of the
/// state they reached. The receiver re-checks the hash before playing them;
/// on a mismatch the host's log wins.
class LanLink implements RemoteTransport {
  LanLink({
    required this.localSide,
    required this.matchId,
    required this.isHost,
    this.pingEvery = const Duration(seconds: 2),
    this.timeout = const Duration(seconds: 7),
  });

  final Side localSide;
  final String matchId;
  final bool isHost;
  final Duration pingEvery;
  final Duration timeout;

  Side get remoteSide => localSide.opponent;

  final ValueNotifier<LanStatus> status = ValueNotifier(LanStatus.connecting);

  /// Emotes the peer sent (item ids).
  final StreamController<String> _emotes = StreamController.broadcast();
  Stream<String> get emotes => _emotes.stream;

  LanMatchHost? _host;
  LanChannel? _channel;
  StreamSubscription<Map<String, Object?>>? _sub;
  Timer? _ping;

  /// Ping intervals since the peer last said anything.
  int _silentTicks = 0;
  bool _disposed = false;

  final Queue<_Batch> _batches = Queue();
  Completer<void>? _arrived;

  /// Local moves not sent yet (still undoable).
  final List<GameAction> _pending = [];

  /// Counters for tests and the debug overlay.
  int sentBatches = 0;
  int receivedBatches = 0;
  int resent = 0;
  int desyncs = 0;

  // A method, not a setter: binding happens once, from the controller.
  // ignore: use_setters_to_change_properties
  void bind(LanMatchHost host) => _host = host;

  /// Starts using [channel] (first connection or a reconnect).
  void attach(LanChannel channel) {
    unawaited(_sub?.cancel());
    _channel = channel;
    _silentTicks = 0;
    _sub = channel.messages.listen(_onMessage, onDone: _onClosed);
    _ping?.cancel();
    _ping = Timer.periodic(pingEvery, (_) => _tick());
    status.value = LanStatus.connected;
    final h = _host;
    _send({
      't': 'hello',
      'v': kLanProtocol,
      'id': matchId,
      'g': h?.gameNumber ?? 0,
      'have': (h?.gameLog.length ?? 0) - _pending.length,
    });
  }

  void _send(Map<String, Object?> m) => _channel?.send(m);

  void _tick() {
    if (_disposed) return;
    _silentTicks++;
    if (pingEvery * _silentTicks > timeout &&
        status.value == LanStatus.connected) {
      _lost();
      return;
    }
    _send(const {'t': 'ping'});
  }

  void _onClosed() {
    if (_disposed) return;
    if (status.value == LanStatus.connected) _lost();
  }

  void _lost() {
    status.value = LanStatus.lost;
    _ping?.cancel();
    final ch = _channel;
    _channel = null;
    unawaited(ch?.close());
  }

  // ---------------------------------------------------------------- local

  /// The local player applied [a] in game [game], reaching
  /// [after]. Moves wait; anything else sends the batch.
  void localAction(GameAction a, GameState after, {required int game}) {
    if (a is Resign) return localResign(a.side, game: game);
    _pending.add(a);
    final commit =
        a is! PlayMove || after.isOver || Engine.actor(after) != localSide;
    if (!commit) return;
    final h = _host;
    final log = h?.gameLog ?? const <GameAction>[];
    final batch = List<GameAction>.of(_pending);
    _pending.clear();
    sentBatches++;
    _send({
      't': 'acts',
      'g': game,
      // Index of the first action in the game log (the host reports local
      // actions before a finished game is archived, so the log holds them).
      'at': log.length - batch.length,
      'a': [for (final x in batch) x.toJson()],
      'h': stateHash(after),
    });
  }

  /// The local player took back their last move.
  void localUndo() {
    if (_pending.isNotEmpty) _pending.removeLast();
  }

  void localResign(Side side, {required int game}) {
    _pending.clear();
    _send({'t': 'resign', 's': side.name, 'g': game});
  }

  void sendEmote(String itemId) => _send({'t': 'emote', 'id': itemId});

  /// Leaving the game on purpose (the peer counts it as a resignation).
  void leave() {
    _send(const {'t': 'bye'});
  }

  // --------------------------------------------------------------- remote

  @override
  Future<List<GameAction>> nextActions(GameState state) async {
    while (!_disposed) {
      final h = _host;
      final game = h?.gameNumber ?? 0;
      final have = h?.gameLog.length ?? 0;
      // Drop what belongs to finished games or is already applied (a resend
      // after a reconnect overlaps).
      while (_batches.isNotEmpty) {
        final b = _batches.first;
        if (b.game < game || (b.at >= 0 && b.at + b.actions.length <= have)) {
          _batches.removeFirst();
          continue;
        }
        break;
      }
      if (_batches.isNotEmpty && _batches.first.game == game) {
        final b = _batches.removeFirst();
        final skip = b.at >= 0 && b.at < have ? have - b.at : 0;
        final actions = b.actions.sublist(skip);
        final reached = _tryApply(state, actions);
        if (reached != null && stateHash(reached) == b.hash) {
          receivedBatches++;
          return actions;
        }
        _desync();
        return const [];
      }
      final c = _arrived = Completer<void>();
      await c.future;
    }
    return const [];
  }

  GameState? _tryApply(GameState s, List<GameAction> actions) {
    try {
      return Engine.applyAll(s, actions);
    } on IllegalActionException {
      return null;
    }
  }

  void _desync() {
    desyncs++;
    status.value = LanStatus.desync;
    final h = _host;
    if (h == null) return;
    if (isHost) {
      // Committed actions only: local moves still pending may be undone.
      final committed = h.gameLog.length - _pending.length;
      _send({
        't': 'log',
        'g': h.gameNumber,
        'a': [for (final x in h.gameLog.take(committed)) x.toJson()],
      });
      status.value = LanStatus.connected;
    } else {
      _send({'t': 'need', 'g': h.gameNumber});
    }
  }

  @override
  Future<void> submit(
    List<GameAction> actions, {
    required int stateHash,
  }) async {
    // LAN sends through [localAction]; kept for the server seam.
  }

  void _wake() {
    final c = _arrived;
    _arrived = null;
    if (c != null && !c.isCompleted) c.complete();
  }

  void _onMessage(Map<String, Object?> m) {
    _silentTicks = 0;
    switch (m['t']) {
      case 'ping':
        _send(const {'t': 'pong'});
      case 'hello':
        if (m['v'] != kLanProtocol || m['id'] != matchId) {
          status.value = LanStatus.left;
          return;
        }
        _catchUp(m['g']! as int, m['have']! as int);
      case 'acts':
        _batches.add(
          _Batch(
            game: m['g']! as int,
            at: m['at']! as int,
            actions: [
              for (final a in m['a']! as List<Object?>)
                GameAction.fromJson((a! as Map).cast<String, Object?>()),
            ],
            hash: m['h']! as int,
          ),
        );
        _wake();
      case 'resign':
        final side = Side.values.byName(m['s']! as String);
        if (m['g'] == _host?.gameNumber) {
          unawaited(_host?.remoteResign(side));
        }
      case 'emote':
        _emotes.add(m['id']! as String);
      case 'bye':
        status.value = LanStatus.left;
        unawaited(_host?.remoteResign(remoteSide));
      case 'need':
        if (isHost) _desync();
      case 'log':
        final h = _host;
        if (h != null && m['g'] == h.gameNumber) {
          // Queued batches stay: those the log covers are skipped by index.
          _pending.clear();
          unawaited(
            h.adoptLog([
              for (final a in m['a']! as List<Object?>)
                GameAction.fromJson((a! as Map).cast<String, Object?>()),
            ]),
          );
          status.value = LanStatus.connected;
        }
    }
  }

  /// After a reconnect: resend what the peer missed of our committed moves.
  void _catchUp(int peerGame, int peerHave) {
    final h = _host;
    if (h == null || peerGame != h.gameNumber) return;
    final committed = h.gameLog.length - _pending.length;
    if (peerHave >= committed) return;
    final tail = h.gameLog.sublist(peerHave, committed);
    final reached = GameRecord(
      h.gameConfig,
      h.gameLog.sublist(0, committed),
    ).replay();
    resent++;
    _send({
      't': 'acts',
      'g': h.gameNumber,
      'at': peerHave,
      'a': [for (final x in tail) x.toJson()],
      'h': stateHash(reached),
    });
  }

  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    _ping?.cancel();
    _wake();
    await _sub?.cancel();
    await _channel?.close();
    // Not awaited: nothing must wait on listeners finishing.
    unawaited(_emotes.close());
    status.dispose();
  }
}

class _Batch {
  _Batch({
    required this.game,
    required this.at,
    required this.actions,
    required this.hash,
  });
  final int game;
  final int at;
  final List<GameAction> actions;
  final int hash;
}
