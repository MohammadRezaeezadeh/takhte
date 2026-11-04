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
      case 24: // Twin Anchors
        for (final dx in [-0.45, 0.45]) {
          final a = c.translate(dx * r, 0);
          canvas.drawLine(
            a.translate(0, -r * 0.7),
            a.translate(0, r * 0.6),
            stroke..strokeWidth = r * 0.12,
          );
          canvas.drawCircle(a.translate(0, -r * 0.78), r * 0.12, stroke);
          canvas.drawArc(
            Rect.fromCircle(center: a.translate(0, r * 0.2), radius: r * 0.42),
            0.2,
            math.pi - 0.4,
            false,
            stroke,
          );
        }
      case 25: // Bazaar Bargain: two coins and a die
        canvas.drawCircle(
          c.translate(-r * 0.4, r * 0.3),
          r * 0.38,
          Paint()..color = AppColors.goldLight,
        );
        canvas.drawCircle(
          c.translate(-r * 0.1, r * 0.45),
          r * 0.38,
          Paint()..color = const Color(0xFFE9C25A),
        );
        paintDie(
          canvas,
          c.translate(r * 0.4, -r * 0.3),
          r * 0.75,
          2,
          bone,
          angle: 0.25,
        );
      case 26: // Hourglass Sand
        final hg2 = Path()
          ..moveTo(c.dx - r * 0.55, c.dy - r)
          ..lineTo(c.dx + r * 0.55, c.dy - r)
          ..lineTo(c.dx + r * 0.08, c.dy)
          ..lineTo(c.dx + r * 0.55, c.dy + r)
          ..lineTo(c.dx - r * 0.55, c.dy + r)
          ..lineTo(c.dx - r * 0.08, c.dy)
          ..close();
        canvas.drawPath(
          hg2,
          Paint()..color = const Color(0xFFE9C25A).withValues(alpha: 0.35),
        );
        canvas.drawPath(hg2, stroke);
        _text(canvas, '4', c.translate(0, -r * 0.5), r * 0.7, color);
      case 27: // Simorgh: great bird with spread wings
        final body = Path()
          ..moveTo(c.dx, c.dy - r * 0.2)
          ..quadraticBezierTo(
            c.dx - r * 1.2,
            c.dy - r * 0.9,
            c.dx - r,
            c.dy + r * 0.1,
          )
          ..quadraticBezierTo(c.dx - r * 0.5, c.dy, c.dx, c.dy + r * 0.3)
          ..quadraticBezierTo(c.dx + r * 0.5, c.dy, c.dx + r, c.dy + r * 0.1)
          ..quadraticBezierTo(
            c.dx + r * 1.2,
            c.dy - r * 0.9,
            c.dx,
            c.dy - r * 0.2,
          )
          ..close();
        canvas.drawPath(
          body,
          Paint()
            ..shader = ui.Gradient.linear(
              c.translate(0, -r),
              c.translate(0, r),
              const [Color(0xFF6CF2FF), Color(0xFF6B4BD8)],
            ),
        );
        for (var i = -2; i <= 2; i++) {
          canvas.drawLine(
            c.translate(0, r * 0.3),
            c.translate(i * r * 0.2, r * 1.0),
            stroke..strokeWidth = r * 0.06,
          );
        }
      case 28: // Nightfall: crescent moon
        canvas.drawCircle(c, r * 0.8, fill);
        canvas.drawCircle(
          c.translate(r * 0.35, -r * 0.2),
          r * 0.72,
          Paint()..color = const Color(0xFF141A33),
        );
        BoardArt.star(
          canvas,
          c.translate(r * 0.5, r * 0.45),
          r * 0.15,
          5,
          fill,
        );
      case 29: // Lantern of Truth
        final body2 = Rect.fromCenter(
          center: c.translate(0, r * 0.1),
          width: r * 0.9,
          height: r * 1.3,
        );
        canvas.drawCircle(
          c.translate(0, r * 0.1),
          r * 0.9,
          Paint()
            ..color = color.withValues(alpha: 0.25)
            ..maskFilter = MaskFilter.blur(BlurStyle.normal, r * 0.3),
        );
        canvas.drawRRect(
          RRect.fromRectAndRadius(body2, Radius.circular(r * 0.35)),
          fill,
        );
        canvas.drawLine(c.translate(0, -r * 0.55), c.translate(0, -r), stroke);
        for (final dx in [-0.18, 0.0, 0.18]) {
          canvas.drawLine(
            c.translate(dx * r, -r * 0.5),
            c.translate(dx * r, r * 0.7),
            Paint()
              ..color = const Color(0xFF8C6418)
              ..strokeWidth = r * 0.05,
          );
        }
      case 30: // Earthquake: cracked ground
        canvas.drawRect(
          Rect.fromLTRB(c.dx - r, c.dy + r * 0.1, c.dx + r, c.dy + r * 0.7),
          Paint()..color = const Color(0xFF8C6A48),
        );
        canvas.drawPath(
          Path()
            ..moveTo(c.dx - r * 0.1, c.dy - r * 0.9)
            ..lineTo(c.dx + r * 0.15, c.dy - r * 0.3)
            ..lineTo(c.dx - r * 0.15, c.dy + r * 0.1)
            ..lineTo(c.dx + r * 0.1, c.dy + r * 0.7),
          stroke..strokeWidth = r * 0.12,
        );
        for (final dx in [-0.7, 0.7]) {
          canvas.drawLine(
            c.translate(dx * r, -r * 0.6),
            c.translate(dx * r * 0.8, -r * 0.2),
            stroke..strokeWidth = r * 0.07,
          );
        }
      case 31: // Lucky Six
        paintDie(canvas, c, r * 1.2, 6, bone, angle: 0.08);
        BoardArt.star(
          canvas,
          c.translate(r * 0.75, -r * 0.75),
          r * 0.25,
          5,
          fill,
        );
      case 32: // Vortex: two swirls
        for (final dx in [-0.45, 0.45]) {
          final v = Path();
          for (var i = 0; i <= 40; i++) {
            final a = i / 40 * math.pi * 3.5;
            final rr = r * 0.5 * (1 - i / 40);
            final p =
                c.translate(dx * r, 0) +
                Offset(math.cos(a) * rr, math.sin(a) * rr * 0.7);
            if (i == 0) {
              v.moveTo(p.dx, p.dy);
            } else {
              v.lineTo(p.dx, p.dy);
            }
          }
          canvas.drawPath(v, stroke..strokeWidth = r * 0.08);
        }
      case 33: // Minefield: two mines
        for (final o in [
          Offset(-r * 0.45, r * 0.15),
          Offset(r * 0.45, -r * 0.15),
        ]) {
          canvas.drawCircle(
            c + o,
            r * 0.38,
            Paint()..color = const Color(0xFF2A2A2A),
          );
          for (var i = 0; i < 8; i++) {
            final a = i * math.pi / 4;
            canvas.drawLine(
              c + o,
              c + o + Offset(math.cos(a), math.sin(a)) * r * 0.55,
              Paint()
                ..color = const Color(0xFF2A2A2A)
                ..strokeWidth = r * 0.09,
            );
          }
          canvas.drawCircle(
            c + o.translate(-r * 0.1, -r * 0.1),
            r * 0.08,
            Paint()..color = AppColors.ruby,
          );
        }
      case 34: // Truce: white flag / dove-like
        canvas.drawLine(
          c.translate(-r * 0.6, r),
          c.translate(-r * 0.6, -r),
          stroke..strokeWidth = r * 0.1,
        );
        final flag = Path()
          ..moveTo(c.dx - r * 0.6, c.dy - r)
          ..quadraticBezierTo(
            c.dx,
            c.dy - r * 1.2,
            c.dx + r * 0.8,
            c.dy - r * 0.8,
          )
          ..quadraticBezierTo(
            c.dx + r * 0.3,
            c.dy - r * 0.4,
            c.dx + r * 0.8,
            c.dy,
          )
          ..quadraticBezierTo(
            c.dx,
            c.dy - r * 0.1,
            c.dx - r * 0.6,
            c.dy - r * 0.1,
          )
          ..close();
        canvas.drawPath(flag, Paint()..color = const Color(0xFFF3E9D2));
      case 35: // Tailwind: arrows forward
      case 36: // Headwind: arrows back
        final dir = glyph == 35 ? 1.0 : -1.0;
        for (var i = -1; i <= 1; i++) {
          final y = c.dy + i * r * 0.5;
          final path = Path()
            ..moveTo(c.dx - r * 0.9 * dir, y)
            ..quadraticBezierTo(c.dx, y - r * 0.25, c.dx + r * 0.7 * dir, y);
          canvas.drawPath(path, stroke..strokeWidth = r * 0.09);
          canvas.drawPath(
            Path()
              ..moveTo(c.dx + r * 0.95 * dir, y)
              ..lineTo(c.dx + r * 0.65 * dir, y - r * 0.18)
              ..lineTo(c.dx + r * 0.65 * dir, y + r * 0.18)
              ..close(),
            fill,
          );
        }
      case 37: // Even Odds: 2 and 4
        paintDie(
          canvas,
          c.translate(-r * 0.45, 0),
          r * 0.85,
          2,
          bone,
          angle: -0.15,
        );
        paintDie(
          canvas,
          c.translate(r * 0.45, 0),
          r * 0.85,
          4,
          bone,
          angle: 0.15,
        );
      case 38: // Ward of Ones: crossed-out 1
        paintDie(canvas, c, r * 1.1, 1, bone);
        canvas.drawLine(
          c.translate(-r * 0.7, -r * 0.7),
          c.translate(r * 0.7, r * 0.7),
          Paint()
            ..color = AppColors.ruby
            ..strokeWidth = r * 0.14,
        );
      case 39: // Twin Dice
        paintDie(canvas, c.translate(-r * 0.45, 0), r * 0.85, 5, bone);
        paintDie(canvas, c.translate(r * 0.45, 0), r * 0.85, 5, bone);
        canvas.drawArc(
          Rect.fromCenter(
            center: c.translate(0, -r * 0.55),
            width: r * 0.9,
            height: r * 0.5,
          ),
          math.pi,
          math.pi,
          false,
          stroke..strokeWidth = r * 0.07,
        );
      case 40: // Royal Roll: crowned die
        paintDie(canvas, c.translate(0, r * 0.2), r * 0.95, 6, bone);
        final crown = Path()
          ..moveTo(c.dx - r * 0.45, c.dy - r * 0.45)
          ..lineTo(c.dx - r * 0.5, c.dy - r * 0.9)
          ..lineTo(c.dx - r * 0.22, c.dy - r * 0.68)
          ..lineTo(c.dx, c.dy - r)
          ..lineTo(c.dx + r * 0.22, c.dy - r * 0.68)
          ..lineTo(c.dx + r * 0.5, c.dy - r * 0.9)
          ..lineTo(c.dx + r * 0.45, c.dy - r * 0.45)
          ..close();
        canvas.drawPath(crown, Paint()..color = AppColors.goldLight);
      case 41: // Silk Purse: purse with two arrows
        final purse = Path()
          ..moveTo(c.dx - r * 0.25, c.dy - r * 0.4)
          ..quadraticBezierTo(
            c.dx - r * 0.95,
            c.dy + r * 0.3,
            c.dx - r * 0.5,
            c.dy + r * 0.85,
          )
          ..lineTo(c.dx + r * 0.5, c.dy + r * 0.85)
          ..quadraticBezierTo(
            c.dx + r * 0.95,
            c.dy + r * 0.3,
            c.dx + r * 0.25,
            c.dy - r * 0.4,
          )
          ..close();
        canvas.drawPath(purse, Paint()..color = const Color(0xFFB794FF));
        for (final dx in [-0.2, 0.2]) {
          canvas.drawArc(
            Rect.fromCircle(
              center: c.translate(dx * r, r * 0.25),
              radius: r * 0.2,
            ),
            0,
            math.pi * 1.6,
            false,
            Paint()
              ..color = Colors.white
              ..style = PaintingStyle.stroke
              ..strokeWidth = r * 0.06,
          );
        }
      case 42: // Leaden Dice: grey heavy die with 3
        paintDie(canvas, c, r * 1.15, 3, kDiceStyles['dice_wood']!, angle: 0.1);
        canvas.drawRect(
          Rect.fromCenter(
            center: c.translate(0, r * 0.85),
            width: r * 1.4,
            height: r * 0.18,
          ),
          Paint()..color = const Color(0xFF6E6762),
        );
      case 43: // Shackle: ring + ball
        canvas.drawCircle(
          c.translate(-r * 0.35, -r * 0.2),
          r * 0.35,
          stroke..strokeWidth = r * 0.12,
        );
        canvas.drawLine(
          c.translate(-r * 0.05, 0),
          c.translate(r * 0.35, r * 0.35),
          stroke,
        );
        canvas.drawCircle(
          c.translate(r * 0.5, r * 0.5),
          r * 0.38,
          Paint()..color = const Color(0xFF3A3532),
        );
      case 44: // Pickpocket: grabbing hand
        final hand = Path()
          ..moveTo(c.dx - r * 0.6, c.dy + r * 0.8)
          ..lineTo(c.dx - r * 0.6, c.dy - r * 0.1);
        for (var i = 0; i < 4; i++) {
          final x = c.dx - r * 0.45 + i * r * 0.3;
          hand
            ..lineTo(x, c.dy - r * (0.7 - (i == 0 ? -0.1 : 0)))
            ..lineTo(x + r * 0.15, c.dy - r * 0.15);
        }
        hand
          ..lineTo(c.dx + r * 0.7, c.dy + r * 0.8)
          ..close();
        canvas.drawPath(hand, fill);
      case 45: // Hex of Sevens: crossed 7
        _text(canvas, '7', c, r * 1.7, color);
        canvas.drawCircle(
          c,
          r * 0.9,
          Paint()
            ..color = AppColors.ruby
            ..style = PaintingStyle.stroke
            ..strokeWidth = r * 0.1,
        );
        canvas.drawLine(
          c.translate(-r * 0.63, r * 0.63),
          c.translate(r * 0.63, -r * 0.63),
          Paint()
            ..color = AppColors.ruby
            ..strokeWidth = r * 0.1,
        );
      case 46: // Sprint: checker with speed lines
        canvas.drawCircle(c.translate(r * 0.3, 0), r * 0.45, fill);
        for (var i = -1; i <= 1; i++) {
          canvas.drawLine(
            c.translate(-r * 0.9, i * r * 0.3),
            c.translate(-r * 0.25, i * r * 0.3),
            stroke..strokeWidth = r * 0.07,
          );
        }
      case 47: // Shield Wall: three shields
        for (var i = -1; i <= 1; i++) {
          final o = c.translate(i * r * 0.62, i.abs() * r * 0.1);
          final sh = Path()
            ..moveTo(o.dx, o.dy - r * 0.5)
            ..lineTo(o.dx + r * 0.38, o.dy - r * 0.3)
            ..quadraticBezierTo(
              o.dx + r * 0.35,
              o.dy + r * 0.25,
              o.dx,
              o.dy + r * 0.5,
            )
            ..quadraticBezierTo(
              o.dx - r * 0.35,
              o.dy + r * 0.25,
              o.dx - r * 0.38,
              o.dy - r * 0.3,
            )
            ..close();
          canvas.drawPath(sh, fill);
        }
      case 48: // Homecoming: arch with arrow
        canvas.drawArc(
          Rect.fromCenter(
            center: c.translate(0, r * 0.1),
            width: r * 1.5,
            height: r * 1.6,
          ),
          math.pi,
          math.pi,
          false,
          stroke..strokeWidth = r * 0.1,
        );
        canvas.drawLine(
          c.translate(-r * 0.75, r * 0.1),
          c.translate(-r * 0.75, r * 0.9),
          stroke,
        );
        canvas.drawLine(
          c.translate(r * 0.75, r * 0.1),
          c.translate(r * 0.75, r * 0.9),
          stroke,
        );
        canvas.drawLine(
          c.translate(0, r * 0.8),
          c.translate(0, -r * 0.2),
          stroke,
        );
        canvas.drawPath(
          Path()
            ..moveTo(c.dx - r * 0.25, c.dy)
            ..lineTo(c.dx, c.dy - r * 0.35)
            ..lineTo(c.dx + r * 0.25, c.dy)
            ..close(),
          fill,
        );
      case 49: // Rallying Cry: horn
        final horn = Path()
          ..moveTo(c.dx - r * 0.8, c.dy - r * 0.15)
          ..lineTo(c.dx + r * 0.5, c.dy - r * 0.6)
          ..lineTo(c.dx + r * 0.5, c.dy + r * 0.6)
          ..lineTo(c.dx - r * 0.8, c.dy + r * 0.15)
          ..close();
        canvas.drawPath(horn, fill);
        for (var i = 1; i <= 2; i++) {
          canvas.drawArc(
            Rect.fromCircle(
              center: c.translate(r * 0.5, 0),
              radius: r * 0.25 * i,
            ),
            -0.7,
            1.4,
            false,
            stroke..strokeWidth = r * 0.06,
          );
        }
      case 50: // Stone Skin: two grey shields
        for (final dx in [-0.42, 0.42]) {
          final o = c.translate(dx * r, 0);
          final sh = Path()
            ..moveTo(o.dx, o.dy - r * 0.65)
            ..lineTo(o.dx + r * 0.45, o.dy - r * 0.4)
            ..quadraticBezierTo(
              o.dx + r * 0.42,
              o.dy + r * 0.35,
              o.dx,
              o.dy + r * 0.65,
            )
            ..quadraticBezierTo(
              o.dx - r * 0.42,
              o.dy + r * 0.35,
              o.dx - r * 0.45,
              o.dy - r * 0.4,
            )
            ..close();
          canvas.drawPath(sh, Paint()..color = const Color(0xFF9AA3AE));
          canvas.drawPath(
            sh,
            Paint()
              ..color = color
              ..style = PaintingStyle.stroke
              ..strokeWidth = r * 0.05,
          );
        }
      case 51: // Caltrops: spikes
        for (final o in [
          Offset(-r * 0.45, r * 0.2),
          Offset(r * 0.45, -r * 0.1),
        ]) {
          for (var i = 0; i < 4; i++) {
            final a = i * math.pi / 2 + 0.4;
            canvas.drawLine(
              c + o,
              c + o + Offset(math.cos(a), math.sin(a)) * r * 0.45,
              stroke..strokeWidth = r * 0.1,
            );
          }
        }
      case 52: // Bait: fishing hook
        canvas.drawLine(
          c.translate(0, -r),
          c.translate(0, r * 0.4),
          stroke..strokeWidth = r * 0.1,
        );
        canvas.drawArc(
          Rect.fromCircle(
            center: c.translate(-r * 0.3, r * 0.4),
            radius: r * 0.3,
          ),
          0,
          math.pi,
          false,
          stroke,
        );
        canvas.drawCircle(c.translate(-r * 0.6, r * 0.2), r * 0.08, fill);
      case 53: // Rally: red banner
        canvas.drawLine(
          c.translate(-r * 0.6, r),
          c.translate(-r * 0.6, -r),
          stroke..strokeWidth = r * 0.1,
        );
        canvas.drawPath(
          Path()
            ..moveTo(c.dx - r * 0.6, c.dy - r)
            ..lineTo(c.dx + r * 0.8, c.dy - r * 0.6)
            ..lineTo(c.dx - r * 0.6, c.dy - r * 0.1)
            ..close(),
          Paint()..color = AppColors.ruby,
        );
      case 54: // Fortune Teller: crystal ball
        canvas.drawCircle(
          c.translate(0, -r * 0.1),
          r * 0.7,
          Paint()
            ..shader = ui.Gradient.radial(
              c.translate(-r * 0.2, -r * 0.3),
              r,
              const [Color(0xFFE0D4FF), Color(0xFF6B4BD8)],
            ),
        );
        canvas.drawRect(
          Rect.fromCenter(
            center: c.translate(0, r * 0.75),
            width: r * 1.1,
            height: r * 0.25,
          ),
          fill,
        );
      case 55: // Destiny: two fanned cards
        for (final a in [-0.25, 0.25]) {
          canvas.save();
          canvas.translate(c.dx, c.dy + r * 0.2);
          canvas.rotate(a);
          canvas.drawRRect(
            RRect.fromRectAndRadius(
              Rect.fromCenter(
                center: Offset(0, -r * 0.35),
                width: r * 0.8,
                height: r * 1.15,
              ),
              Radius.circular(r * 0.1),
            ),
            Paint()..color = const Color(0xFF1B2A6B),
          );
          canvas.drawRRect(
            RRect.fromRectAndRadius(
              Rect.fromCenter(
                center: Offset(0, -r * 0.35),
                width: r * 0.8,
                height: r * 1.15,
              ),
              Radius.circular(r * 0.1),
            ),
            stroke..strokeWidth = r * 0.06,
          );
          canvas.restore();
        }
      case 56: // High Stakes: coin stack x2
        for (var i = 0; i < 4; i++) {
          canvas.drawOval(
            Rect.fromCenter(
              center: c.translate(-r * 0.3, r * (0.55 - i * 0.22)),
              width: r * 0.9,
              height: r * 0.35,
            ),
            Paint()
              ..color = i.isEven
                  ? AppColors.goldLight
                  : const Color(0xFFB8861C),
          );
        }
        _text(canvas, '×2', c.translate(r * 0.5, -r * 0.4), r * 0.75, color);
      case 57: // Exile: checker flung out
        canvas.drawCircle(
          c.translate(-r * 0.35, r * 0.3),
          r * 0.38,
          Paint()..color = const Color(0xFF5A3420),
        );
        canvas.drawLine(
          c.translate(-r * 0.05, 0),
          c.translate(r * 0.75, -r * 0.75),
          stroke..strokeWidth = r * 0.1,
        );
        canvas.drawPath(
          Path()
            ..moveTo(c.dx + r * 0.85, c.dy - r * 0.85)
            ..lineTo(c.dx + r * 0.4, c.dy - r * 0.75)
            ..lineTo(c.dx + r * 0.75, c.dy - r * 0.4)
            ..close(),
          fill,
        );
      case 58: // Oasis: palm tree
        canvas.drawLine(
          c.translate(0, r),
          c.translate(r * 0.1, -r * 0.3),
          Paint()
            ..color = const Color(0xFF8C6A48)
            ..strokeWidth = r * 0.14,
        );
        for (var i = 0; i < 5; i++) {
          final a = math.pi + i * math.pi / 4;
          canvas.drawLine(
            c.translate(r * 0.1, -r * 0.3),
            c.translate(r * 0.1, -r * 0.3) +
                Offset(math.cos(a), math.sin(a) * 0.6) * r * 0.8,
            Paint()
              ..color = const Color(0xFF2E9E5A)
              ..strokeWidth = r * 0.12
              ..strokeCap = StrokeCap.round,
          );
        }
        canvas.drawOval(
          Rect.fromCenter(
            center: c.translate(0, r * 0.95),
            width: r * 1.6,
            height: r * 0.25,
          ),
          Paint()..color = const Color(0xFF34C3C3),
        );
      case 59: // Double Agent: two masks
        for (final dx in [-0.35, 0.35]) {
          canvas.drawOval(
            Rect.fromCenter(
              center: c.translate(dx * r, dx * r * 0.3),
              width: r * 0.9,
              height: r * 1.1,
            ),
            Paint()
              ..color = dx < 0
                  ? const Color(0xFFF3E9D2)
                  : const Color(0xFF2A2A2A),
          );
          canvas.drawCircle(
            c.translate(dx * r - r * 0.15, dx * r * 0.3 - r * 0.1),
            r * 0.08,
            Paint()..color = dx < 0 ? Colors.black : Colors.white,
          );
          canvas.drawCircle(
            c.translate(dx * r + r * 0.15, dx * r * 0.3 - r * 0.1),
            r * 0.08,
            Paint()..color = dx < 0 ? Colors.black : Colors.white,
          );
        }
      case 60: // Sandstorm: swirling sand arcs
        for (var i = 0; i < 4; i++) {
          canvas.drawArc(
            Rect.fromCircle(center: c, radius: r * (0.3 + i * 0.22)),
            i * 1.3 + time,
            math.pi * 1.1,
            false,
            Paint()
              ..color = Color.lerp(
                const Color(0xFFE8C07A),
                const Color(0xFF9C6B30),
                i / 3,
              )!
              ..style = PaintingStyle.stroke
              ..strokeWidth = r * 0.11
              ..strokeCap = StrokeCap.round,
          );
        }
      case 61: // Caravan: camel silhouette
        final camel = Paint()..color = const Color(0xFFC89B5A);
        canvas
          ..drawOval(
            Rect.fromCenter(
              center: c.translate(-r * 0.1, 0),
              width: r * 1.2,
              height: r * 0.6,
            ),
            camel,
          )
          ..drawCircle(c.translate(-r * 0.15, -r * 0.3), r * 0.28, camel)
          ..drawLine(
            c.translate(r * 0.4, -r * 0.05),
            c.translate(r * 0.65, -r * 0.6),
            camel..strokeWidth = r * 0.16,
          )
          ..drawCircle(c.translate(r * 0.72, -r * 0.62), r * 0.13, camel);
        for (final dx in [-0.5, -0.25, 0.1, 0.3]) {
          canvas.drawLine(
            c.translate(dx * r, r * 0.2),
            c.translate(dx * r, r * 0.85),
            camel..strokeWidth = r * 0.09,
          );
        }
      case 62: // Spirit Ward: ward with an eye
        canvas
          ..drawCircle(c, r * 0.85, Paint()..color = const Color(0xFF2B5DAA))
          ..drawCircle(c, r * 0.6, Paint()..color = const Color(0xFFEFF4FF))
          ..drawCircle(c, r * 0.32, Paint()..color = const Color(0xFF4F8FE8))
          ..drawCircle(c, r * 0.14, Paint()..color = Colors.black);
      case 63: // Mirage: shimmering heat lines
        for (var i = 0; i < 4; i++) {
          final y = c.dy - r * 0.6 + i * r * 0.4;
          final path = Path()..moveTo(c.dx - r * 0.9, y);
          for (var k = 0; k < 6; k++) {
            path.relativeQuadraticBezierTo(
              r * 0.15,
              (k.isEven ? -1 : 1) * r * 0.15 * math.sin(time * 2 + i),
              r * 0.3,
              0,
            );
          }
          canvas.drawPath(
            path,
            Paint()
              ..color = const Color(0xFF7FD6E0)
                  .withValues(alpha: 0.4 + i * 0.15)
              ..style = PaintingStyle.stroke
              ..strokeWidth = r * 0.08,
          );
        }
      case 64: // Mountain Pass: two peaks with a gap
        for (final dx in [-0.45, 0.45]) {
          canvas.drawPath(
            Path()
              ..moveTo(c.dx + dx * r - r * 0.55, c.dy + r * 0.8)
              ..lineTo(c.dx + dx * r, c.dy - r * 0.7)
              ..lineTo(c.dx + dx * r + r * 0.4, c.dy + r * 0.8)
              ..close(),
            Paint()..color = const Color(0xFF6F7B8C),
          );
          canvas.drawPath(
            Path()
              ..moveTo(c.dx + dx * r - r * 0.17, c.dy - r * 0.25)
              ..lineTo(c.dx + dx * r, c.dy - r * 0.7)
              ..lineTo(c.dx + dx * r + r * 0.13, c.dy - r * 0.3)
              ..close(),
            Paint()..color = Colors.white,
          );
        }
      case 65: // Saffron Thread: crocus flower
        for (var i = 0; i < 6; i++) {
          final a = i * math.pi / 3 + time * 0.3;
          canvas.drawOval(
            Rect.fromCenter(
              center: c + Offset(math.cos(a), math.sin(a)) * r * 0.45,
              width: r * 0.55,
              height: r * 0.35,
            ),
            Paint()..color = const Color(0xFF9B6BD6),
          );
        }
        for (var i = 0; i < 3; i++) {
          final a = -math.pi / 2 + (i - 1) * 0.5;
          canvas.drawLine(
            c,
            c + Offset(math.cos(a), math.sin(a)) * r * 0.55,
            Paint()
              ..color = const Color(0xFFE0461E)
              ..strokeWidth = r * 0.08
              ..strokeCap = StrokeCap.round,
          );
        }
      case 66: // Star Reader: seven-pointed star
        final star = Path();
        for (var i = 0; i < 14; i++) {
          final a = -math.pi / 2 + i * math.pi / 7;
          final rr = i.isEven ? r * 0.9 : r * 0.42;
          final pt = c + Offset(math.cos(a), math.sin(a)) * rr;
          i == 0 ? star.moveTo(pt.dx, pt.dy) : star.lineTo(pt.dx, pt.dy);
        }
        canvas.drawPath(
          star..close(),
          Paint()..color = const Color(0xFFF2C94C),
        );
      case 67: // Sevenfold: seven orbs in a ring
        for (var i = 0; i < 7; i++) {
          final a = -math.pi / 2 + i * 2 * math.pi / 7 + time * 0.4;
          canvas.drawCircle(
            c + Offset(math.cos(a), math.sin(a)) * r * 0.65,
            r * 0.16,
            Paint()..color = i.isEven ? color : const Color(0xFFF2C94C),
          );
        }
        canvas.drawCircle(c, r * 0.22, Paint()..color = color);
      case 68: // Hailstorm: cloud with hailstones
        final cloud = Paint()..color = const Color(0xFF8E9AAF);
        canvas
          ..drawCircle(c.translate(-r * 0.35, -r * 0.25), r * 0.35, cloud)
          ..drawCircle(c.translate(r * 0.1, -r * 0.4), r * 0.42, cloud)
          ..drawCircle(c.translate(r * 0.5, -r * 0.2), r * 0.3, cloud);
        for (var i = 0; i < 5; i++) {
          final dy = ((time * 0.8 + i * 0.37) % 1) * r * 0.6;
          canvas.drawCircle(
            c.translate((i - 2) * r * 0.3, r * 0.25 + dy),
            r * 0.09,
            Paint()..color = Colors.white,
          );
        }
      case 69: // Royal Treasury: treasure chest
        canvas
          ..drawRect(
            Rect.fromCenter(
              center: c.translate(0, r * 0.25),
              width: r * 1.5,
              height: r * 0.8,
            ),
            Paint()..color = const Color(0xFF7A4A22),
          )
          ..drawArc(
            Rect.fromCenter(
              center: c.translate(0, -r * 0.15),
              width: r * 1.5,
              height: r * 0.8,
            ),
            math.pi,
            math.pi,
            true,
            Paint()..color = const Color(0xFF9A6234),
          )
          ..drawRect(
            Rect.fromCenter(
              center: c.translate(0, r * 0.05),
              width: r * 1.5,
              height: r * 0.12,
            ),
            Paint()..color = const Color(0xFFF2C94C),
          )
          ..drawCircle(
            c.translate(0, r * 0.2),
            r * 0.12,
            Paint()..color = const Color(0xFFF2C94C),
          );
      case 70: // Falcon's Eye: golden eye with a dark pupil
        canvas
          ..drawOval(
            Rect.fromCenter(center: c, width: r * 1.8, height: r * 1.0),
            Paint()..color = const Color(0xFFF2C94C),
          )
          ..drawCircle(c, r * 0.38, Paint()..color = const Color(0xFF8C4A12))
          ..drawCircle(c, r * 0.18, Paint()..color = Colors.black)
          ..drawCircle(
            c.translate(-r * 0.1, -r * 0.1),
            r * 0.06,
            Paint()..color = Colors.white,
          );
      case 71: // Iron Dice: grey die with four pips
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(center: c, width: r * 1.5, height: r * 1.5),
            Radius.circular(r * 0.25),
          ),
          Paint()..color = const Color(0xFF7D8590),
        );
        for (final o in [(-1, -1), (1, -1), (-1, 1), (1, 1)]) {
          canvas.drawCircle(
            c.translate(o.$1 * r * 0.38, o.$2 * r * 0.38),
            r * 0.13,
            Paint()..color = const Color(0xFF22262B),
          );
        }
      case 72: // Eclipse: dark disc over a glowing ring
        canvas
          ..drawCircle(c, r * 0.85, Paint()..color = const Color(0xFFF2C94C))
          ..drawCircle(
            c.translate(r * 0.12, -r * 0.05),
            r * 0.75,
            Paint()..color = const Color(0xFF14121C),
          );
      case 73: // Sultan's Favor: crown
        canvas.drawPath(
          Path()
            ..moveTo(c.dx - r * 0.85, c.dy + r * 0.5)
            ..lineTo(c.dx - r * 0.85, c.dy - r * 0.35)
            ..lineTo(c.dx - r * 0.42, c.dy + r * 0.05)
            ..lineTo(c.dx, c.dy - r * 0.6)
            ..lineTo(c.dx + r * 0.42, c.dy + r * 0.05)
            ..lineTo(c.dx + r * 0.85, c.dy - r * 0.35)
            ..lineTo(c.dx + r * 0.85, c.dy + r * 0.5)
            ..close(),
          Paint()..color = const Color(0xFFF2C94C),
        );
        for (final dx in [-0.45, 0.0, 0.45]) {
          canvas.drawCircle(
            c.translate(dx * r, r * 0.28),
            r * 0.1,
            Paint()..color = const Color(0xFFC0392B),
          );
        }
      case 74: // Bandit: masked face
        canvas
          ..drawCircle(c, r * 0.8, Paint()..color = const Color(0xFFD9B38C))
          ..drawRect(
            Rect.fromCenter(
              center: c.translate(0, -r * 0.1),
              width: r * 1.7,
              height: r * 0.4,
            ),
            Paint()..color = const Color(0xFF1E1E1E),
          );
        for (final dx in [-0.3, 0.3]) {
          canvas.drawCircle(
            c.translate(dx * r, -r * 0.1),
            r * 0.09,
            Paint()..color = Colors.white,
          );
        }
      case 75: // Desert Rose: layered petals
        for (var ring = 0; ring < 3; ring++) {
          for (var i = 0; i < 5; i++) {
            final a = i * 2 * math.pi / 5 + ring * 0.6;
            canvas.drawCircle(
              c + Offset(math.cos(a), math.sin(a)) * r * (0.55 - ring * 0.18),
              r * (0.32 - ring * 0.07),
              Paint()
                ..color = Color.lerp(
                  const Color(0xFFE8A0A0),
                  const Color(0xFFB03A48),
                  ring / 2,
                )!,
            );
          }
        }
      case 76: // Twin Suns: two radiant suns
        for (final dx in [-0.42, 0.42]) {
          final sc = c.translate(dx * r, dx * r * 0.3);
          for (var i = 0; i < 8; i++) {
            final a = i * math.pi / 4 + time * 0.5;
            canvas.drawLine(
              sc + Offset(math.cos(a), math.sin(a)) * r * 0.3,
              sc + Offset(math.cos(a), math.sin(a)) * r * 0.5,
              Paint()
                ..color = const Color(0xFFF5A623)
                ..strokeWidth = r * 0.07,
            );
          }
          canvas.drawCircle(
            sc,
            r * 0.26,
            Paint()..color = const Color(0xFFF2C94C),
          );
        }
      case 77: // Cold Snap: snowflake
        for (var i = 0; i < 6; i++) {
          final a = i * math.pi / 3;
          final d = Offset(math.cos(a), math.sin(a));
          final arm = Paint()
            ..color = const Color(0xFFBFE6FF)
            ..strokeWidth = r * 0.09
            ..strokeCap = StrokeCap.round;
          canvas.drawLine(c, c + d * r * 0.85, arm);
          final m = c + d * r * 0.5;
          for (final s in [-1, 1]) {
            final b = a + s * math.pi / 4;
            canvas.drawLine(
              m,
              m + Offset(math.cos(b), math.sin(b)) * r * 0.25,
              arm,
            );
          }
        }
      case 78: // Pilgrimage: arch gateway
        canvas
          ..drawRect(
            Rect.fromCenter(
              center: c.translate(0, r * 0.2),
              width: r * 1.5,
              height: r * 1.2,
            ),
            Paint()..color = const Color(0xFF2E86AB),
          )
          ..drawCircle(
            c.translate(0, -r * 0.4),
            r * 0.75,
            Paint()..color = const Color(0xFF2E86AB),
          )
          ..drawCircle(
            c.translate(0, -r * 0.2),
            r * 0.38,
            Paint()..color = const Color(0xFF14121C),
          )
          ..drawRect(
            Rect.fromCenter(
              center: c.translate(0, r * 0.3),
              width: r * 0.76,
              height: r * 1.0,
            ),
            Paint()..color = const Color(0xFF14121C),
          );
      case 79: // Eye of the Storm: spiral around a calm centre
        final spiral = Path()..moveTo(c.dx, c.dy);
        for (var t = 0.0; t < 4 * math.pi; t += 0.2) {
          final rr = r * 0.07 * t;
          spiral.lineTo(
            c.dx + math.cos(t + time) * rr,
            c.dy + math.sin(t + time) * rr,
          );
        }
        canvas
          ..drawPath(
            spiral,
            Paint()
              ..color = const Color(0xFF6C8EBF)
              ..style = PaintingStyle.stroke
              ..strokeWidth = r * 0.1,
          )
          ..drawCircle(c, r * 0.12, Paint()..color = Colors.white);
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
