// Smoke-tests every screen and (optionally) writes screenshots:
//   flutter test test/visual/screens_test.dart --dart-define=SHOT_OUT=/tmp/shots
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:haftnard/core/ai/personality.dart';
import 'package:haftnard/core/effects/cards.dart';
import 'package:haftnard/core/rules/engine.dart';
import 'package:haftnard/core/rules/match.dart';
import 'package:haftnard/core/rules/state.dart';
import 'package:haftnard/core/rules/types.dart';
import 'package:haftnard/game/audio.dart';
import 'package:haftnard/game/layout.dart';
import 'package:haftnard/game/match_controller.dart';
import 'package:haftnard/game/scene/board_game.dart';
import 'package:haftnard/meta/meta_state.dart';
import 'package:haftnard/meta/save.dart';
import 'package:haftnard/meta/settings.dart';
import 'package:haftnard/ui/app.dart';
import 'package:haftnard/ui/game/seven_overlay.dart';
import 'package:haftnard/ui/screens/game_screen.dart';
import 'package:haftnard/ui/screens/journey_screen.dart';
import 'package:haftnard/ui/screens/locker_screen.dart';
import 'package:haftnard/ui/screens/main_menu.dart';
import 'package:haftnard/ui/screens/play_setup.dart';
import 'package:haftnard/ui/screens/profile_screen.dart';
import 'package:haftnard/ui/screens/settings_screen.dart';
import 'package:haftnard/ui/screens/store_screen.dart';

const shotDir = String.fromEnvironment('SHOT_OUT');

Future<void> loadFonts() async {
  Future<void> load(String family, List<String> files) async {
    final loader = FontLoader(family);
    for (final f in files) {
      loader.addFont(
        Future.value(ByteData.sublistView(File(f).readAsBytesSync())),
      );
    }
    await loader.load();
  }

  await load('Vazirmatn', [
    'assets/fonts/Vazirmatn-Regular.ttf',
    'assets/fonts/Vazirmatn-Bold.ttf',
  ]);
  await load('Lalezar', ['assets/fonts/Lalezar-Regular.ttf']);
  await load('Cinzel', ['assets/fonts/CinzelDecorative-Bold.ttf']);
  final flutterRoot = Platform.environment['FLUTTER_ROOT'] ?? '/root/flutter';
  final icons = File(
    '$flutterRoot/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf',
  );
  if (icons.existsSync()) await load('MaterialIcons', [icons.path]);
}

final GlobalKey _boundary = GlobalKey();

Widget harness(Widget home, {String lang = 'en', SaveService? svc}) {
  final s = svc ?? SaveService(MemorySaveStore());
  s.data.settings = Settings(language: lang, music: false, sound: false);
  return ProviderScope(
    overrides: [saveServiceProvider.overrideWithValue(s)],
    child: RepaintBoundary(
      key: _boundary,
      child: HaftNardApp(home: home),
    ),
  );
}

Future<void> shot(WidgetTester tester, String name) async {
  if (shotDir.isEmpty) return;
  await tester.runAsync(() async {
    final ro = tester.renderObject<RenderRepaintBoundary>(
      find.byKey(_boundary),
    );
    final img = await ro.toImage(pixelRatio: 1.5);
    final data = await img.toByteData(format: ui.ImageByteFormat.png);
    File('$shotDir/$name.png').writeAsBytesSync(data!.buffer.asUint8List());
  });
}

Future<void> settle(WidgetTester tester, {int frames = 30}) async {
  for (var i = 0; i < frames; i++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
}

void main() {
  setUpAll(() async {
    Sfx.instance.available = false;
    await loadFonts();
  });

  Future<void> screen(
    WidgetTester tester,
    String name,
    Widget w, {
    String lang = 'en',
    Size size = const Size(390, 844),
  }) async {
    await tester.binding.setSurfaceSize(size);
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = size;
    await tester.pumpWidget(harness(w, lang: lang));
    await settle(tester);
    expect(tester.takeException(), isNull);
    await shot(tester, name);
  }

  for (final lang in ['en', 'fa']) {
    testWidgets(
      'main menu $lang',
      (t) => screen(t, 'menu_$lang', const MainMenuScreen(), lang: lang),
    );
    testWidgets(
      'play setup $lang',
      (t) => screen(t, 'setup_$lang', const PlaySetupScreen(), lang: lang),
    );
  }
  testWidgets('store', (t) => screen(t, 'store_en', const StoreScreen()));
  testWidgets(
    'locker',
    (t) => screen(t, 'locker_fa', const LockerScreen(), lang: 'fa'),
  );
  testWidgets('profile', (t) => screen(t, 'profile_en', const ProfileScreen()));
  testWidgets(
    'settings',
    (t) => screen(t, 'settings_fa', const SettingsScreen(), lang: 'fa'),
  );
  testWidgets('journey', (t) => screen(t, 'journey_en', const JourneyScreen()));

  testWidgets('game screen vs AI', (t) async {
    final session = MatchSession(
      match: MatchState(const MatchConfig(seed: 11)),
      white: const SeatConfig.human('You'),
      black: const SeatConfig.ai(
        personalityId: 'gambler',
        difficulty: Difficulty.easy,
        name: 'Kian',
      ),
    );
    await screen(t, 'game_en', GameScreen(session: session));
    await t.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 300)),
    );
    await settle(t, frames: 20);
    await shot(t, 'game_en_2');
  });

  testWidgets('seven overlay', (t) async {
    await screen(
      t,
      'seven_fa',
      Scaffold(
        backgroundColor: Colors.black,
        body: SevenOverlay(
          offer: const [CardId.timeStop, CardId.chains, CardId.phoenix],
          picksLeft: 1,
          onPick: (_) {},
          backId: 'back_star',
          frameId: 'frame_gold',
        ),
      ),
      lang: 'fa',
    );
  });

  testWidgets('landscape game', (t) async {
    final session = MatchSession(
      match: MatchState(const MatchConfig(seed: 12, length: 3)),
      white: const SeatConfig.human('A'),
      black: const SeatConfig.human('B'),
      origin: 'passplay',
    );
    await screen(
      t,
      'game_landscape',
      GameScreen(session: session),
      size: const Size(844, 390),
    );
  });

  testWidgets('human plays a move by tapping the board', (t) async {
    final session = MatchSession(
      match: MatchState(const MatchConfig(seed: 21, mode: GameMode.classic)),
      white: const SeatConfig.human('A'),
      black: const SeatConfig.human('B'),
      origin: 'passplay',
    );
    await screen(t, 'tap_start', GameScreen(session: session));
    final game = t
        .widget<GameWidget<BoardGame>>(find.byType(GameWidget<BoardGame>))
        .game!;
    final ctrl = game.controller;
    var guard = 0;
    while (ctrl.state.phase == Phase.opening && guard++ < 10) {
      game.handleTap(game.layout.field.center);
      await settle(t, frames: 40);
    }
    expect(ctrl.state.phase, Phase.moving);
    final side = ctrl.state.current;
    final move = Engine.legalMoves(ctrl.state)
        .firstWhere((m) => m.to != Pos.off);
    final fromAbs = toAbsolute(side, move.from);
    final toAbs = toAbsolute(side, move.to);
    final n = ctrl.state.board.count(side, move.from);
    game.handleTap(game.layout.checkerCenter(PointSlot(fromAbs), n - 1, n));
    expect(game.selectedFrom, move.from);
    game.handleTap(game.layout.pointRect(toAbs).center);
    await settle(t);
    expect(ctrl.state.movesThisRoll, isNotEmpty);
    expect(ctrl.canUndo, isTrue);
    await shot(t, 'tap_after');
  });
}
