import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:haftnard/core/rules/match.dart';
import 'package:haftnard/net/lan/channel.dart';
import 'package:haftnard/net/lan/lan_link.dart';
import 'package:meta/meta.dart';

/// TCP port the host listens on (falls back to any free port if taken).
const int kLanPort = 47470;

/// UDP port for the host's "a game is open here" beacon.
const int kLanBeaconPort = 47471;

const String _beaconTag = 'HAFTNARD';

/// An open game found on the local network.
@immutable
class LanGameInfo {
  const LanGameInfo({
    required this.hostName,
    required this.address,
    required this.port,
    required this.mode,
    required this.length,
  });

  final String hostName;
  final String address;
  final int port;
  final String mode;
  final int length;

  Map<String, Object?> toJson() => {
    'host': hostName,
    'port': port,
    'mode': mode,
    'len': length,
  };

  static LanGameInfo? fromJson(Map<String, Object?> j, String address) {
    try {
      return LanGameInfo(
        hostName: j['host']! as String,
        address: address,
        port: j['port']! as int,
        mode: j['mode']! as String,
        length: j['len']! as int,
      );
    } on Object {
      return null;
    }
  }

  @override
  bool operator ==(Object other) =>
      other is LanGameInfo && other.address == address && other.port == port;

  @override
  int get hashCode => Object.hash(address, port);
}

/// This device's IPv4 addresses on Wi-Fi / hotspot interfaces.
Future<List<String>> localAddresses() async {
  try {
    final ifs = await NetworkInterface.list(type: InternetAddressType.IPv4);
    return [
      for (final i in ifs)
        for (final a in i.addresses)
          if (!a.isLoopback && !a.isLinkLocal) a.address,
    ];
  } on Object {
    return const [];
  }
}

String newMatchId() {
  final r = math.Random();
  return List.generate(8, (_) => r.nextInt(36).toRadixString(36)).join();
}

/// Hosting a game: listens for a guest, announces itself, and keeps
/// listening during the match so a dropped guest can reconnect.
class LanHost {
  LanHost({
    required this.hostName,
    required this.config,
    String? matchId,
    this.beacon = true,
  }) : matchId = matchId ?? newMatchId();

  final String hostName;
  final MatchConfig config;
  final String matchId;
  final bool beacon;

  ServerSocket? _server;
  RawDatagramSocket? _udp;
  Timer? _beaconTimer;
  StreamSubscription<Socket>? _accept;

  final Completer<(SocketChannel, String)> _guest = Completer();

  /// Reconnects of the joined guest (each a fresh channel).
  final StreamController<SocketChannel> _reconnects =
      StreamController.broadcast();

  int get port => _server?.port ?? 0;

  /// Completes with the first guest (channel and name).
  Future<(SocketChannel, String)> get guest => _guest.future;
  Stream<SocketChannel> get reconnects => _reconnects.stream;

  Future<void> start({InternetAddress? bindTo}) async {
    final addr = bindTo ?? InternetAddress.anyIPv4;
    try {
      _server = await ServerSocket.bind(addr, kLanPort);
    } on SocketException {
      _server = await ServerSocket.bind(addr, 0);
    }
    _accept = _server!.listen((s) => unawaited(_handle(SocketChannel(s))));
    if (beacon) await _startBeacon();
  }

  LanGameInfo info(String address) => LanGameInfo(
    hostName: hostName,
    address: address,
    port: port,
    mode: config.mode.name,
    length: config.length,
  );

  Future<void> _handle(SocketChannel ch) async {
    final hello = await ch.first();
    switch (hello?['t']) {
      case 'probe':
        if (!_guest.isCompleted) {
          ch.send({'t': 'info', ...info('').toJson()});
        }
        await Future<void>.delayed(const Duration(milliseconds: 50));
        await ch.close();
      case 'join':
        if (hello!['v'] != kLanProtocol) {
          ch.send(const {'t': 'refuse', 'why': 'version'});
          await ch.close();
          return;
        }
        final id = hello['id'] as String?;
        if (_guest.isCompleted) {
          if (id == matchId) {
            ch.send({'t': 'welcome', 'v': kLanProtocol, 'id': matchId});
            _reconnects.add(ch);
          } else {
            ch.send(const {'t': 'refuse', 'why': 'full'});
            await ch.close();
          }
          return;
        }
        ch.send({
          't': 'welcome',
          'v': kLanProtocol,
          'id': matchId,
          'host': hostName,
          'cfg': config.toJson(),
        });
        _guest.complete((ch, (hello['name'] as String?) ?? ''));
        _beaconTimer?.cancel();
      default:
        await ch.close();
    }
  }

  Future<void> _startBeacon() async {
    try {
      final udp = _udp = await RawDatagramSocket.bind(
        InternetAddress.anyIPv4,
        0,
      );
      udp.broadcastEnabled = true;
      void announce() {
        final data = utf8.encode(
          '$_beaconTag ${jsonEncode(info('').toJson())}',
        );
        try {
          udp.send(data, InternetAddress('255.255.255.255'), kLanBeaconPort);
        } on Object {
          // Some networks forbid broadcast; the guest's scan still works.
        }
      }

      announce();
      _beaconTimer = Timer.periodic(
        const Duration(seconds: 1),
        (_) => announce(),
      );
    } on Object {
      // No UDP (e.g. sandboxed): discovery falls back to scanning.
    }
  }

  Future<void> stop() async {
    _beaconTimer?.cancel();
    _udp?.close();
    await _accept?.cancel();
    await _server?.close();
    await _reconnects.close();
  }
}

/// Finds open games: listens for beacons and scans the local /24 subnets
/// (the scan also works where broadcast is filtered, e.g. some hotspots).
class LanDiscovery {
  LanDiscovery({this.scanTimeout = const Duration(milliseconds: 450)});

  final Duration scanTimeout;
  final Set<LanGameInfo> _found = {};
  final StreamController<List<LanGameInfo>> _out = StreamController.broadcast();
  RawDatagramSocket? _udp;
  bool _stopped = false;

  Stream<List<LanGameInfo>> get games => _out.stream;
  List<LanGameInfo> get current => List.unmodifiable(_found);

  void _add(LanGameInfo g) {
    if (_stopped) return;
    if (_found.add(g)) _out.add(current);
  }

  Future<void> start() async {
    try {
      final udp = _udp = await RawDatagramSocket.bind(
        InternetAddress.anyIPv4,
        kLanBeaconPort,
      );
      udp.listen((e) {
        if (e != RawSocketEvent.read) return;
        final d = udp.receive();
        if (d == null) return;
        final text = utf8.decode(d.data, allowMalformed: true);
        if (!text.startsWith('$_beaconTag ')) return;
        try {
          final j = (jsonDecode(text.substring(_beaconTag.length + 1)) as Map)
              .cast<String, Object?>();
          final g = LanGameInfo.fromJson(j, d.address.address);
          if (g != null) _add(g);
        } on FormatException {
          return;
        }
      });
    } on Object {
      // Beacon port busy or unavailable: rely on [scan].
    }
    unawaited(scan());
  }

  /// Probes every address of this device's /24 subnets on [kLanPort].
  Future<void> scan({int port = kLanPort}) async {
    final mine = await localAddresses();
    final targets = <String>{};
    for (final a in mine) {
      final p = a.split('.');
      if (p.length != 4) continue;
      for (var i = 1; i < 255; i++) {
        targets.add('${p[0]}.${p[1]}.${p[2]}.$i');
      }
    }
    final list = targets.toList();
    const batch = 64;
    for (var i = 0; i < list.length && !_stopped; i += batch) {
      await Future.wait([
        for (final t in list.skip(i).take(batch)) _probe(t, port),
      ]);
    }
  }

  Future<void> _probe(String address, int port) async {
    final g = await probeHost(address, port: port, timeout: scanTimeout);
    if (g != null) _add(g);
  }

  Future<void> stop() async {
    _stopped = true;
    _udp?.close();
    await _out.close();
  }
}

/// Asks [address] whether it hosts an open game.
Future<LanGameInfo?> probeHost(
  String address, {
  int port = kLanPort,
  Duration timeout = const Duration(milliseconds: 450),
}) async {
  SocketChannel? ch;
  try {
    final s = await Socket.connect(address, port, timeout: timeout);
    ch = SocketChannel(s)..send(const {'t': 'probe'});
    final m = await ch.first(timeout: timeout * 2);
    if (m == null || m['t'] != 'info') return null;
    return LanGameInfo.fromJson(m, address);
  } on Object {
    return null;
  } finally {
    await ch?.close();
  }
}

/// The host's answer to a join.
class LanWelcome {
  const LanWelcome({
    required this.channel,
    required this.matchId,
    this.hostName = '',
    this.config,
  });
  final SocketChannel channel;
  final String matchId;
  final String hostName;

  /// Null on a reconnect (the guest already has the match).
  final MatchConfig? config;
}

class LanJoinException implements Exception {
  const LanJoinException(this.reason);

  /// 'unreachable', 'version', 'full' or 'noanswer'.
  final String reason;
  @override
  String toString() => 'LanJoinException($reason)';
}

/// Joins the game at [address] (or rejoins match [matchId]).
Future<LanWelcome> joinHost(
  String address, {
  required String name,
  int port = kLanPort,
  String? matchId,
  Duration timeout = const Duration(seconds: 4),
}) async {
  final Socket s;
  try {
    s = await Socket.connect(address, port, timeout: timeout);
  } on Object {
    throw const LanJoinException('unreachable');
  }
  final ch = SocketChannel(s)
    ..send({'t': 'join', 'v': kLanProtocol, 'name': name, 'id': ?matchId});
  final m = await ch.first(timeout: timeout);
  if (m == null) {
    await ch.close();
    throw const LanJoinException('noanswer');
  }
  if (m['t'] != 'welcome') {
    await ch.close();
    throw LanJoinException((m['why'] as String?) ?? 'noanswer');
  }
  final cfg = m['cfg'];
  return LanWelcome(
    channel: ch,
    matchId: m['id']! as String,
    hostName: (m['host'] as String?) ?? '',
    config: cfg is Map
        ? MatchConfig.fromJson(cfg.cast<String, Object?>())
        : null,
  );
}

/// Keeps a LAN game connected: the host re-attaches reconnecting guests,
/// the guest retries the host every couple of seconds after a drop.
class LanSession {
  LanSession.host(this.link, LanHost this.host)
    : hostAddress = null,
      hostPort = null,
      guestName = null {
    _sub = host!.reconnects.listen(link.attach);
  }

  /// A link whose channel the caller manages (tests, in-memory play).
  LanSession.direct(this.link)
    : host = null,
      hostAddress = null,
      hostPort = null,
      guestName = null;

  LanSession.guest(
    this.link, {
    required String this.hostAddress,
    required int this.hostPort,
    required String this.guestName,
  }) : host = null {
    link.status.addListener(_onStatus);
  }

  final LanLink link;
  final LanHost? host;
  final String? hostAddress;
  final int? hostPort;
  final String? guestName;
  StreamSubscription<SocketChannel>? _sub;
  Timer? _retry;
  bool _closed = false;

  void _onStatus() {
    if (_closed || link.status.value != LanStatus.lost) return;
    _retry ??= Timer.periodic(const Duration(seconds: 2), (_) async {
      if (_closed || link.status.value != LanStatus.lost) return;
      try {
        final w = await joinHost(
          hostAddress!,
          port: hostPort!,
          name: guestName!,
          matchId: link.matchId,
          timeout: const Duration(seconds: 2),
        );
        if (_closed) return unawaited(w.channel.close());
        _retry?.cancel();
        _retry = null;
        link.attach(w.channel);
      } on LanJoinException {
        // Try again on the next tick.
      }
    });
  }

  Future<void> close() async {
    if (_closed) return;
    _closed = true;
    _retry?.cancel();
    await _sub?.cancel();
    if (hostAddress != null) link.status.removeListener(_onStatus);
    await link.dispose();
    await host?.stop();
  }
}
