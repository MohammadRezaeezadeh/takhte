// The LAN lobby on screen: Play → Friend (Wi-Fi) → Create game waits and
// shows this phone's address; a guest joining over a real (loopback)
// socket starts the game. Joining a dead address shows a clear error.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:haftnard/game/audio.dart';
import 'package:haftnard/game/match_controller.dart';
import 'package:haftnard/net/lan/lan_lobby.dart';
import 'package:haftnard/ui/game/seven_overlay.dart';
import 'package:haftnard/ui/screens/game_screen.dart';
import 'package:haftnard/ui/screens/lan_screen.dart';
import 'package:haftnard/ui/screens/play_setup.dart';

import 'screens_test.dart' show harness;

Future<void> _real(WidgetTester t, [int ms = 150]) async {
  await t.runAsync(() => Future<void>.delayed(Duration(milliseconds: ms)));
  await t.pump(const Duration(milliseconds: 50));
}

void main() {
  setUpAll(() {
    Sfx.instance.available = false;
    SevenOverlay.useSensors = false;
    kAiUseIsolates = false;
    LanScreen.loopbackOnly = true;
  });

  testWidgets('host from the play menu, a guest joins, the game starts', (
    t,
  ) async {
    t.view.devicePixelRatio = 1;
    t.view.physicalSize = const Size(420, 900);
    addTearDown(t.view.reset);
    await t.pumpWidget(harness(const PlaySetupScreen()));
    await t.pump(const Duration(milliseconds: 300));
    final tile = find.byKey(const ValueKey('lan-tile'));
    await t.scrollUntilVisible(
      tile,
      200,
      scrollable: find
          .byWidgetPredicate(
            (w) => w is Scrollable && w.axisDirection == AxisDirection.right,
          )
          .first,
    );
    await t.tap(tile);
    await t.pump(const Duration(milliseconds: 300));
    final hostButton = find.byKey(const ValueKey('lan-host-button'));
    await t.ensureVisible(hostButton);
    await t.tap(hostButton);
    for (var i = 0; i < 10; i++) {
      await _real(t);
    }
    expect(find.byKey(const ValueKey('lan-host')), findsOneWidget);
    expect(find.text('Waiting for your friend…'), findsOneWidget);
    expect(find.text('127.0.0.1'), findsOneWidget);

    final host = LanScreen.debugHost!;
    // The host's socket callbacks run in the test's fake time and the
    // guest's in real time: interleave both until the handshake is done.
    LanWelcome? welcome;
    await t.runAsync(() async {
      unawaited(
        joinHost(
          '127.0.0.1',
          port: host.port,
          name: 'Ali',
        ).then((w) => welcome = w),
      );
    });
    for (var i = 0; i < 40 && welcome == null; i++) {
      await _real(t, 50);
    }
    expect(welcome?.config, isNotNull);
    for (var i = 0; i < 10; i++) {
      await _real(t);
    }
    expect(find.byType(GameScreen), findsOneWidget);
    expect(find.text('Ali'), findsWidgets, reason: 'guest name on the HUD');

    // Leaving tells the guest (it counts as resigning there).
    final bye = welcome!.channel.messages.firstWhere((m) => m['t'] == 'bye');
    await t.pumpWidget(const SizedBox());
    for (var i = 0; i < 5; i++) {
      await _real(t);
    }
    Map<String, Object?>? got;
    await t.runAsync(() async {
      unawaited(bye.then((m) => got = m));
    });
    for (var i = 0; i < 40 && got == null; i++) {
      await _real(t, 50);
    }
    expect(got?['t'], 'bye');
    await t.runAsync(welcome!.channel.close);
    await t.pump(const Duration(seconds: 5));
  });

  testWidgets('joining an address with no game shows why', (t) async {
    t.view.devicePixelRatio = 1;
    t.view.physicalSize = const Size(420, 900);
    addTearDown(t.view.reset);
    await t.pumpWidget(harness(const LanScreen.join()));
    await t.pump(const Duration(milliseconds: 300));
    await t.enterText(find.byKey(const ValueKey('lan-address')), '127.0.0.1:1');
    await t.tap(find.byKey(const ValueKey('lan-connect')));
    for (var i = 0; i < 20; i++) {
      await _real(t, 100);
      if (find.byKey(const ValueKey('lan-error')).evaluate().isNotEmpty) break;
    }
    expect(find.text("Couldn't reach that address."), findsOneWidget);
  });
}
