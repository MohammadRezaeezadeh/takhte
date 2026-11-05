// The LAN lobby over real TCP sockets on loopback: probing finds the game,
// joining delivers the match config, other versions and a third device are
// refused, and the joined guest can reconnect into the same match.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:haftnard/core/rules/match.dart';
import 'package:haftnard/core/rules/state.dart';
import 'package:haftnard/net/lan/channel.dart';
import 'package:haftnard/net/lan/lan_lobby.dart';

void main() {
  test('probe, join, refuse, reconnect', () async {
    final host = LanHost(
      hostName: 'Sara',
      config: const MatchConfig(mode: GameMode.classic, length: 3, seed: 9),
      beacon: false,
    );
    await host.start(bindTo: InternetAddress.loopbackIPv4);
    final port = host.port;

    final info = await probeHost('127.0.0.1', port: port);
    expect(info, isNotNull);
    expect(info!.hostName, 'Sara');
    expect(info.mode, 'classic');
    expect(info.length, 3);

    // Nothing listens on the next port: no game there.
    expect(await probeHost('127.0.0.1', port: port + 1), isNull);

    final welcome = await joinHost('127.0.0.1', port: port, name: 'Ali');
    final (hostCh, guestName) = await host.guest;
    expect(guestName, 'Ali');
    expect(welcome.hostName, 'Sara');
    expect(welcome.matchId, host.matchId);
    expect(welcome.config!.seed, 9);
    expect(welcome.config!.mode, GameMode.classic);

    // Messages flow both ways after the handshake.
    final got = hostCh.messages.first;
    welcome.channel.send({'t': 'ping', 'n': 1});
    expect((await got)['n'], 1);
    final back = welcome.channel.messages.first;
    hostCh.send({'t': 'pong', 'n': 2});
    expect((await back)['n'], 2);

    // A third device can't take the seat.
    await expectLater(
      joinHost('127.0.0.1', port: port, name: 'Reza'),
      throwsA(
        isA<LanJoinException>().having((e) => e.reason, 'reason', 'full'),
      ),
    );

    // The guest drops and rejoins the same match.
    final re = host.reconnects.first;
    await welcome.channel.close();
    final again = await joinHost(
      '127.0.0.1',
      port: port,
      name: 'Ali',
      matchId: host.matchId,
    );
    final hostCh2 = await re;
    expect(again.config, isNull, reason: 'a rejoin keeps its match');
    final got2 = hostCh2.messages.first;
    again.channel.send({'t': 'ping', 'n': 3});
    expect((await got2)['n'], 3);

    await again.channel.close();
    await hostCh.close();
    await host.stop();
  });

  test('another protocol version is refused', () async {
    final host = LanHost(
      hostName: 'H',
      config: const MatchConfig(seed: 2),
      beacon: false,
    );
    await host.start(bindTo: InternetAddress.loopbackIPv4);
    final s = await Socket.connect('127.0.0.1', host.port);
    final ch = SocketChannel(s)..send({'t': 'join', 'v': 999, 'name': 'X'});
    final m = await ch.first(timeout: const Duration(seconds: 3));
    expect(m, {'t': 'refuse', 'why': 'version'});
    await ch.close();
    await host.stop();
  });

  test('an unreachable host fails fast with a reason', () async {
    final free = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
    final port = free.port;
    await free.close();
    await expectLater(
      joinHost('127.0.0.1', port: port, name: 'A'),
      throwsA(
        isA<LanJoinException>().having(
          (e) => e.reason,
          'reason',
          'unreachable',
        ),
      ),
    );
  });
}
