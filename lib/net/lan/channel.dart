import 'dart:async';
import 'dart:convert';
import 'dart:io';

/// A message pipe between two devices: one JSON object per message.
abstract interface class LanChannel {
  Stream<Map<String, Object?>> get messages;
  void send(Map<String, Object?> message);
  Future<void> close();
}

/// Newline-delimited JSON over a TCP socket.
class SocketChannel implements LanChannel {
  SocketChannel(this.socket) {
    socket.setOption(SocketOption.tcpNoDelay, true);
    _sub = utf8.decoder
        .bind(socket)
        .transform(const LineSplitter())
        .listen(
          (line) {
            if (line.isEmpty) return;
            try {
              final m = jsonDecode(line);
              if (m is! Map) return;
              final msg = m.cast<String, Object?>();
              if (!_first.isCompleted) {
                _first.complete(msg);
              } else {
                _in.add(msg);
              }
            } on FormatException {
              // A garbled line is dropped; the hash check catches any gap.
            }
          },
          onError: (Object _) => unawaited(close()),
          onDone: () => unawaited(close()),
          cancelOnError: true,
        );
  }

  final Socket socket;
  final StreamController<Map<String, Object?>> _in = StreamController();
  final Completer<Map<String, Object?>?> _first = Completer();

  /// The connection's first message (the handshake), or null if the peer
  /// closed or said nothing in time. Later messages go to [messages].
  Future<Map<String, Object?>?> first({
    Duration timeout = const Duration(seconds: 4),
  }) => _first.future.timeout(timeout, onTimeout: () => null);
  late final StreamSubscription<String> _sub;
  bool _closed = false;

  String get remoteAddress => socket.remoteAddress.address;

  @override
  Stream<Map<String, Object?>> get messages => _in.stream;

  @override
  void send(Map<String, Object?> message) {
    if (_closed) return;
    try {
      socket.write('${jsonEncode(message)}\n');
    } on Object {
      unawaited(close());
    }
  }

  @override
  Future<void> close() async {
    if (_closed) return;
    _closed = true;
    if (!_first.isCompleted) _first.complete(null);
    await _sub.cancel();
    socket.destroy();
    // Not awaited: an unlistened controller's close never completes.
    unawaited(_in.close());
  }
}

/// Two connected in-memory ends (tests, and a local loopback).
class MemoryChannel implements LanChannel {
  MemoryChannel._();

  static (MemoryChannel, MemoryChannel) pair() {
    final a = MemoryChannel._();
    final b = MemoryChannel._();
    a._peer = b;
    b._peer = a;
    return (a, b);
  }

  late MemoryChannel _peer;
  final StreamController<Map<String, Object?>> _in = StreamController();
  bool _closed = false;

  /// Messages are dropped while false (simulates a lost connection).
  bool connected = true;

  @override
  Stream<Map<String, Object?>> get messages => _in.stream;

  @override
  void send(Map<String, Object?> message) {
    if (_closed || !connected || _peer._closed) return;
    // Round-trip through JSON so tests see exactly what goes on the wire.
    final copy = (jsonDecode(jsonEncode(message)) as Map)
        .cast<String, Object?>();
    scheduleMicrotask(() {
      if (!_peer._closed) _peer._in.add(copy);
    });
  }

  @override
  Future<void> close() async {
    if (_closed) return;
    _closed = true;
    unawaited(_in.close());
    if (!_peer._closed) await _peer.close();
  }
}
