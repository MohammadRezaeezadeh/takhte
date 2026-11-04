import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:haftnard/core/ai/personality.dart';
import 'package:haftnard/game/themes/board_themes.dart';

/// Procedurally drawn character bust for AI personalities (and the player).
class AvatarPainter extends CustomPainter {
  AvatarPainter({
    required this.style,
    required this.hue,
    this.seed = 0,
    this.time = 0,
  });

  /// 'sage', 'hammer', 'builder', 'gambler', 'fox', 'player', 'boss'.
  final String style;
  final double hue;
  final int seed;
  final double time;

  Color _h(double s, double v, [double dh = 0]) =>
      HSVColor.fromAHSV(1, (hue + dh) % 360, s, v).toColor();

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.shortestSide / 2;
    canvas.save();
    canvas.clipPath(Path()..addOval(Rect.fromCircle(center: c, radius: r)));
    // Background medallion.
    canvas.drawCircle(
      c,
      r,
      Paint()
        ..shader = RadialGradient(colors: [_h(0.6, 0.45), _h(0.8, 0.15)])
            .createShader(Rect.fromCircle(center: c, radius: r)),
    );
    final star = Paint()..color = _h(0.4, 0.6).withValues(alpha: 0.25);
    BoardArt.star(canvas, c, r * 0.95, 8, star);
    // Shoulders.
    final robe = Path()
      ..moveTo(c.dx - r, c.dy + r)
      ..quadraticBezierTo(
        c.dx - r * 0.8,
        c.dy + r * 0.35,
        c.dx,
        c.dy + r * 0.32,
      )
      ..quadraticBezierTo(c.dx + r * 0.8, c.dy + r * 0.35, c.dx + r, c.dy + r)
      ..close();
    canvas.drawPath(robe, Paint()..color = _h(0.7, 0.55, 20));
    canvas.drawPath(
      Path()
        ..moveTo(c.dx - r * 0.18, c.dy + r * 0.35)
        ..lineTo(c.dx, c.dy + r)
        ..lineTo(c.dx + r * 0.18, c.dy + r * 0.35),
      Paint()
        ..color = const Color(0xFFD4AF37)
        ..style = PaintingStyle.stroke
        ..strokeWidth = r * 0.05,
    );
    // Head.
    final skin = Color.lerp(
      const Color(0xFFE0B48A),
      const Color(0xFF8C5A3A),
      (seed % 5) / 5,
    )!;
    final head = c.translate(0, -r * 0.05);
    canvas.drawOval(
      Rect.fromCenter(center: head, width: r * 0.78, height: r * 0.92),
      Paint()..color = skin,
    );
    // Eyes with a slow blink.
    final blink = (math.sin(time * 1.3 + seed) > 0.97) ? 0.15 : 1.0;
    final eye = Paint()..color = const Color(0xFF1A1110);
    for (final dx in [-0.15, 0.15]) {
      canvas.drawOval(
        Rect.fromCenter(
          center: head.translate(dx * r, -r * 0.02),
          width: r * 0.1,
          height: r * 0.11 * blink,
        ),
        eye,
      );
    }
    final brow = Paint()
      ..color = const Color(0xFF2A1A12)
      ..strokeWidth = r * 0.045
      ..strokeCap = StrokeCap.round;
    final angry = style == 'hammer' || style == 'boss';
    canvas.drawLine(
      head.translate(-r * 0.24, -r * (angry ? 0.12 : 0.14)),
      head.translate(-r * 0.07, -r * (angry ? 0.08 : 0.15)),
      brow,
    );
    canvas.drawLine(
      head.translate(r * 0.24, -r * (angry ? 0.12 : 0.14)),
      head.translate(r * 0.07, -r * (angry ? 0.08 : 0.15)),
      brow,
    );
    // Mouth / facial hair.
    final hair = Paint()..color = const Color(0xFF2A1A12);
    switch (style) {
      case 'sage':
        final beard = Path()
          ..moveTo(head.dx - r * 0.3, head.dy + r * 0.12)
          ..quadraticBezierTo(
            head.dx,
            head.dy + r * 0.85,
            head.dx + r * 0.3,
            head.dy + r * 0.12,
          )
          ..quadraticBezierTo(
            head.dx,
            head.dy + r * 0.3,
            head.dx - r * 0.3,
            head.dy + r * 0.12,
          );
        canvas.drawPath(beard, Paint()..color = const Color(0xFFE6E1D8));
      case 'hammer':
      case 'boss':
        canvas.drawPath(
          Path()
            ..moveTo(head.dx - r * 0.22, head.dy + r * 0.2)
            ..quadraticBezierTo(
              head.dx,
              head.dy + r * 0.1,
              head.dx + r * 0.22,
              head.dy + r * 0.2,
            )
            ..quadraticBezierTo(
              head.dx,
              head.dy + r * 0.16,
              head.dx - r * 0.22,
              head.dy + r * 0.2,
            ),
          hair..style = PaintingStyle.fill,
        );
      case 'gambler':
        canvas.drawArc(
          Rect.fromCenter(
            center: head.translate(0, r * 0.15),
            width: r * 0.3,
            height: r * 0.16,
          ),
          0,
          math.pi,
          false,
          Paint()
            ..color = const Color(0xFF6E1420)
            ..style = PaintingStyle.stroke
            ..strokeWidth = r * 0.04,
        );
        // Wink.
        canvas.drawLine(
          head.translate(r * 0.1, -r * 0.02),
          head.translate(r * 0.2, -r * 0.02),
          brow,
        );
      default:
        canvas.drawArc(
          Rect.fromCenter(
            center: head.translate(0, r * 0.18),
            width: r * 0.22,
            height: r * 0.1,
          ),
          0,
          math.pi,
          false,
          Paint()
            ..color = const Color(0xFF6E1420)
            ..style = PaintingStyle.stroke
            ..strokeWidth = r * 0.035,
        );
    }
    // Headwear.
    final hat = Paint()..color = _h(0.75, 0.8, -15);
    final trim = Paint()..color = const Color(0xFFD4AF37);
    switch (style) {
      case 'sage':
        // Wrapped turban.
        final t = Rect.fromCenter(
          center: head.translate(0, -r * 0.42),
          width: r * 0.95,
          height: r * 0.5,
        );
        canvas.drawOval(t, Paint()..color = const Color(0xFFF3E9D2));
        for (var i = 0; i < 3; i++) {
          canvas.drawArc(
            t.deflate(i * r * 0.04),
            math.pi * 0.1,
            math.pi * 0.8,
            false,
            Paint()
              ..color = const Color(0xFFCDBF9F)
              ..style = PaintingStyle.stroke
              ..strokeWidth = r * 0.02,
          );
        }
        canvas.drawCircle(
          head.translate(0, -r * 0.42),
          r * 0.07,
          Paint()..color = _h(0.8, 0.9),
        );
      case 'hammer':
        // Pointed helmet.
        final helm = Path()
          ..moveTo(head.dx - r * 0.42, head.dy - r * 0.18)
          ..quadraticBezierTo(
            head.dx - r * 0.4,
            head.dy - r * 0.6,
            head.dx,
            head.dy - r * 0.85,
          )
          ..quadraticBezierTo(
            head.dx + r * 0.4,
            head.dy - r * 0.6,
            head.dx + r * 0.42,
            head.dy - r * 0.18,
          )
          ..close();
        canvas.drawPath(helm, Paint()..color = const Color(0xFF9AA3AE));
        canvas.drawRect(
          Rect.fromLTWH(
            head.dx - r * 0.44,
            head.dy - r * 0.24,
            r * 0.88,
            r * 0.08,
          ),
          trim,
        );
        canvas.drawLine(
          head.translate(0, -r * 0.2),
          head.translate(0, r * 0.05),
          Paint()
            ..color = const Color(0xFF9AA3AE)
            ..strokeWidth = r * 0.06,
        );
      case 'builder':
        // Headscarf.
        final scarf = Path()
          ..moveTo(head.dx - r * 0.5, head.dy + r * 0.3)
          ..quadraticBezierTo(
            head.dx - r * 0.55,
            head.dy - r * 0.7,
            head.dx,
            head.dy - r * 0.62,
          )
          ..quadraticBezierTo(
            head.dx + r * 0.55,
            head.dy - r * 0.7,
            head.dx + r * 0.5,
            head.dy + r * 0.3,
          )
          ..lineTo(head.dx + r * 0.38, head.dy + r * 0.3)
          ..quadraticBezierTo(
            head.dx + r * 0.42,
            head.dy - r * 0.45,
            head.dx,
            head.dy - r * 0.45,
          )
          ..quadraticBezierTo(
            head.dx - r * 0.42,
            head.dy - r * 0.45,
            head.dx - r * 0.38,
            head.dy + r * 0.3,
          )
          ..close();
        canvas.drawPath(scarf, hat);
        for (var i = 0; i < 5; i++) {
          canvas.drawCircle(
            head.translate((i - 2) * r * 0.16, -r * 0.55),
            r * 0.03,
            trim,
          );
        }
      case 'gambler':
        // Cylinder cap with a tassel.
        canvas.drawRect(
          Rect.fromCenter(
            center: head.translate(0, -r * 0.48),
            width: r * 0.6,
            height: r * 0.34,
          ),
          hat,
        );
        canvas.drawRect(
          Rect.fromCenter(
            center: head.translate(0, -r * 0.33),
            width: r * 0.64,
            height: r * 0.06,
          ),
          trim,
        );
        final sway = math.sin(time * 2) * r * 0.05;
        canvas.drawLine(
          head.translate(0, -r * 0.65),
          head.translate(r * 0.32 + sway, -r * 0.45),
          Paint()
            ..color = const Color(0xFF1A1110)
            ..strokeWidth = r * 0.03,
        );
        canvas.drawCircle(
          head.translate(r * 0.32 + sway, -r * 0.42),
          r * 0.05,
          Paint()..color = const Color(0xFF1A1110),
        );
      case 'fox':
        // Hood with fox ears.
        final hood = Path()
          ..moveTo(head.dx - r * 0.5, head.dy + r * 0.35)
          ..quadraticBezierTo(
            head.dx - r * 0.6,
            head.dy - r * 0.6,
            head.dx,
            head.dy - r * 0.6,
          )
          ..quadraticBezierTo(
            head.dx + r * 0.6,
            head.dy - r * 0.6,
            head.dx + r * 0.5,
            head.dy + r * 0.35,
          )
          ..lineTo(head.dx + r * 0.38, head.dy + r * 0.35)
          ..quadraticBezierTo(
            head.dx + r * 0.42,
            head.dy - r * 0.42,
            head.dx,
            head.dy - r * 0.44,
          )
          ..quadraticBezierTo(
            head.dx - r * 0.42,
            head.dy - r * 0.42,
            head.dx - r * 0.38,
            head.dy + r * 0.35,
          )
          ..close();
        canvas.drawPath(hood, Paint()..color = const Color(0xFFC0602A));
        for (final s in [-1, 1]) {
          canvas.drawPath(
            Path()
              ..moveTo(head.dx + s * r * 0.18, head.dy - r * 0.55)
              ..lineTo(head.dx + s * r * 0.42, head.dy - r * 0.9)
              ..lineTo(head.dx + s * r * 0.45, head.dy - r * 0.45)
              ..close(),
            Paint()..color = const Color(0xFFC0602A),
          );
        }
      case 'boss':
        // Crown.
        final crown = Path()
          ..moveTo(head.dx - r * 0.38, head.dy - r * 0.3)
          ..lineTo(head.dx - r * 0.42, head.dy - r * 0.72)
          ..lineTo(head.dx - r * 0.2, head.dy - r * 0.52)
          ..lineTo(head.dx, head.dy - r * 0.82)
          ..lineTo(head.dx + r * 0.2, head.dy - r * 0.52)
          ..lineTo(head.dx + r * 0.42, head.dy - r * 0.72)
          ..lineTo(head.dx + r * 0.38, head.dy - r * 0.3)
          ..close();
        canvas.drawPath(crown, trim);
        canvas.drawCircle(
          head.translate(0, -r * 0.5),
          r * 0.06,
          Paint()..color = const Color(0xFFC2324A),
        );
      default:
        // Player: simple cap and scarf.
        canvas.drawArc(
          Rect.fromCenter(
            center: head.translate(0, -r * 0.32),
            width: r * 0.8,
            height: r * 0.5,
          ),
          math.pi,
          math.pi,
          true,
          hat,
        );
    }
    canvas.restore();
    // Ring.
    canvas.drawCircle(
      c,
      r - 1.5,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..color = const Color(0xFFD4AF37),
    );
  }

  @override
  bool shouldRepaint(covariant AvatarPainter old) =>
      old.time != time || old.style != style || old.hue != hue;
}

class Avatar extends StatelessWidget {
  const Avatar({
    required this.style,
    required this.hue,
    super.key,
    this.size = 56,
    this.seed = 0,
    this.time = 0,
  });

  factory Avatar.forPersonality(
    AiPersonality p, {
    double size = 56,
    double time = 0,
  }) => Avatar(
    style: p.id,
    hue: p.hue,
    seed: p.avatarSeed,
    size: size,
    time: time,
  );

  final String style;
  final double hue;
  final double size;
  final int seed;
  final double time;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: size,
    height: size,
    child: CustomPaint(
      painter: AvatarPainter(style: style, hue: hue, seed: seed, time: time),
    ),
  );
}
