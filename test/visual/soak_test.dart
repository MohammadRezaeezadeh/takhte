// Soak test: 50 complete AI-vs-AI matches (each ends with a full bear-off)
// in one app session (one provider container, like the real app), each
// through a fresh GameScreen + Flame scene with the real AudioManager on a
// fake backend.
//
// Each match is its own testWidgets: `flutter test` always runs with
// --chain-stack-traces, and one long async test body grows an unbounded
// stack_trace chain (~2 MB per match of _Closure/_SuspendState/LazyTrace)
// that would hide or fake app-level growth. Splitting per match frees the
// chain at every test end, so the heap check measures only the app.
//
// Bear-off used to be where things went wrong (a new audio player and a
// per-frame text layout on every bear-off), so every frame of the bear-off
// is sampled: object counts must stay flat while bearing off and return to
// the match's baseline afterwards.
import 'dart:developer' as dev;
import 'dart:io';
import 'dart:isolate';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:haftnard/core/ai/personality.dart';
import 'package:haftnard/core/rules/match.dart';
import 'package:haftnard/core/rules/types.dart';
import 'package:haftnard/game/audio.dart';
import 'package:haftnard/game/audio/audio_manager.dart';
import 'package:haftnard/game/match_controller.dart';
import 'package:haftnard/game/scene/board_game.dart';
import 'package:haftnard/game/scene/fx.dart';
import 'package:haftnard/meta/meta_state.dart';
import 'package:haftnard/meta/save.dart';
import 'package:haftnard/meta/settings.dart';
import 'package:haftnard/ui/app.dart';
import 'package:haftnard/ui/game/seven_overlay.dart';
import 'package:haftnard/ui/screens/game_screen.dart';

import 'package:vm_service/vm_service.dart' show VmService;
import 'package:vm_service/vm_service_io.dart';

import '../support/fake_audio.dart';

void main() {
  const matches = int.fromEnvironment('SOAK_MATCHES', defaultValue: 50);
  final backend = FakeBackend();
  late AudioManager audio;

  setUpAll(() {
    SevenOverlay.useSensors = false;
    kAiUseIsolates = false;
    audio = AudioManager(backend);
    Sfx.instance
      ..available = true
      ..manager = audio;
  });

  tearDownAll(() {
    Sfx.instance
      ..manager = null
      ..available = false;
  });

  // State shared across the per-match tests.
  final svc = SaveService(MemorySaveStore());
  svc.data.settings = const Settings(animSpeed: 2);
  final container = ProviderContainer(
    overrides: [saveServiceProvider.overrideWithValue(svc)],
  );
  Widget app(Widget home) => UncontrolledProviderScope(
    container: container,
    child: HaftNardApp(home: home),
  );
  const tracked = {'SaveService', 'ProviderContainer', 'MatchController'};
  VmService? vm;
  String? iso;
  Map<String, int>? classBytes;
  var growthReport = '';
  int? heapAt5;
  late int players;
  final weak = <WeakReference<BoardGame>>[];
  final rss = <double>[];
  int? firstBaseline;

  Future<(int, Map<String, int>)> heap(Set<String> classes) async {
    final v = vm!;
    final prof = await v.getAllocationProfile(iso!, gc: true);
    final bytes = <String, int>{
      for (final c in prof.members!)
        '${c.classRef!.library?.uri?.split('/').last}:${c.classRef!.name}':
            c.bytesCurrent ?? 0,
    };
    final prev = classBytes;
    if (prev != null) {
      final d = [
        for (final e in bytes.entries) (e.key, e.value - (prev[e.key] ?? 0)),
      ]..sort((a, b) => b.$2.compareTo(a.$2));
      growthReport = d
          .take(15)
          .map((x) => '${x.$1} +${x.$2 >> 10}KB')
          .join(', ');
    }
    classBytes = bytes;
    // Dart objects only: VM-internal classes (no library: Code,
    // Instructions, Function, ...) are JIT artefacts of newly exercised code
    // paths that an AOT release build doesn't have.
    final dartBytes = [
      for (final c in prof.members!)
        if (c.classRef!.library != null) c.bytesCurrent ?? 0,
    ].fold(0, (a, b) => a + b);
    return (
      dartBytes,
      {
        for (final c in prof.members!)
          if (classes.contains(c.classRef!.name))
            c.classRef!.name!: c.instancesCurrent ?? 0,
      },
    );
  }

  setUpAll(() async {
    await Sfx.instance.preload();
    players = backend.voices.length;
    // Heap checks need the VM service (`flutter test --coverage` in CI or
    // `--enable-vmservice` in tool/check.sh): full GC, then exact counts.
    final info = await dev.Service.getInfo();
    final ws = info.serverWebSocketUri;
    if (ws != null) {
      vm = await vmServiceConnectUri(ws.toString());
      iso = dev.Service.getIsolateId(Isolate.current);
    }
  });

  tearDownAll(() async {
    await vm?.dispose();
    container.dispose();
  });

  void sized(WidgetTester tester) {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(400, 860);
    addTearDown(tester.view.reset);
  }

  for (var m = 0; m < matches; m++) {
    testWidgets('soak match $m: bear-off keeps every count flat', (
      tester,
    ) async {
      sized(tester);
      final session = MatchSession(
        match: MatchState(MatchConfig(seed: 100 + m)),
        white: const SeatConfig.ai(
          personalityId: 'hammer',
          difficulty: Difficulty.easy,
          name: 'W',
        ),
        black: const SeatConfig.ai(
          personalityId: 'fox',
          difficulty: Difficulty.easy,
          name: 'B',
        ),
      );
      await tester.pumpWidget(
        app(GameScreen(key: ValueKey(m), session: session)),
      );
      final layoutsBefore = FxLayer.debugPopupLayouts;
      final popupsBefore = FxLayer.debugPopupsCreated;
      int? baseComponents;
      int? baseListeners;
      var bearOffFrames = 0;
      for (var i = 0; i < 12000 && !session.match.isOver; i++) {
        await tester.pump(const Duration(milliseconds: 60));
        final g = BoardGame.current;
        if (g == null || !g.isLoaded) continue;
        final st = g.debugStats();
        final ctrl = g.controller;
        baseComponents ??= st['components'];
        baseListeners ??= ctrl.listenerCount;
        final s = ctrl.state;
        final bearingOff =
            s.board.borneOff(Side.white) > 0 ||
            s.board.borneOff(Side.black) > 0;
        if (!bearingOff) continue;
        bearOffFrames++;
        final where = 'match $m, bear-off frame $bearOffFrames';
        expect(
          st['components'],
          lessThanOrEqualTo(baseComponents! + 2),
          reason: 'components grew during bear-off ($where)',
        );
        expect(st['particles'], lessThanOrEqualTo(FxLayer.maxParticles));
        expect(st['popups'], lessThanOrEqualTo(FxLayer.maxPopups));
        expect(audio.activeCount, lessThanOrEqualTo(audio.maxActive));
        expect(
          backend.voices,
          hasLength(players),
          reason: 'new player ($where)',
        );
        expect(
          ctrl.listenerCount,
          baseListeners,
          reason: 'listeners changed during bear-off ($where)',
        );
      }
      expect(session.match.isOver, isTrue, reason: 'match $m stalled');
      expect(bearOffFrames, greaterThan(10), reason: 'match $m bear-off');
      // Let the game-over effects and every sound finish.
      for (var i = 0; i < 50; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      expect(tester.takeException(), isNull, reason: 'match $m');
      final g = BoardGame.current!;
      weak.add(WeakReference(g));
      final end = g.debugStats();
      firstBaseline ??= baseComponents;
      expect(
        end['components'],
        lessThanOrEqualTo(baseComponents! + 2),
        reason: 'match $m: components did not return to baseline',
      );
      expect(baseComponents, lessThanOrEqualTo(firstBaseline! + 2));
      expect(end['images'], lessThanOrEqualTo(2));
      expect(audio.stats.resets, 0, reason: 'audio needed a reset');
      expect(MatchController.live, lessThanOrEqualTo(1));
      // One text layout per popup, never one per frame.
      expect(
        FxLayer.debugPopupLayouts - layoutsBefore,
        lessThanOrEqualTo(FxLayer.debugPopupsCreated - popupsBefore),
        reason: 'popup text laid out per frame in match $m',
      );
      rss.add(ProcessInfo.currentRss / (1 << 20));
      // Back to the menu before the test ends (the binding would otherwise
      // tear the tree down itself).
      await tester.pumpWidget(app(const SizedBox()));
      await tester.pump(const Duration(seconds: 6));
      if (vm != null && m == 5) {
        heapAt5 = (await tester.runAsync(() => heap(tracked)))!.$1;
      }
    }, timeout: const Timeout(Duration(minutes: 3)));
  }

  testWidgets('soak: after $matches matches nothing is retained', (
    tester,
  ) async {
    sized(tester);
    // Leave the game (same app and scope, like going back to the menu):
    // everything from the matches must be released.
    await tester.pumpWidget(app(const SizedBox()));
    await tester.pump(const Duration(seconds: 5));
    expect(MatchController.live, 0, reason: 'controllers leaked');
    expect(BoardGame.current, isNull, reason: 'scene leaked');
    expect(backend.live, hasLength(players));

    // Churn the heap so the GC runs: finished matches' scenes must be
    // collectable (nothing keeps a reference to them).
    for (var k = 0; k < 80; k++) {
      List<List<int>>.generate(4000, (i) => List.filled(500, i)).clear();
      await tester.pump(const Duration(milliseconds: 10));
    }
    final alive = weak.where((w) => w.target != null).length;
    expect(
      alive,
      // GC timing varies; a real leak keeps every scene alive.
      lessThanOrEqualTo(8),
      reason: '$alive/$matches scenes leaked',
    );

    final base = heapAt5;
    if (vm != null && base != null) {
      final (bytes, live) = (await tester.runAsync(() => heap(tracked)))!;
      final growthMb = (bytes - base) / (1 << 20);
      if ((live['SaveService'] ?? 0) > 2) {
        await tester.runAsync(() async {
          final prof = await vm!.getAllocationProfile(iso!);
          final c = prof.members!.firstWhere(
            (c) => c.classRef!.name == 'SaveService',
          );
          final inst = await vm!.getInstances(iso!, c.classRef!.id!, 3);
          for (final o in inst.instances!) {
            final p = await vm!.getRetainingPath(iso!, o.id!, 25);
            stderr.writeln(
              'SOAKPATH ${p.elements!.map((e) => '${(e.value?.json?['class'] as Map?)?['name'] ?? e.value?.json?['type']}${e.parentField != null ? '.${e.parentField}' : ''}').join(' < ')}',
            );
          }
        });
      }
      debugPrint(
        'SOAK Dart heap after full GC: +${growthMb.toStringAsFixed(1)} MB, live $live',
      );
      // Finished matches must be collectable: Riverpod's debug devtools
      // recorder used to keep every match's container and save data.
      expect(live['SaveService'] ?? 0, lessThanOrEqualTo(2), reason: '$live');
      expect(
        live['ProviderContainer'] ?? 0,
        lessThanOrEqualTo(2),
        reason: '$live',
      );
      expect(
        live['MatchController'] ?? 0,
        lessThanOrEqualTo(1),
        reason: '$live',
      );
      // Riverpod's devtools recorder (debug) and unanswered haptics messages
      // (tests) used to add ~1.5-4 MB per match.
      expect(
        growthMb,
        lessThan(5),
        reason:
            'Dart objects grew ${growthMb.toStringAsFixed(1)} MB; '
            'top classes: $growthReport',
      );
    }

    double avg(Iterable<double> l) => l.reduce((a, b) => a + b) / l.length;
    final growth = avg(rss.skip(matches - 5)) - avg(rss.take(5));
    debugPrint('SOAK rss growth ${growth.round()} MB, scenes alive $alive');
    // Loose bound: flutter_tester's RSS also holds its software rasterizer
    // caches; object-level leaks are caught exactly above.
    expect(growth, lessThan(300), reason: 'memory grew ${growth.round()} MB');
    expect(audio.stats.played, greaterThan(1000));
  }, timeout: const Timeout(Duration(minutes: 5)));
}
