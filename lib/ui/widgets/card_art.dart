import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:haftnard/core/effects/cards.dart';
import 'package:haftnard/game/themes/board_themes.dart';
import 'package:haftnard/game/themes/pieces.dart';
import 'package:haftnard/ui/theme.dart';

/// Procedural icon for each card (by [CardDef.glyph]).
class CardGlyphPainter extends CustomPainter {
  CardGlyphPainter(this.glyph, this.color, {this.time = 0});
  final int glyph;
  final Color color;
  final double time;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.shortestSide * 0.38;
    final fill = Paint()..color = color;
    final stroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = r * 0.1
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final dim = Paint()..color = color.withValues(alpha: 0.35);
    final bone = kDiceStyles['dice_bone']!;
    switch (glyph) {
      case 0: // Loaded Hand: three dice fanned
        for (var i = -1; i <= 1; i++) {
          paintDie(
            canvas,
            c.translate(i * r * 0.6, i.abs() * r * 0.15),
            r * 0.75,
            4 + i,
            bone,
            angle: i * 0.3,
          );
        }
      case 1: // Double Down: two stacked dice
        paintDie(
          canvas,
          c.translate(-r * 0.3, -r * 0.3),
          r * 0.8,
          6,
          bone,
          angle: -0.2,
        );
        paintDie(
          canvas,
          c.translate(r * 0.3, r * 0.3),
          r * 0.8,
          6,
          bone,
          angle: 0.15,
        );
      case 2: // Fate's Edit: die with a quill
        paintDie(canvas, c.translate(-r * 0.2, r * 0.15), r * 0.9, 3, bone);
        canvas.drawLine(
          c.translate(r * 0.9, -r),
          c.translate(r * 0.1, r * 0.1),
          stroke,
        );
        canvas.drawPath(
          Path()
            ..moveTo(c.dx + r * 0.9, c.dy - r)
            ..quadraticBezierTo(
              c.dx + r * 0.2,
              c.dy - r * 0.9,
              c.dx + r * 0.35,
              c.dy - r * 0.1,
            )
            ..close(),
          fill,
        );
      case 3: // Second Chance: circular arrow
        final rect = Rect.fromCircle(center: c, radius: r * 0.75);
        canvas.drawArc(rect, -math.pi * 0.3, math.pi * 1.6, false, stroke);
        final tip =
            c +
            Offset(math.cos(-math.pi * 0.3), math.sin(-math.pi * 0.3)) *
                r *
                0.75;
        canvas.drawPath(
          Path()
            ..moveTo(tip.dx + r * 0.3, tip.dy)
            ..lineTo(tip.dx - r * 0.1, tip.dy - r * 0.35)
            ..lineTo(tip.dx - r * 0.15, tip.dy + r * 0.2)
            ..close(),
          fill,
        );
      case 4: // Lucky Charm: eye amulet (nazar)
        canvas.drawOval(
          Rect.fromCenter(center: c, width: r * 2, height: r * 1.2),
          fill,
        );
        canvas.drawCircle(
          c,
          r * 0.45,
          Paint()..color = const Color(0xFFF3E9D2),
        );
        canvas.drawCircle(c, r * 0.3, Paint()..color = const Color(0xFF1B6FD6));
        canvas.drawCircle(c, r * 0.13, Paint()..color = Colors.black);
      case 5: // Seven Magnet
        final arc = Path()
          ..addArc(
            Rect.fromCircle(center: c.translate(0, -r * 0.1), radius: r * 0.7),
            math.pi,
            math.pi,
          );
        canvas.drawPath(arc, stroke..strokeWidth = r * 0.3);
        canvas.drawRect(
          Rect.fromLTWH(c.dx - r * 0.85, c.dy - r * 0.1, r * 0.3, r * 0.5),
          Paint()..color = AppColors.ruby,
        );
        canvas.drawRect(
          Rect.fromLTWH(c.dx + r * 0.55, c.dy - r * 0.1, r * 0.3, r * 0.5),
          Paint()..color = AppColors.ruby,
        );
        _text(canvas, '7', c.translate(0, r * 0.65), r * 0.8, color);
      case 6: // Broken Die
        paintDie(
          canvas,
          c.translate(-r * 0.15, 0),
          r * 1.1,
          5,
          bone,
          angle: -0.1,
        );
        canvas.drawPath(
          Path()
            ..moveTo(c.dx - r * 0.1, c.dy - r * 0.7)
            ..lineTo(c.dx + r * 0.1, c.dy - r * 0.2)
            ..lineTo(c.dx - r * 0.15, c.dy + r * 0.1)
            ..lineTo(c.dx + r * 0.1, c.dy + r * 0.7),
          Paint()
            ..color = Colors.black
            ..style = PaintingStyle.stroke
            ..strokeWidth = r * 0.12,
        );
      case 7: // Chains
        for (var i = -1; i <= 1; i++) {
          canvas.save();
          canvas.translate(c.dx + i * r * 0.62, c.dy);
          canvas.rotate(i.isEven ? 0 : math.pi / 2);
          canvas.drawOval(
            Rect.fromCenter(
              center: Offset.zero,
              width: r * 0.9,
              height: r * 0.55,
            ),
            stroke,
          );
          canvas.restore();
        }
      case 8: // Fog
        for (var i = 0; i < 3; i++) {
          canvas.drawOval(
            Rect.fromCenter(
              center: c.translate(
                (i - 1) * r * 0.55,
                (i == 1 ? -r * 0.2 : r * 0.1),
              ),
              width: r * 1.1,
              height: r * 0.8,
            ),
            Paint()..color = color.withValues(alpha: 0.75),
          );
        }
        for (var i = 0; i < 3; i++) {
          canvas.drawLine(
            c.translate(-r * 0.8, r * (0.55 + i * 0.2)),
            c.translate(r * 0.8, r * (0.55 + i * 0.2)),
            Paint()
              ..color = dim.color
              ..strokeWidth = r * 0.08,
          );
        }
      case 9: // Curse of Small Numbers: big 4 with a down arrow
        _text(canvas, '4', c.translate(-r * 0.25, 0), r * 1.6, color);
        canvas.drawLine(
          c.translate(r * 0.6, -r * 0.6),
          c.translate(r * 0.6, r * 0.5),
          stroke,
        );
        canvas.drawPath(
          Path()
            ..moveTo(c.dx + r * 0.35, c.dy + r * 0.25)
            ..lineTo(c.dx + r * 0.6, c.dy + r * 0.7)
            ..lineTo(c.dx + r * 0.85, c.dy + r * 0.25)
            ..close(),
          fill,
        );
      case 10: // Mirror
        canvas.drawOval(
          Rect.fromCenter(
            center: c.translate(0, -r * 0.15),
            width: r * 1.3,
            height: r * 1.6,
          ),
          stroke,
        );
        canvas.drawOval(
          Rect.fromCenter(
            center: c.translate(0, -r * 0.15),
            width: r * 1.1,
            height: r * 1.4,
          ),
          Paint()
            ..shader = ui.Gradient.linear(
              c.translate(-r, -r),
              c.translate(r, r),
              [const Color(0xFFBFE6F5), const Color(0xFF5E7FA0)],
            ),
        );
        canvas.drawLine(
          c.translate(0, r * 0.65),
          c.translate(0, r * 1.0),
          stroke,
        );
        canvas.drawLine(
          c.translate(-r * 0.3, -r * 0.5),
          c.translate(r * 0.05, -r * 0.8),
          Paint()
            ..color = Colors.white70
            ..strokeWidth = r * 0.08,
        );
      case 11: // Thief: mask
        final mask = Path()
          ..moveTo(c.dx - r, c.dy - r * 0.2)
          ..quadraticBezierTo(c.dx, c.dy - r * 0.6, c.dx + r, c.dy - r * 0.2)
          ..quadraticBezierTo(
            c.dx + r * 0.9,
            c.dy + r * 0.45,
            c.dx + r * 0.2,
            c.dy + r * 0.25,
          )
          ..quadraticBezierTo(
            c.dx,
            c.dy + r * 0.05,
            c.dx - r * 0.2,
            c.dy + r * 0.25,
          )
          ..quadraticBezierTo(
            c.dx - r * 0.9,
            c.dy + r * 0.45,
            c.dx - r,
            c.dy - r * 0.2,
          )
          ..close();
        canvas.drawPath(mask, fill);
        canvas.drawOval(
          Rect.fromCenter(
            center: c.translate(-r * 0.45, -r * 0.05),
            width: r * 0.45,
            height: r * 0.25,
          ),
          Paint()..color = Colors.black,
        );
        canvas.drawOval(
          Rect.fromCenter(
            center: c.translate(r * 0.45, -r * 0.05),
            width: r * 0.45,
            height: r * 0.25,
          ),
          Paint()..color = Colors.black,
        );
      case 12: // Holy Shield
        final sh = Path()
          ..moveTo(c.dx, c.dy - r)
          ..lineTo(c.dx + r * 0.85, c.dy - r * 0.6)
          ..quadraticBezierTo(c.dx + r * 0.8, c.dy + r * 0.5, c.dx, c.dy + r)
          ..quadraticBezierTo(
            c.dx - r * 0.8,
            c.dy + r * 0.5,
            c.dx - r * 0.85,
            c.dy - r * 0.6,
          )
          ..close();
        canvas.drawPath(sh, fill);
        BoardArt.star(
          canvas,
          c.translate(0, -r * 0.05),
          r * 0.45,
          8,
          Paint()..color = Colors.white.withValues(alpha: 0.85),
        );
      case 13: // Iron Gate: portcullis
        final gate = Rect.fromCenter(
          center: c,
          width: r * 1.6,
          height: r * 1.8,
        );
        canvas.drawRRect(
          RRect.fromRectAndCorners(
            gate,
            topLeft: Radius.circular(r * 0.8),
            topRight: Radius.circular(r * 0.8),
          ),
          stroke,
        );
        for (var i = -2; i <= 2; i++) {
          canvas.drawLine(
            c.translate(i * r * 0.3, -r * 0.6),
            c.translate(i * r * 0.3, r * 0.9),
            stroke..strokeWidth = r * 0.08,
          );
        }
        canvas.drawLine(
          c.translate(-r * 0.75, r * 0.1),
          c.translate(r * 0.75, r * 0.1),
          stroke,
        );
      case 14: // Ghost Step: wisp
        final g = Path()
          ..moveTo(c.dx - r * 0.6, c.dy + r * 0.8)
          ..lineTo(c.dx - r * 0.6, c.dy - r * 0.1)
          ..quadraticBezierTo(
            c.dx - r * 0.6,
            c.dy - r * 0.9,
            c.dx,
            c.dy - r * 0.9,
          )
          ..quadraticBezierTo(
            c.dx + r * 0.6,
            c.dy - r * 0.9,
            c.dx + r * 0.6,
            c.dy - r * 0.1,
          )
          ..lineTo(c.dx + r * 0.6, c.dy + r * 0.8)
          ..lineTo(c.dx + r * 0.3, c.dy + r * 0.55)
          ..lineTo(c.dx, c.dy + r * 0.8)
          ..lineTo(c.dx - r * 0.3, c.dy + r * 0.55)
          ..close();
        canvas.drawPath(g, Paint()..color = color.withValues(alpha: 0.85));
        canvas.drawCircle(
          c.translate(-r * 0.22, -r * 0.25),
          r * 0.12,
          Paint()..color = Colors.black,
        );
        canvas.drawCircle(
          c.translate(r * 0.22, -r * 0.25),
          r * 0.12,
          Paint()..color = Colors.black,
        );
      case 15: // Phoenix
        final wing = Path()
          ..moveTo(c.dx, c.dy + r * 0.2)
          ..quadraticBezierTo(
            c.dx - r * 1.1,
            c.dy - r * 0.2,
            c.dx - r,
            c.dy - r,
          )
          ..quadraticBezierTo(
            c.dx - r * 0.4,
            c.dy - r * 0.3,
            c.dx,
            c.dy - r * 0.2,
          )
          ..quadraticBezierTo(
            c.dx + r * 0.4,
            c.dy - r * 0.3,
            c.dx + r,
            c.dy - r,
          )
          ..quadraticBezierTo(
            c.dx + r * 1.1,
            c.dy - r * 0.2,
            c.dx,
            c.dy + r * 0.2,
          )
          ..close();
        canvas.drawPath(
          wing,
          Paint()
            ..shader = ui.Gradient.linear(
              c.translate(0, -r),
              c.translate(0, r),
              const [Color(0xFFFFD36B), Color(0xFFFF5A1A)],
            ),
        );
        final tail = Path()
          ..moveTo(c.dx - r * 0.2, c.dy + r * 0.1)
          ..quadraticBezierTo(
            c.dx,
            c.dy + r * 1.2,
            c.dx + r * 0.2,
            c.dy + r * 0.1,
          )
          ..close();
        canvas.drawPath(tail, Paint()..color = const Color(0xFFFF7A1A));
      case 16: // Teleport: spiral portal
        final sp = Path();
        for (var i = 0; i <= 60; i++) {
          final a = i / 60 * math.pi * 5 + time;
          final rr = r * i / 60;
          final p = c + Offset(math.cos(a), math.sin(a)) * rr;
          if (i == 0) {
            sp.moveTo(p.dx, p.dy);
          } else {
            sp.lineTo(p.dx, p.dy);
          }
        }
        canvas.drawPath(sp, stroke..strokeWidth = r * 0.09);
      case 17: // Landmine
        canvas.drawCircle(c, r * 0.6, Paint()..color = const Color(0xFF2A2A2A));
        for (var i = 0; i < 8; i++) {
          final a = i * math.pi / 4;
          canvas.drawLine(
            c,
            c + Offset(math.cos(a), math.sin(a)) * r * 0.95,
            Paint()
              ..color = const Color(0xFF2A2A2A)
              ..strokeWidth = r * 0.15,
          );
        }
        canvas.drawCircle(
          c.translate(-r * 0.2, -r * 0.2),
          r * 0.15,
          Paint()..color = AppColors.ruby,
        );
      case 18: // Quicksand swirl
        final q = Path();
        for (var i = 0; i <= 50; i++) {
          final a = i / 50 * math.pi * 4;
          final rr = r * (1 - i / 50);
          final p = c + Offset(math.cos(a) * rr, math.sin(a) * rr * 0.6);
          if (i == 0) {
            q.moveTo(p.dx, p.dy);
          } else {
            q.lineTo(p.dx, p.dy);
          }
        }
        canvas.drawPath(q, stroke);
      case 19: // Toll Gate: coin on a barrier
        canvas.drawLine(
          c.translate(-r, r * 0.3),
          c.translate(r, r * 0.3),
          stroke..strokeWidth = r * 0.18,
        );
        canvas.drawLine(
          c.translate(-r * 0.8, r * 0.3),
          c.translate(-r * 0.8, r),
          stroke,
        );
        canvas.drawCircle(
          c.translate(0, -r * 0.35),
          r * 0.45,
          Paint()..color = AppColors.goldLight,
        );
        canvas.drawCircle(
          c.translate(0, -r * 0.35),
          r * 0.45,
          Paint()
            ..color = const Color(0xFF8C6418)
            ..style = PaintingStyle.stroke
            ..strokeWidth = r * 0.07,
        );
      case 20: // Time Stop: hourglass
        final hg = Path()
          ..moveTo(c.dx - r * 0.6, c.dy - r)
          ..lineTo(c.dx + r * 0.6, c.dy - r)
          ..lineTo(c.dx + r * 0.08, c.dy)
          ..lineTo(c.dx + r * 0.6, c.dy + r)
          ..lineTo(c.dx - r * 0.6, c.dy + r)
          ..lineTo(c.dx - r * 0.08, c.dy)
          ..close();
        canvas.drawPath(hg, stroke);
        canvas.drawPath(
          Path()
            ..moveTo(c.dx - r * 0.35, c.dy + r * 0.85)
            ..lineTo(c.dx + r * 0.35, c.dy + r * 0.85)
            ..lineTo(c.dx, c.dy + r * 0.35)
            ..close(),
          fill,
        );
      case 21: // Blood Pact: drop
        final drop = Path()
          ..moveTo(c.dx, c.dy - r)
          ..quadraticBezierTo(
            c.dx + r * 0.8,
            c.dy + r * 0.1,
            c.dx + r * 0.55,
            c.dy + r * 0.55,
          )
          ..arcToPoint(
            c.translate(-r * 0.55, r * 0.55),
            radius: Radius.circular(r * 0.6),
          )
          ..quadraticBezierTo(c.dx - r * 0.8, c.dy + r * 0.1, c.dx, c.dy - r)
          ..close();
        canvas.drawPath(drop, Paint()..color = const Color(0xFFC2324A));
        canvas.drawCircle(
          c.translate(-r * 0.2, r * 0.2),
          r * 0.12,
          Paint()..color = Colors.white54,
        );
      case 22: // Gambler's Coin
        canvas.save();
        canvas.translate(c.dx, c.dy);
        canvas.scale(0.55 + 0.45 * math.cos(time * 2).abs(), 1);
        canvas.drawCircle(
          Offset.zero,
          r * 0.85,
          Paint()..color = AppColors.goldLight,
        );
        canvas.drawCircle(
          Offset.zero,
          r * 0.65,
          Paint()
            ..color = const Color(0xFFB8861C)
            ..style = PaintingStyle.stroke
            ..strokeWidth = r * 0.08,
        );
        BoardArt.star(
          canvas,
          Offset.zero,
          r * 0.4,
          6,
          Paint()..color = const Color(0xFFB8861C),
        );
        canvas.restore();
      default: // Greed: coin sack
        final sack = Path()
          ..moveTo(c.dx - r * 0.3, c.dy - r * 0.55)
          ..quadraticBezierTo(
            c.dx - r,
            c.dy + r * 0.2,
            c.dx - r * 0.6,
            c.dy + r * 0.9,
          )
          ..lineTo(c.dx + r * 0.6, c.dy + r * 0.9)
          ..quadraticBezierTo(
            c.dx + r,
            c.dy + r * 0.2,
            c.dx + r * 0.3,
            c.dy - r * 0.55,
          )
          ..close();
        canvas.drawPath(sack, Paint()..color = const Color(0xFF8C6A48));
        canvas.drawLine(
          c.translate(-r * 0.35, -r * 0.55),
          c.translate(r * 0.35, -r * 0.55),
          stroke,
        );
        canvas.drawCircle(
          c.translate(0, r * 0.3),
          r * 0.3,
          Paint()..color = AppColors.goldLight,
        );
    }
  }

  void _text(Canvas canvas, String t, Offset at, double size, Color color) {
    final tp = TextPainter(
      text: TextSpan(
        text: t,
        style: TextStyle(
          fontFamily: AppFonts.display,
          fontSize: size,
          color: color,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, at - Offset(tp.width / 2, tp.height / 2));
  }

  @override
  bool shouldRepaint(covariant CardGlyphPainter old) =>
      old.glyph != glyph || old.time != time || old.color != color;
}

/// Card back patterns.
class CardBackPainter extends CustomPainter {
  CardBackPainter(this.backId);
  final String backId;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final (a, b, ink) = switch (backId) {
      'back_boteh' => (
        const Color(0xFF7A1F2B),
        const Color(0xFF3A0E15),
        const Color(0xFFE9C25A),
      ),
      'back_peacock' => (
        const Color(0xFF0E6B6B),
        const Color(0xFF06343A),
        const Color(0xFF6CF2FF),
      ),
      'back_simorgh' => (
        const Color(0xFF3B1C6E),
        const Color(0xFF120A2E),
        const Color(0xFFFFD36B),
      ),
      _ => (
        const Color(0xFF1B2A6B),
        const Color(0xFF0B1238),
        const Color(0xFFD4AF37),
      ),
    };
    canvas.drawRect(
      rect,
      Paint()
        ..shader = ui.Gradient.radial(rect.center, size.longestSide * 0.7, [
          a,
          b,
        ]),
    );
    final p = Paint()..color = ink.withValues(alpha: 0.85);
    final thin = Paint()
      ..color = ink.withValues(alpha: 0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    switch (backId) {
      case 'back_boteh':
        for (var y = 14.0; y < size.height; y += 28) {
          for (
            var x = 14.0 + ((y ~/ 28).isOdd ? 14 : 0);
            x < size.width;
            x += 28
          ) {
            _boteh(canvas, Offset(x, y), 9, p);
          }
        }
      case 'back_peacock':
        for (var i = 0; i < 9; i++) {
          final a0 = math.pi + i * math.pi / 8;
          final end =
              Offset(size.width / 2, size.height * 0.85) +
              Offset(math.cos(a0), math.sin(a0)) * size.height * 0.6;
          canvas.drawLine(
            Offset(size.width / 2, size.height * 0.85),
            end,
            thin,
          );
          canvas.drawOval(
            Rect.fromCenter(center: end, width: 14, height: 18),
            p,
          );
          canvas.drawCircle(end, 4, Paint()..color = const Color(0xFF1B2A6B));
        }
      case 'back_simorgh':
        for (var i = 0; i < 7; i++) {
          final y = size.height * (0.2 + i * 0.1);
          final path = Path()
            ..moveTo(size.width * 0.5, y)
            ..quadraticBezierTo(
              size.width * 0.15,
              y - 20,
              size.width * 0.05,
              y + 12,
            )
            ..moveTo(size.width * 0.5, y)
            ..quadraticBezierTo(
              size.width * 0.85,
              y - 20,
              size.width * 0.95,
              y + 12,
            );
          canvas.drawPath(path, thin..strokeWidth = 2);
        }
        BoardArt.star(canvas, rect.center, size.width * 0.12, 8, p);
      default:
        const s = 22.0;
        for (var y = 0.0; y < size.height + s; y += s) {
          for (var x = 0.0; x < size.width + s; x += s) {
            BoardArt.star(
              canvas,
              Offset(x, y),
              s * 0.36,
              8,
              thin
                ..style = PaintingStyle.fill
                ..color = ink.withValues(alpha: 0.25),
            );
          }
        }
        BoardArt.star(canvas, rect.center, size.width * 0.22, 8, p);
        canvas.drawCircle(rect.center, size.width * 0.09, Paint()..color = b);
        _seven(canvas, rect.center, size.width * 0.1, ink);
    }
    canvas.drawRect(
      rect.deflate(5),
      thin
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..color = ink,
    );
  }

  void _boteh(Canvas c, Offset o, double r, Paint p) {
    final path = Path()
      ..moveTo(o.dx, o.dy - r)
      ..quadraticBezierTo(
        o.dx + r * 1.2,
        o.dy - r * 0.2,
        o.dx + r * 0.2,
        o.dy + r,
      )
      ..quadraticBezierTo(
        o.dx - r,
        o.dy + r * 0.6,
        o.dx - r * 0.3,
        o.dy - r * 0.2,
      )
      ..quadraticBezierTo(o.dx - r * 0.1, o.dy - r * 0.6, o.dx, o.dy - r)
      ..close();
    c.drawPath(path, p);
  }

  void _seven(Canvas c, Offset o, double r, Color col) {
    final tp = TextPainter(
      text: TextSpan(
        text: '۷',
        style: TextStyle(
          fontFamily: AppFonts.display,
          fontSize: r * 1.8,
          color: col,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(c, o - Offset(tp.width / 2, tp.height / 2));
  }

  @override
  bool shouldRepaint(covariant CardBackPainter old) => old.backId != backId;
}

/// A full card face.
class CardFace extends StatelessWidget {
  const CardFace({
    required this.card,
    required this.lang,
    super.key,
    this.frameId = 'frame_gold',
    this.width = 150,
    this.time = 0,
    this.shine = 0,
    this.compact = false,
  });

  final CardDef card;
  final String lang;
  final String frameId;
  final double width;
  final double time;

  /// -1..1 horizontal tilt for the moving sheen.
  final double shine;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final h = width * 1.45;
    final rc = AppColors.rarity(card.rarity.index);
    final frame = switch (frameId) {
      'frame_silver' => const [Color(0xFFE8E8EE), Color(0xFF8A8A98)],
      'frame_enamel' => const [Color(0xFF34C3C3), Color(0xFF1B2A6B)],
      _ => const [Color(0xFFFFE08A), Color(0xFFB8861C)],
    };
    final legendary = card.rarity == Rarity.legendary;
    return Container(
      width: width,
      height: h,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(width * 0.08),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: frame,
        ),
        boxShadow: [
          BoxShadow(
            color: rc.withValues(
              alpha: legendary ? 0.55 + 0.25 * math.sin(time * 3) : 0.45,
            ),
            blurRadius: legendary ? 28 : 18,
            spreadRadius: 1,
          ),
          const BoxShadow(
            color: Colors.black54,
            blurRadius: 10,
            offset: Offset(0, 6),
          ),
        ],
      ),
      padding: EdgeInsets.all(width * 0.035),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(width * 0.06),
        child: Stack(
          children: [
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color.lerp(AppColors.ink, rc, 0.18)!,
                      AppColors.night,
                    ],
                  ),
                ),
              ),
            ),
            Column(
              children: [
                SizedBox(height: width * 0.05),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: width * 0.05),
                  child: Text(
                    card.name(lang),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: AppFonts.display,
                      fontSize: width * 0.12,
                      color: rc,
                      height: 1.1,
                    ),
                  ),
                ),
                Expanded(
                  flex: 5,
                  child: Container(
                    margin: EdgeInsets.symmetric(
                      horizontal: width * 0.08,
                      vertical: width * 0.03,
                    ),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          rc.withValues(alpha: 0.25),
                          Colors.transparent,
                        ],
                      ),
                    ),
                    child: CustomPaint(
                      painter: CardGlyphPainter(card.glyph, rc, time: time),
                      size: Size.infinite,
                    ),
                  ),
                ),
                if (!compact)
                  Expanded(
                    flex: 4,
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: width * 0.06),
                      child: SingleChildScrollView(
                        physics: const NeverScrollableScrollPhysics(),
                        child: Column(
                          children: [
                            Text(
                              card.desc(lang),
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: width * 0.073,
                                color: AppColors.ivory,
                                height: 1.35,
                              ),
                            ),
                            if (card.drawback(lang) != null) ...[
                              SizedBox(height: width * 0.02),
                              Text(
                                card.drawback(lang)!,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: width * 0.066,
                                  color: const Color(0xFFFF8A8A),
                                  height: 1.3,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.symmetric(vertical: width * 0.015),
                  color: rc.withValues(alpha: 0.2),
                  child: Text(
                    _rarityLabel(card.rarity, lang),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: width * 0.065,
                      color: rc,
                      letterSpacing: lang == 'fa' ? 0 : 2,
                    ),
                  ),
                ),
              ],
            ),
            // Moving sheen.
            Positioned.fill(
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment(-1.5 + shine, -1),
                      end: Alignment(1.5 + shine, 1),
                      colors: [
                        Colors.transparent,
                        Colors.white.withValues(alpha: legendary ? 0.22 : 0.12),
                        Colors.transparent,
                      ],
                      stops: const [0.35, 0.5, 0.65],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _rarityLabel(Rarity r, String lang) =>
      switch ((r, lang == 'fa')) {
        (Rarity.common, true) => 'معمولی',
        (Rarity.rare, true) => 'کمیاب',
        (Rarity.epic, true) => 'حماسی',
        (Rarity.legendary, true) => 'افسانه‌ای',
        (Rarity.common, false) => 'COMMON',
        (Rarity.rare, false) => 'RARE',
        (Rarity.epic, false) => 'EPIC',
        (Rarity.legendary, false) => 'LEGENDARY',
      };
}

class CardBack extends StatelessWidget {
  const CardBack({required this.backId, super.key, this.width = 150});
  final String backId;
  final double width;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: width * 1.45,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(width * 0.08),
        boxShadow: const [
          BoxShadow(
            color: Colors.black54,
            blurRadius: 10,
            offset: Offset(0, 6),
          ),
        ],
        border: Border.all(color: AppColors.gold, width: 2),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(width * 0.07),
        child: CustomPaint(
          painter: CardBackPainter(backId),
          size: Size.infinite,
        ),
      ),
    );
  }
}
