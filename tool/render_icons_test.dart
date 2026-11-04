// Renders the launcher icon and splash logo into android/app/src/main/res.
//   flutter test tool/render_icons_test.dart
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:haftnard/game/themes/board_themes.dart';
import 'package:haftnard/game/themes/pieces.dart';

const res = 'android/app/src/main/res';

Future<void> png(
  String path,
  int size,
  void Function(Canvas, double) paint,
) async {
  final rec = ui.PictureRecorder();
  final c = Canvas(rec);
  paint(c, size.toDouble());
  final img = await rec.endRecording().toImage(size, size);
  final data = await img.toByteData(format: ui.ImageByteFormat.png);
  File(path)
    ..parent.createSync(recursive: true)
    ..writeAsBytesSync(data!.buffer.asUint8List());
}

void background(Canvas c, double s, {bool round = false}) {
  final rect = Rect.fromLTWH(0, 0, s, s);
  final paint = Paint()
    ..shader = ui.Gradient.radial(rect.center, s * 0.7, const [
      Color(0xFF2A2468),
      Color(0xFF0B0F1F),
    ]);
  if (round) {
    c.drawCircle(rect.center, s / 2, paint);
  } else {
    c.drawRRect(
      RRect.fromRectAndRadius(rect, Radius.circular(s * 0.22)),
      paint,
    );
  }
  final lattice = Paint()..color = const Color(0x18FFD36B);
  for (var i = 0; i < 8; i++) {
    final a = i * math.pi / 4;
    BoardArt.star(
      c,
      rect.center + Offset(math.cos(a), math.sin(a)) * s * 0.36,
      s * 0.06,
      8,
      lattice,
    );
  }
}

void foreground(Canvas c, double s, {double scale = 1}) {
  final ctr = Offset(s / 2, s / 2);
  BoardArt.star(
    c,
    ctr,
    s * 0.33 * scale,
    8,
    Paint()
      ..color = const Color(0xFFD4AF37)
      ..style = PaintingStyle.stroke
      ..strokeWidth = s * 0.018 * scale,
  );
  c.drawCircle(
    ctr,
    s * 0.26 * scale,
    Paint()
      ..color = const Color(0x66FFB347)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, s * 0.06 * scale),
  );
  paintDie(
    c,
    ctr,
    s * 0.38 * scale,
    7,
    kDiceStyles['dice_bone']!,
    angle: -0.12,
    time: 0.4,
  );
}

void main() {
  testWidgets('render icons', (tester) async {
    await tester.runAsync(() async {
      const dens = {
        'mdpi': 48,
        'hdpi': 72,
        'xhdpi': 96,
        'xxhdpi': 144,
        'xxxhdpi': 192,
      };
      for (final e in dens.entries) {
        await png('$res/mipmap-${e.key}/ic_launcher.png', e.value, (c, s) {
          background(c, s);
          foreground(c, s, scale: 1.25);
        });
        await png('$res/mipmap-${e.key}/ic_launcher_round.png', e.value, (
          c,
          s,
        ) {
          background(c, s, round: true);
          foreground(c, s, scale: 1.2);
        });
      }
      // Adaptive icon foreground (108dp canvas, content in the 66% safe zone).
      await png(
        '$res/drawable-nodpi/ic_launcher_foreground.png',
        432,
        (c, s) => foreground(c, s, scale: 0.92),
      );
      // Splash logo.
      await png(
        '$res/drawable-nodpi/splash_logo.png',
        288,
        (c, s) => foreground(c, s, scale: 1.2),
      );
    });
  });
}
