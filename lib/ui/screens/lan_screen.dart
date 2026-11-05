import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:haftnard/core/rules/match.dart';
import 'package:haftnard/core/rules/state.dart';
import 'package:haftnard/core/rules/types.dart';
import 'package:haftnard/game/match_controller.dart';
import 'package:haftnard/net/lan/lan_link.dart';
import 'package:haftnard/net/lan/lan_lobby.dart';
import 'package:haftnard/ui/app.dart';
import 'package:haftnard/ui/screens/game_screen.dart';
import 'package:haftnard/ui/theme.dart';
import 'package:haftnard/ui/widgets/jewel.dart';
import 'package:haftnard/ui/widgets/menu_background.dart';
import 'package:haftnard/ui/widgets/top_bar.dart';

/// Playing a friend on the same Wi-Fi or hotspot: create a game (and wait
/// for them) or find and join theirs. No server: the phones talk directly.
class LanScreen extends StatefulWidget {
  const LanScreen.host({required MatchConfig this.config, super.key});
  const LanScreen.join({super.key}) : config = null;

  /// Set when hosting.
  final MatchConfig? config;

  bool get hosting => config != null;

  /// Tests: bind to loopback and skip broadcast.
  @visibleForTesting
  static bool loopbackOnly = false;

  /// Tests: the host this screen opened.
  @visibleForTesting
  static LanHost? debugHost;

  @override
  State<LanScreen> createState() => _LanScreenState();
}

class _LanScreenState extends State<LanScreen> {
  final TextEditingController _name = TextEditingController();
  final TextEditingController _address = TextEditingController();
  LanHost? _host;
  LanDiscovery? _discovery;
  List<String> _mine = const [];
  List<LanGameInfo> _games = const [];
  StreamSubscription<List<LanGameInfo>>? _gamesSub;
  String? _error;
  bool _connecting = false;
  bool _started = false;
  bool _handedOff = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    final l = context.l10n;
    _name.text = widget.hosting ? l.lanHostDefault : l.lanGuestDefault;
    unawaited(widget.hosting ? _startHost() : _startJoin());
  }

  Future<void> _startHost() async {
    final host = _host = LanScreen.debugHost = LanHost(
      hostName: _name.text,
      config: widget.config!,
      beacon: !LanScreen.loopbackOnly,
    );
    try {
      await host.start(
        bindTo: LanScreen.loopbackOnly ? InternetAddress.loopbackIPv4 : null,
      );
    } on Object {
      if (mounted) setState(() => _error = context.l10n.lanErrUnreachable);
      return;
    }
    final mine = LanScreen.loopbackOnly
        ? const ['127.0.0.1']
        : await localAddresses();
    if (!mounted) return;
    setState(() => _mine = mine);
    final (channel, guestName) = await host.guest;
    if (!mounted) {
      await channel.close();
      return;
    }
    final link = LanLink(
      localSide: Side.white,
      matchId: host.matchId,
      isHost: true,
    );
    final lan = LanSession.host(link, host);
    final l = context.l10n;
    _go(
      MatchSession(
        match: MatchState(widget.config!),
        white: SeatConfig.human(
          _name.text.trim().isEmpty ? l.lanHostDefault : _name.text.trim(),
        ),
        black: SeatConfig.remote(
          guestName.isEmpty ? l.lanGuestDefault : guestName,
        ),
        origin: 'lan',
      ),
      lan,
      () => link.attach(channel),
    );
  }

  Future<void> _startJoin() async {
    if (LanScreen.loopbackOnly) return;
    final d = _discovery = LanDiscovery();
    _gamesSub = d.games.listen((g) {
      if (mounted) setState(() => _games = g);
    });
    await d.start();
  }

  Future<void> _join(String address, {int port = kLanPort}) async {
    if (_connecting) return;
    final l = context.l10n;
    setState(() {
      _connecting = true;
      _error = null;
    });
    final name = _name.text.trim().isEmpty
        ? l.lanGuestDefault
        : _name.text.trim();
    try {
      final w = await joinHost(address.trim(), port: port, name: name);
      if (!mounted) {
        await w.channel.close();
        return;
      }
      final link = LanLink(
        localSide: Side.black,
        matchId: w.matchId,
        isHost: false,
      );
      final lan = LanSession.guest(
        link,
        hostAddress: address.trim(),
        hostPort: port,
        guestName: name,
      );
      _go(
        MatchSession(
          match: MatchState(w.config!),
          white: SeatConfig.remote(
            w.hostName.isEmpty ? l.lanHostDefault : w.hostName,
          ),
          black: SeatConfig.human(name),
          origin: 'lan',
        ),
        lan,
        () => link.attach(w.channel),
      );
    } on LanJoinException catch (e) {
      if (!mounted) return;
      setState(() {
        _connecting = false;
        _error = switch (e.reason) {
          'full' => l.lanErrFull,
          'version' => l.lanErrVersion,
          'noanswer' => l.lanErrNoAnswer,
          _ => l.lanErrUnreachable,
        };
      });
    }
  }

  /// "192.168.43.1" or "192.168.43.1:47470".
  Future<void> _joinTyped(String text) {
    final t = text.trim();
    final i = t.lastIndexOf(':');
    final port = i > 0 ? int.tryParse(t.substring(i + 1)) : null;
    return port == null ? _join(t) : _join(t.substring(0, i), port: port);
  }

  void _go(MatchSession session, LanSession lan, VoidCallback attach) {
    _handedOff = true;
    unawaited(
      Navigator.of(context).pushReplacement(
        fadeRoute<void>(
          GameScreen(session: session, lan: lan, onLanReady: attach),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _name.dispose();
    _address.dispose();
    unawaited(_gamesSub?.cancel());
    unawaited(_discovery?.stop());
    // A host that handed off keeps listening (reconnects) inside the game.
    if (!_handedOff) unawaited(_host?.stop());
    super.dispose();
  }

  String _modeLabel(String mode) {
    final l = context.l10n;
    return mode == GameMode.classic.name ? l.modeClassic : l.modeSeven;
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Scaffold(
      body: MenuBackground(
        child: SafeArea(
          child: Column(
            children: [
              ScreenHeader(title: widget.hosting ? l.lanHost : l.lanJoin),
              Expanded(
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 520),
                    child: ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        Panel(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              TextField(
                                key: const ValueKey('lan-name'),
                                controller: _name,
                                maxLength: 16,
                                decoration: InputDecoration(
                                  labelText: l.lanYourName,
                                  counterText: '',
                                ),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                l.lanHelp,
                                style: const TextStyle(
                                  color: AppColors.muted,
                                  height: 1.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),
                        if (widget.hosting) _hostPanel() else _joinPanel(),
                        if (_error != null) ...[
                          const SizedBox(height: 12),
                          Text(
                            _error!,
                            key: const ValueKey('lan-error'),
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: AppColors.ruby,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _hostPanel() {
    final l = context.l10n;
    return Panel(
      key: const ValueKey('lan-host'),
      child: Column(
        children: [
          const SizedBox(
            width: 34,
            height: 34,
            child: CircularProgressIndicator(color: AppColors.goldLight),
          ),
          const SizedBox(height: 12),
          Text(
            l.lanWaiting,
            style: const TextStyle(
              fontFamily: AppFonts.display,
              fontSize: 22,
              color: AppColors.goldLight,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            l.lanYourAddress,
            style: const TextStyle(color: AppColors.muted),
          ),
          for (final a in _mine)
            Directionality(
              textDirection: TextDirection.ltr,
              child: SelectableText(
                a,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _joinPanel() {
    final l = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Panel(
          key: const ValueKey('lan-games'),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.goldLight,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(l.lanSearching),
                ],
              ),
              const SizedBox(height: 8),
              if (_games.isEmpty)
                Text(
                  l.lanNoGames,
                  style: const TextStyle(color: AppColors.muted),
                ),
              for (final g in _games)
                ListTile(
                  key: ValueKey('lan-game-${g.address}'),
                  leading: const Icon(Icons.wifi, color: AppColors.goldLight),
                  title: Text(g.hostName),
                  subtitle: Text(
                    '${_modeLabel(g.mode)} · ${l.pointsN(g.length)} · '
                    '${g.address}',
                  ),
                  onTap: _connecting
                      ? null
                      : () => unawaited(_join(g.address, port: g.port)),
                ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Panel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Directionality(
                textDirection: TextDirection.ltr,
                child: TextField(
                  key: const ValueKey('lan-address'),
                  controller: _address,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: InputDecoration(hintText: l.lanAddressHint),
                  onSubmitted: (v) => unawaited(_joinTyped(v)),
                ),
              ),
              const SizedBox(height: 10),
              JewelButton(
                key: const ValueKey('lan-connect'),
                label: l.lanConnect,
                icon: Icons.link,
                color: AppColors.emerald,
                enabled: !_connecting,
                onPressed: () => unawaited(_joinTyped(_address.text)),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
