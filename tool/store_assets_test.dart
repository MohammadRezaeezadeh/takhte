// Renders the store listing graphics into docs/store/:
//   flutter test tool/store_assets_test.dart
// * icon-512.png (Play Store icon), feature-graphic.png (1024×500)
// * screenshots/*.png — Persian phone screenshots at 1080×2160 (2:1).
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:haftnard/core/ai/personality.dart';
import 'package:haftnard/core/effects/cards.dart';
import 'package:haftnard/core/rules/match.dart';
import 'package:haftnard/game/audio.dart';
import 'package:haftnard/game/match_controller.dart';
import 'package:haftnard/game/scene/board_game.dart';
import 'package:haftnard/game/themes/board_themes.dart';
import 'package:haftnard/game/themes/pieces.dart';
import 'package:haftnard/meta/meta_state.dart';
import 'package:haftnard/meta/save.dart';
import 'package:haftnard/meta/settings.dart';
import 'package:haftnard/ui/app.dart';
import 'package:haftnard/ui/game/seven_overlay.dart';
import 'package:haftnard/ui/screens/codex_screen.dart';
import 'package:haftnard/ui/screens/game_screen.dart';
import 'package:haftnard/ui/screens/journey_screen.dart';
import 'package:haftnard/ui/screens/main_menu.dart';
import 'package:haftnard/ui/screens/play_setup.dart';

import '../test/visual/screens_test.dart' show loadFonts;
import 'render_icons_test.dart' show background, foreground;

const out = 'docs/store';
final GlobalKey _boundary = GlobalKey();

Future<void> _save(ui.Image img, String path) async {
  final data = await img.toByteData(format: ui.ImageByteFormat.png);
  File(path)
    ..parent.createSync(recursive: true)
    ..writeAsBytesSync(data!.buffer.asUint8List());
}

Future<void> _canvas(
  String path,
  int w,
  int h,
  void Function(Canvas c, Size s) paint,
) async {
  final rec = ui.PictureRecorder();
  paint(Canvas(rec), Size(w.toDouble(), h.toDouble()));
  await _save(await rec.endRecording().toImage(w, h), path);
}

void _text(
  Canvas c,
  String s,
  Offset center,
  double size,
  Color color, {
  String family = 'Lalezar',
}) {
  final tp = TextPainter(
    text: TextSpan(
      text: s,
      style: TextStyle(
        fontFamily: family,
        fontSize: size,
        color: color,
        shadows: const [Shadow(color: Color(0xAA000000), blurRadius: 12)],
      ),
    ),
    textDirection: TextDirection.rtl,
  )..layout();
  tp.paint(c, center - Offset(tp.width / 2, tp.height / 2));
}

void _feature(Canvas c, Size s) {
  final rect = Offset.zero & s;
  c.drawRect(
    rect,
    Paint()
      ..shader = ui.Gradient.radial(
        Offset(s.width * 0.3, s.height * 0.5),
        s.width * 0.75,
        const [Color(0xFF2A2468), Color(0xFF0B0F1F)],
      ),
  );
  final lattice = Paint()..color = const Color(0x14FFD36B);
  for (var x = 0; x < 9; x++) {
    for (var y = 0; y < 5; y++) {
      BoardArt.star(
        c,
        Offset(x * 128.0 + (y.isOdd ? 64 : 0), y * 120.0 + 20),
        26,
        8,
        lattice,
      );
    }
  }
  // Two glowing 7–7 dice on the left.
  final dice = Offset(s.width * 0.25, s.height * 0.52);
  c.drawCircle(
    dice,
    170,
    Paint()
      ..color = const Color(0x55FFB347)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 60),
  );
  final style = kDiceStyles['dice_bone']!;
  paintDie(c, dice.translate(-70, 10), 120, 7, style, angle: -0.2, time: 0.4);
  paintDie(c, dice.translate(75, -20), 120, 7, style, angle: 0.15, time: 0.4);
  // Title.
  _text(
    c,
    'هفت‌نرد',
    Offset(s.width * 0.7, s.height * 0.4),
    120,
    const Color(0xFFFFD36B),
  );
  _text(
    c,
    'تخته‌نرد با کارت‌های جادویی',
    Offset(s.width * 0.7, s.height * 0.68),
    40,
    const Color(0xFFF3E9D2),
    family: 'Vazirmatn',
  );
}

Widget _app(Widget home, SaveService svc) => ProviderScope(
  overrides: [saveServiceProvider.overrideWithValue(svc)],
  child: RepaintBoundary(
    key: _boundary,
    child: HaftNardApp(home: home),
  ),
);

SaveService _svc() => SaveService(MemorySaveStore())
  ..data.settings = const Settings(
    sound: false,
    music: false,
    tutorialDone: true,
    sevenGuideDone: true,
  );

Future<void> _shot(WidgetTester t, String name) async {
  await t.runAsync(() async {
    final ro = t.renderObject<RenderRepaintBoundary>(find.byKey(_boundary));
    await _save(
      await ro.toImage(pixelRatio: 2.7),
      '$out/screenshots/$name.png',
    );
  });
}

Future<void> _settle(WidgetTester t, {int frames = 30}) async {
  for (var i = 0; i < frames; i++) {
    await t.pump(const Duration(milliseconds: 50));
  }
}

void main() {
  setUpAll(() async {
    Sfx.instance.available = false;
    SevenOverlay.useSensors = false;
    kAiUseIsolates = false;
    await loadFonts();
  });

  Future<void> phone(WidgetTester t) async {
    const size = Size(400, 800);
    await t.binding.setSurfaceSize(size);
    t.view.devicePixelRatio = 1;
    t.view.physicalSize = size;
  }

  testWidgets('icon and feature graphic', (t) async {
    await t.runAsync(() async {
      await _canvas('$out/icon-512.png', 512, 512, (c, s) {
        c.drawRect(Offset.zero & s, Paint()..color = const Color(0xFF0B0F1F));
        background(c, s.width);
        foreground(c, s.width, scale: 1.25);
      });
      await _canvas('$out/feature-graphic.png', 1024, 500, _feature);
    });
  });

  testWidgets('menu', (t) async {
    await phone(t);
    await t.pumpWidget(_app(const MainMenuScreen(), _svc()));
    await _settle(t);
    await _shot(t, '1-menu');
  });

  testWidgets('game', (t) async {
    await phone(t);
    final session = MatchSession(
      match: MatchState(const MatchConfig(seed: 31, p7: 0.25)),
      white: const SeatConfig.ai(
        personalityId: 'hammer',
        difficulty: Difficulty.medium,
        name: 'آرش',
      ),
      black: const SeatConfig.ai(
        personalityId: 'fox',
        difficulty: Difficulty.medium,
        name: 'روباه',
      ),
    );
    await t.pumpWidget(_app(GameScreen(session: session), _svc()));
    await t.runAsync(() => Future<void>.delayed(const Duration(seconds: 1)));
    // Play until a few powers are on the board.
    for (var i = 0; i < 1500; i++) {
      await t.pump(const Duration(milliseconds: 60));
      final g = BoardGame.current;
      if (g != null &&
          g.isLoaded &&
          // A tool, not a test: reads the power layer's debug list.
          // ignore: invalid_use_of_visible_for_testing_member
          g.power.debugDrawn.length >= 2 &&
          !g.controller.busy) {
        break;
      }
    }
    await _settle(t, frames: 20);
    await _shot(t, '2-game');
    await t.pumpWidget(const SizedBox());
    await t.pump(const Duration(seconds: 10));
  });

  testWidgets('7–7 card choice', (t) async {
    await phone(t);
    await t.pumpWidget(
      _app(
        Scaffold(
          backgroundColor: const Color(0xFF0B0F1F),
          body: SevenOverlay(
            offer: const [CardId.timeStop, CardId.fog, CardId.phoenix],
            picksLeft: 1,
            onPick: (_) {},
            backId: 'back_star',
            frameId: 'frame_gold',
          ),
        ),
        _svc(),
      ),
    );
    await _settle(t, frames: 60);
    await _shot(t, '3-seven');
  });

  testWidgets('setup', (t) async {
    await phone(t);
    await t.pumpWidget(_app(const PlaySetupScreen(), _svc()));
    await _settle(t);
    await _shot(t, '4-setup');
  });

  testWidgets('journey', (t) async {
    await phone(t);
    await t.pumpWidget(_app(const JourneyScreen(), _svc()));
    await _settle(t);
    await _shot(t, '5-journey');
  });

  testWidgets('codex', (t) async {
    await phone(t);
    await t.pumpWidget(_app(const CodexScreen(), _svc()));
    await _settle(t);
    await _shot(t, '6-codex');
  });
}
