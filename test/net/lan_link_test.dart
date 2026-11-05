// Two devices playing a LAN match: both run the same engine, only committed
// action batches travel, and both end every turn on the same state hash —
// with undos, forced moves, 7–7 card picks, a dropped connection with
// catch-up on reconnect, and a resignation.
import 'dart:async';
import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:haftnard/core/ai/ai.dart';
import 'package:haftnard/core/ai/personality.dart';
import 'package:haftnard/core/rules/actions.dart';
import 'package:haftnard/core/rules/match.dart';
import 'package:haftnard/core/rules/record.dart';
import 'package:haftnard/core/rules/types.dart';
import 'package:haftnard/game/match_controller.dart';
import 'package:haftnard/net/lan/channel.dart';
import 'package:haftnard/net/lan/lan_link.dart';

class _Device {
  _Device(MatchConfig cfg, {required this.side, required this.link})
    : ctrl = MatchController(
        MatchSession(
          match: MatchState(cfg),
          white: side == Side.white
              ? const SeatConfig.human('Host')
              : const SeatConfig.remote('Host'),
          black: side == Side.black
              ? const SeatConfig.human('Guest')
              : const SeatConfig.remote('Guest'),
          origin: 'lan',
        ),
        pacing: Duration.zero,
        useIsolates: false,
        lan: link,
      );

  final Side side;
  final LanLink link;
  final MatchController ctrl;
}

(_Device, _Device, MemoryChannel, MemoryChannel) _pair(MatchConfig cfg) {
  final host = _Device(
    cfg,
    side: Side.white,
    link: LanLink(localSide: Side.white, matchId: 'm1', isHost: true),
  );
  final guest = _Device(
    cfg,
    side: Side.black,
    link: LanLink(localSide: Side.black, matchId: 'm1', isHost: false),
  );
  final (a, b) = MemoryChannel.pair();
  host.link.attach(a);
  guest.link.attach(b);
  return (host, guest, a, b);
}

/// Plays both seats with an easy AI brain (and random undos) until the
/// match ends or [until] says stop.
Future<int> _play(
  _Device host,
  _Device guest, {
  required math.Random rng,
  bool Function(int step)? until,
  void Function(int step)? onStep,
}) async {
  final brain = AiBrain(const AiConfig(difficulty: Difficulty.easy));
  var steps = 0;
  var idle = 0;
  while (!host.ctrl.match.isOver || !guest.ctrl.match.isOver) {
    steps++;
    if (until?.call(steps) ?? false) break;
    onStep?.call(steps);
    var acted = false;
    for (final d in [host, guest]) {
      final c = d.ctrl;
      if (c.state.isOver && !c.match.isOver) {
        // Next game once both devices finished this one.
        // Each device moves on by itself (the player taps "next game").
        unawaited(c.nextGame());
        acted = true;
        continue;
      }
      if (!c.waitingForHuman) continue;
      if (c.canUndo && rng.nextDouble() < 0.2) {
        c.undo();
      } else {
        final a = brain.decide(c.state).first;
        unawaited(c.act(a));
      }
      acted = true;
    }
    await pumpEventQueue(times: 3);
    idle = acted ? 0 : idle + 1;
    if (idle > 400) {
      fail(
        'stalled at step $steps: host ${host.ctrl.state.phase} '
        'log ${host.ctrl.gameLog.length} ${host.link.status.value} '
        'wait ${host.ctrl.waitingForHuman}; guest ${guest.ctrl.state.phase} '
        'log ${guest.ctrl.gameLog.length} ${guest.link.status.value} '
        'wait ${guest.ctrl.waitingForHuman} desync ${guest.link.desyncs} '
        'busy ${guest.ctrl.busy} ${host.ctrl.busy}\n'
        'H ${[for (final x in host.ctrl.gameLog) x.toJson()]}\n'
        'G ${[for (final x in guest.ctrl.gameLog) x.toJson()]}',
      );
    }
    if (steps > 60000) fail('runaway');
  }
  return steps;
}

void main() {
  test('a 3-point Seven match plays identically on both devices', () async {
    const cfg = MatchConfig(length: 3, seed: 4242, p7: 0.25);
    final (host, guest, _, _) = _pair(cfg);
    unawaited(host.ctrl.begin());
    unawaited(guest.ctrl.begin());
    final hashes = <int, int>{};
    await _play(
      host,
      guest,
      rng: math.Random(1),
      onStep: (_) {
        // Whenever both devices have played the same actions, they hold the
        // same state (applied step by step on each device).
        final h = host.ctrl;
        final g = guest.ctrl;
        if (h.gameNumber == g.gameNumber &&
            h.gameLog.length == g.gameLog.length &&
            !h.busy &&
            !g.busy &&
            !h.state.isOver &&
            !g.state.isOver &&
            '${[for (final x in h.gameLog) x.toJson()]}' ==
                '${[for (final x in g.gameLog) x.toJson()]}') {
          final hh = stateHash(h.state);
          expect(stateHash(g.state), hh);
          hashes[h.gameLog.length] = hh;
        }
      },
    );
    expect(host.ctrl.match.isOver, isTrue);
    expect(guest.ctrl.match.results.map((r) => r.toJson()).toList(), [
      for (final r in host.ctrl.match.results) r.toJson(),
    ]);
    expect(hashes.length, greaterThan(50));
    expect(host.link.sentBatches, greaterThan(20));
    expect(guest.link.receivedBatches, host.link.sentBatches);
    for (final d in [host, guest]) {
      d.ctrl.dispose();
      await d.link.dispose();
    }
  });

  test('a dropped connection catches up on reconnect', () async {
    const cfg = MatchConfig(seed: 77, p7: 0.1);
    final (host, guest, a, b) = _pair(cfg);
    unawaited(host.ctrl.begin());
    unawaited(guest.ctrl.begin());
    final rng = math.Random(3);
    // Play a while, then cut the wire for a stretch.
    await _play(host, guest, rng: rng, until: (s) => s > 60);
    a.connected = false;
    b.connected = false;
    await _play(host, guest, rng: rng, until: (s) => s > 40);
    // The side that kept playing is ahead; reconnect on a fresh pipe.
    expect(
      host.ctrl.gameLog.length != guest.ctrl.gameLog.length ||
          host.ctrl.state.phase != guest.ctrl.state.phase,
      isTrue,
      reason: 'the cut should have left the devices apart',
    );
    final (a2, b2) = MemoryChannel.pair();
    host.link.attach(a2);
    guest.link.attach(b2);
    await _play(host, guest, rng: rng);
    expect(host.link.resent + guest.link.resent, greaterThan(0));
    expect(guest.ctrl.match.results.single.toJson(), {
      ...host.ctrl.match.results.single.toJson(),
    });
    for (final d in [host, guest]) {
      d.ctrl.dispose();
      await d.link.dispose();
    }
  });

  test('resigning and leaving end the game on the other device', () async {
    const cfg = MatchConfig(seed: 5, p7: 0);
    final (host, guest, _, _) = _pair(cfg);
    unawaited(host.ctrl.begin());
    unawaited(guest.ctrl.begin());
    await _play(host, guest, rng: math.Random(9), until: (s) => s > 30);
    await host.ctrl.resign(Side.white);
    await pumpEventQueue();
    expect(guest.ctrl.state.isOver, isTrue);
    expect(guest.ctrl.state.result!.winner, Side.black);

    final (h2, g2, _, _) = _pair(cfg);
    unawaited(h2.ctrl.begin());
    unawaited(g2.ctrl.begin());
    await _play(h2, g2, rng: math.Random(2), until: (s) => s > 20);
    g2.link.leave();
    await pumpEventQueue();
    expect(h2.link.status.value, LanStatus.left);
    expect(h2.ctrl.state.result!.winner, Side.white);
    for (final d in [host, guest, h2, g2]) {
      d.ctrl.dispose();
      await d.link.dispose();
    }
  });

  test(
    "a batch that misses the sender's hash is replaced by the host's log",
    () async {
      const cfg = MatchConfig(seed: 31, p7: 0);
      final (host, guest, a, _) = _pair(cfg);
      // A corrupted batch reaches the guest before anything else.
      a.send({
        't': 'acts',
        'g': 0,
        'at': 0,
        'a': [const RollOpening().toJson()],
        'h': 12345,
      });
      unawaited(host.ctrl.begin());
      unawaited(guest.ctrl.begin());
      await _play(host, guest, rng: math.Random(4));
      expect(guest.link.desyncs, 1);
      expect(guest.link.status.value, LanStatus.connected);
      expect(guest.ctrl.match.results.single.toJson(), {
        ...host.ctrl.match.results.single.toJson(),
      });
      for (final d in [host, guest]) {
        d.ctrl.dispose();
        await d.link.dispose();
      }
    },
  );
}
