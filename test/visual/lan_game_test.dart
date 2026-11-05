// A LAN match in the real game screen: this phone hosts (White) while the
// other phone (a headless controller playing Black) talks over an
// in-memory wire. The match finishes identically on both, a dropped
// connection shows the banner and recovers, and opponent emotes arrive.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:haftnard/core/ai/ai.dart';
import 'package:haftnard/core/ai/personality.dart';
import 'package:haftnard/core/rules/match.dart';
import 'package:haftnard/core/rules/record.dart';
import 'package:haftnard/core/rules/types.dart';
import 'package:haftnard/game/audio.dart';
import 'package:haftnard/game/match_controller.dart';
import 'package:haftnard/game/scene/board_game.dart';
import 'package:haftnard/meta/meta_state.dart';
import 'package:haftnard/meta/save.dart';
import 'package:haftnard/meta/settings.dart';
import 'package:haftnard/net/lan/channel.dart';
import 'package:haftnard/net/lan/lan_link.dart';
import 'package:haftnard/net/lan/lan_lobby.dart';
import 'package:haftnard/ui/app.dart';
import 'package:haftnard/ui/game/seven_overlay.dart';
import 'package:haftnard/ui/screens/game_screen.dart';
import 'package:haftnard/ui/widgets/jewel.dart';

void main() {
  setUpAll(() {
    Sfx.instance.available = false;
    SevenOverlay.useSensors = false;
    kAiUseIsolates = false;
  });

  testWidgets('a LAN match plays out on the game screen', (t) async {
    t.view.devicePixelRatio = 1;
    t.view.physicalSize = const Size(400, 860);
    addTearDown(t.view.reset);
    const cfg = MatchConfig(seed: 2024, p7: 0.08);
    final hostLink = LanLink(localSide: Side.white, matchId: 'x', isHost: true);
    final guestLink = LanLink(
      localSide: Side.black,
      matchId: 'x',
      isHost: false,
    );
    final guest = MatchController(
      MatchSession(
        match: MatchState(cfg),
        white: const SeatConfig.remote('Sara'),
        black: const SeatConfig.human('Ali'),
        origin: 'lan',
      ),
      pacing: Duration.zero,
      useIsolates: false,
      lan: guestLink,
    );
    var (a, b) = MemoryChannel.pair();
    final session = MatchSession(
      match: MatchState(cfg),
      white: const SeatConfig.human('Sara'),
      black: const SeatConfig.remote('Ali'),
      origin: 'lan',
    );
    final svc = SaveService(MemorySaveStore());
    svc.data.settings = const Settings(
      language: 'en',
      sound: false,
      music: false,
      animSpeed: 2,
      tutorialDone: true,
    );
    await t.pumpWidget(
      ProviderScope(
        overrides: [saveServiceProvider.overrideWithValue(svc)],
        child: HaftNardApp(
          home: GameScreen(
            session: session,
            lan: LanSession.direct(hostLink),
            onLanReady: () => hostLink.attach(a),
          ),
        ),
      ),
    );
    guestLink.attach(b);
    unawaited(guest.begin());
    expect(find.text('Ali'), findsWidgets, reason: 'remote name on the HUD');

    final brain = AiBrain(const AiConfig(difficulty: Difficulty.easy));
    var sawBanner = false;
    var cut = false;
    var reconnected = false;
    var emoted = false;
    var lastProgress = -1;
    var stuck = 0;
    for (var i = 0; i < 30000 && !session.match.isOver; i++) {
      await t.pump(const Duration(milliseconds: 80));
      final g = BoardGame.current;
      if (g == null || !g.isLoaded) continue;
      final host = g.controller;
      final progress = host.gameLog.length + guest.gameLog.length * 1000;
      if (progress != lastProgress) {
        lastProgress = progress;
        stuck = 0;
      } else if (++stuck > 800) {
        fail(
          'stalled: host ${host.state.phase} log ${host.gameLog.length} '
          'wait ${host.waitingForHuman} busy ${host.busy} '
          'ai ${host.aiThinking} ${hostLink.status.value}; guest '
          '${guest.state.phase} log ${guest.gameLog.length} wait '
          '${guest.waitingForHuman} busy ${guest.busy} '
          '${guestLink.status.value} cut $cut rec $reconnected',
        );
      }
      // The opponent's 7–7 pick waits for "got it" (the 8 s fallback would
      // also release it).
      final ack = find.byKey(const ValueKey('ai-pick-ack'));
      if (ack.evaluate().isNotEmpty) {
        t.widget<JewelButton>(ack).onPressed?.call();
      }
      if (host.waitingForHuman) {
        unawaited(host.act(brain.decide(host.state).first));
      }
      if (guest.waitingForHuman) {
        unawaited(guest.act(brain.decide(guest.state).first));
      }
      if (!emoted && host.gameLog.length > 6) {
        emoted = true;
        guestLink.sendEmote('emo_wellplayed');
        await t.pump(const Duration(milliseconds: 300));
        expect(find.text('Well played'), findsOneWidget, reason: 'emote');
      }
      // Cut the wire mid-game, wait for the heartbeat to notice, reconnect.
      if (!cut && host.gameLog.length > 30) {
        cut = true;
        a.connected = false;
        b.connected = false;
      }
      if (cut && !reconnected) {
        if (find.byKey(const ValueKey('lan-banner')).evaluate().isNotEmpty) {
          sawBanner = true;
          (a, b) = MemoryChannel.pair();
          hostLink.attach(a);
          guestLink.attach(b);
          reconnected = true;
        }
      }
    }
    expect(session.match.isOver, isTrue, reason: 'match did not finish');
    expect(emoted, isTrue);
    expect(sawBanner, isTrue, reason: 'no lost-connection banner');
    expect(find.byKey(const ValueKey('lan-banner')), findsNothing);
    // Let the guest apply the final batch.
    for (var i = 0; i < 50 && !guest.match.isOver; i++) {
      await t.pump(const Duration(milliseconds: 100));
    }
    expect(
      guest.match.results.single.toJson(),
      session.match.results.single.toJson(),
    );
    expect(
      stateHash(guest.state),
      stateHash(BoardGame.current!.controller.state),
    );
    expect(t.takeException(), isNull);
    await t.pumpWidget(const SizedBox());
    await t.pump(const Duration(seconds: 5));
    guest.dispose();
    unawaited(guestLink.dispose());
    await t.pump(const Duration(seconds: 1));
  }, timeout: const Timeout(Duration(minutes: 20)));
}
