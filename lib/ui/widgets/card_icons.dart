import 'dart:math' as math;
import 'dart:ui';

import 'package:haftnard/game/themes/pieces.dart';

/// Redrawn card icons (playtest round 3 clarity audit): concrete objects that
/// read at HUD size (32 px) and differ from every other icon. Returns false
/// for glyphs that keep their original art. Used everywhere a card icon
/// appears (card face, HUD chip, board badge, history).
bool paintClearIcon(Canvas c, int glyph, Offset o, double r) {
  final bone = kDiceStyles['dice_bone']!;
  Paint fill(int argb) => Paint()..color = Color(argb);
  Paint line(int argb, double w) => Paint()
    ..color = Color(argb)
    ..style = PaintingStyle.stroke
    ..strokeWidth = w
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round;

  void arrowHead(Offset tip, double angle, double s, Paint p) {
    final a = Offset(math.cos(angle + 2.6), math.sin(angle + 2.6)) * s;
    final b = Offset(math.cos(angle - 2.6), math.sin(angle - 2.6)) * s;
    c.drawPath(
      Path()
        ..moveTo(tip.dx, tip.dy)
        ..lineTo(tip.dx + a.dx, tip.dy + a.dy)
        ..lineTo(tip.dx + b.dx, tip.dy + b.dy)
        ..close(),
      p,
    );
  }

  void cloud(Offset at, double s, Paint p) {
    c
      ..drawCircle(at.translate(-s * 0.55, s * 0.1), s * 0.45, p)
      ..drawCircle(at.translate(0, -s * 0.15), s * 0.6, p)
      ..drawCircle(at.translate(s * 0.6, s * 0.1), s * 0.42, p)
      ..drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: at.translate(0, s * 0.3),
            width: s * 2.1,
            height: s * 0.6,
          ),
          Radius.circular(s * 0.3),
        ),
        p,
      );
  }

  void shield(Offset at, double s, int argb) {
    final path = Path()
      ..moveTo(at.dx, at.dy - s)
      ..lineTo(at.dx + s * 0.8, at.dy - s * 0.7)
      ..quadraticBezierTo(at.dx + s * 0.8, at.dy + s * 0.5, at.dx, at.dy + s)
      ..quadraticBezierTo(
        at.dx - s * 0.8,
        at.dy + s * 0.5,
        at.dx - s * 0.8,
        at.dy - s * 0.7,
      )
      ..close();
    c
      ..drawPath(path, fill(argb))
      ..drawPath(path, line(0xFF2A2A3A, s * 0.12));
  }

  switch (glyph) {
    case 1: // Roll Again: one die inside a circular "again" arrow
      paintDie(c, o, r * 0.95, 5, bone);
      final p = line(0xFFFFD36B, r * 0.16);
      c.drawArc(
        Rect.fromCircle(center: o, radius: r * 0.98),
        -2.4,
        4.6,
        false,
        p,
      );
      arrowHead(
        o + Offset(math.cos(2.2), math.sin(2.2)) * r * 0.98,
        2.2 + math.pi / 2,
        r * 0.32,
        fill(0xFFFFD36B),
      );
    case 3: // Second Chance: a gold reroll token, a die and an arrow on it
      c
        ..drawCircle(o, r * 1.0, fill(0xFFB8811C))
        ..drawCircle(o, r * 0.86, fill(0xFFFFD36B));
      paintDie(c, o, r * 0.62, 2, bone);
      final p = line(0xFF8A5A10, r * 0.14);
      c.drawArc(
        Rect.fromCircle(center: o, radius: r * 0.66),
        -2.9,
        4.3,
        false,
        p,
      );
      arrowHead(
        o + Offset(math.cos(1.4), math.sin(1.4)) * r * 0.66,
        1.4 + math.pi / 2,
        r * 0.3,
        fill(0xFF8A5A10),
      );
    case 4: // Lucky Charm: a four-leaf clover
      for (var i = 0; i < 4; i++) {
        final a = i * math.pi / 2 + math.pi / 4;
        c.drawCircle(
          o.translate(0, -r * 0.1) + Offset(math.cos(a), math.sin(a)) * r * 0.4,
          r * 0.36,
          fill(0xFF3DBE6A),
        );
      }
      c
        ..drawCircle(o.translate(0, -r * 0.1), r * 0.15, fill(0xFF1F7A40))
        ..drawLine(
          o.translate(0, r * 0.2),
          o.translate(r * 0.25, r * 0.95),
          line(0xFF1F7A40, r * 0.13),
        );
    case 6: // Broken Die: a die split in two by a dark crack
      Path half(double side) => Path()
        ..moveTo(o.dx + side * r * 2, o.dy - r * 2)
        ..lineTo(o.dx + r * 0.05, o.dy - r * 2)
        ..lineTo(o.dx - r * 0.2, o.dy - r * 0.35)
        ..lineTo(o.dx + r * 0.22, o.dy + r * 0.15)
        ..lineTo(o.dx - r * 0.05, o.dy + r * 2)
        ..lineTo(o.dx + side * r * 2, o.dy + r * 2)
        ..close();
      c
        ..save()
        ..translate(-r * 0.2, r * 0.05)
        ..rotate(-0.12)
        ..clipPath(half(-1));
      paintDie(c, o, r * 1.4, 5, bone);
      c
        ..restore()
        ..save()
        ..translate(r * 0.22, -r * 0.05)
        ..rotate(0.12)
        ..clipPath(half(1));
      paintDie(c, o, r * 1.4, 5, bone);
      c.restore();
      // Shards and a jagged red flash in the gap.
      final crack = Path()
        ..moveTo(o.dx + r * 0.1, o.dy - r * 0.95)
        ..lineTo(o.dx - r * 0.12, o.dy - r * 0.3)
        ..lineTo(o.dx + r * 0.2, o.dy + r * 0.2)
        ..lineTo(o.dx, o.dy + r * 0.95);
      c.drawPath(crack, line(0xFFE0455A, r * 0.1));
      for (final d in const [Offset(0.45, -1.05), Offset(-0.5, 1)]) {
        c.drawRect(
          Rect.fromCenter(center: o + d * r, width: r * 0.16, height: r * 0.16),
          fill(0xFFF3E9D2),
        );
      }
    case 7: // Freeze (Chains): a snowflake on an ice cube
      final cube = RRect.fromRectAndRadius(
        Rect.fromCircle(center: o, radius: r * 0.92),
        Radius.circular(r * 0.22),
      );
      c
        ..drawRRect(cube, fill(0xFF8FDDF5))
        ..drawRRect(cube, line(0xFFE6FAFF, r * 0.09))
        ..drawLine(
          o.translate(-r * 0.7, -r * 0.45),
          o.translate(-r * 0.35, -r * 0.75),
          line(0xFFFFFFFF, r * 0.1),
        );
      final flake = line(0xFF1F6FA8, r * 0.12);
      for (var i = 0; i < 3; i++) {
        final a = i * math.pi / 3;
        final d = Offset(math.cos(a), math.sin(a)) * r * 0.55;
        c.drawLine(o - d, o + d, flake);
      }
    case 8: // Fog: a thick grey cloud covering most of a die
      paintDie(c, o.translate(-r * 0.25, -r * 0.4), r * 0.95, 3, bone);
      cloud(o.translate(r * 0.05, r * 0.12), r * 0.86, fill(0xFF8E98A3));
      cloud(o.translate(r * 0.05, r * 0.2), r * 0.7, fill(0xFFC9D1D8));
    case 9: // Curse: a die in a dark aura, a skull above it
      c.drawCircle(
        o.translate(0, r * 0.2),
        r * 0.95,
        Paint()
          ..color = const Color(0xFF5B2A86)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, r * 0.25),
      );
      paintDie(c, o.translate(0, r * 0.3), r * 0.95, 2, bone);
      final skull = o.translate(0, -r * 0.62);
      c
        ..drawCircle(skull, r * 0.32, fill(0xFFF3E9D2))
        ..drawRect(
          Rect.fromCenter(
            center: skull.translate(0, r * 0.27),
            width: r * 0.3,
            height: r * 0.18,
          ),
          fill(0xFFF3E9D2),
        )
        ..drawCircle(skull.translate(-r * 0.12, 0), r * 0.08, fill(0xFF1A1A1A))
        ..drawCircle(skull.translate(r * 0.12, 0), r * 0.08, fill(0xFF1A1A1A));
    case 16: // Teleport: a checker jumping through a portal ring
      c
        ..drawOval(
          Rect.fromCenter(
            center: o.translate(r * 0.45, 0),
            width: r * 0.7,
            height: r * 1.6,
          ),
          line(0xFFB79CFF, r * 0.16),
        )
        ..drawCircle(
          o.translate(-r * 0.5, r * 0.35),
          r * 0.38,
          fill(0xFFF3E9D2),
        )
        ..drawCircle(
          o.translate(-r * 0.5, r * 0.35),
          r * 0.38,
          line(0xFF8C6A48, r * 0.07),
        );
      final arc = Path()
        ..moveTo(o.dx - r * 0.45, o.dy - r * 0.1)
        ..quadraticBezierTo(
          o.dx - r * 0.1,
          o.dy - r * 0.9,
          o.dx + r * 0.3,
          o.dy - r * 0.3,
        );
      c.drawPath(arc, line(0xFFB79CFF, r * 0.1));
      arrowHead(
        o.translate(r * 0.3, -r * 0.3),
        0.9,
        r * 0.25,
        fill(0xFFB79CFF),
      );
    case 18: // Quicksand: a checker half sunk in sand, sinking arrows
      final top = o.translate(0, -r * 0.05);
      c
        ..drawCircle(top, r * 0.55, fill(0xFF5A3A22))
        ..drawCircle(top, r * 0.42, fill(0xFFF3E9D2))
        ..drawCircle(top, r * 0.22, line(0xFFB8A27A, r * 0.07));
      final sand = Path()
        ..moveTo(o.dx - r * 1.05, o.dy + r * 1.0)
        ..lineTo(o.dx - r * 1.05, o.dy + r * 0.2)
        ..quadraticBezierTo(
          o.dx - r * 0.5,
          o.dy + r * 0.02,
          o.dx,
          o.dy + r * 0.18,
        )
        ..quadraticBezierTo(
          o.dx + r * 0.5,
          o.dy + r * 0.34,
          o.dx + r * 1.05,
          o.dy + r * 0.16,
        )
        ..lineTo(o.dx + r * 1.05, o.dy + r * 1.0)
        ..close();
      c.drawPath(sand, fill(0xFFD9A85A));
      for (final d in const [
        Offset(-0.6, 0.55),
        Offset(0.1, 0.7),
        Offset(0.65, 0.5),
        Offset(-0.25, 0.85),
      ]) {
        c.drawCircle(o + d * r, r * 0.07, fill(0xFF9C6B30));
      }
      for (final x in const [-0.85, 0.85]) {
        final p = line(0xFFFF9F43, r * 0.1);
        c.drawLine(
          o.translate(x * r, -r * 0.85),
          o.translate(x * r, -r * 0.35),
          p,
        );
        arrowHead(
          o.translate(x * r, -r * 0.22),
          math.pi / 2,
          r * 0.22,
          fill(0xFFFF9F43),
        );
      }
    case 20: // Time Stop: a clock with frozen hands and a pause sign
      c
        ..drawCircle(o, r * 0.95, fill(0xFFF3E9D2))
        ..drawCircle(o, r * 0.95, line(0xFF4A90D9, r * 0.12))
        ..drawLine(o, o.translate(0, -r * 0.6), line(0xFF2A2A3A, r * 0.1))
        ..drawLine(o, o.translate(r * 0.45, 0), line(0xFF2A2A3A, r * 0.1));
      for (final dx in [-0.18, 0.18]) {
        c.drawRect(
          Rect.fromCenter(
            center: o.translate(dx * r + r * 0.55, r * 0.55),
            width: r * 0.16,
            height: r * 0.5,
          ),
          fill(0xFF4A90D9),
        );
      }
    case 32: // Vortex: a whirlpool funnel
      for (var i = 0; i < 4; i++) {
        c.drawOval(
          Rect.fromCenter(
            center: o.translate(0, -r * 0.55 + i * r * 0.38),
            width: r * (1.9 - i * 0.42),
            height: r * (0.42 - i * 0.06),
          ),
          line(0xFF3B8ED0, r * 0.11),
        );
      }
    case 35: // Tailwind: a die and a green "+1" arrow up
    case 36: // Headwind: a die and a red "−1" arrow down
      final up = glyph == 35;
      paintDie(c, o.translate(-r * 0.3, 0), r * 1.0, 4, bone);
      final col = up ? 0xFF3DBE6A : 0xFFE0453A;
      final x = o.dx + r * 0.6;
      c.drawLine(
        Offset(x, o.dy + (up ? r * 0.75 : -r * 0.75)),
        Offset(x, o.dy + (up ? -r * 0.35 : r * 0.35)),
        line(col, r * 0.2),
      );
      arrowHead(
        Offset(x, o.dy + (up ? -r * 0.85 : r * 0.85)),
        up ? -math.pi / 2 : math.pi / 2,
        r * 0.45,
        fill(col),
      );
    case 37: // Even Odds: a balance with two equal pans
      final p = line(0xFFFFD36B, r * 0.11);
      c
        ..drawLine(o.translate(0, -r * 0.75), o.translate(0, r * 0.8), p)
        ..drawLine(
          o.translate(-r * 0.85, -r * 0.45),
          o.translate(r * 0.85, -r * 0.45),
          p,
        )
        ..drawLine(
          o.translate(-r * 0.5, r * 0.85),
          o.translate(r * 0.5, r * 0.85),
          p,
        );
      for (final dx in [-0.65, 0.65]) {
        c.drawArc(
          Rect.fromCenter(
            center: o.translate(dx * r, -r * 0.05),
            width: r * 0.7,
            height: r * 0.5,
          ),
          0,
          math.pi,
          true,
          fill(0xFFFFD36B),
        );
      }
    case 39: // Twin Dice: two sixes side by side, glowing gold
      c.drawCircle(
        o,
        r * 1.1,
        Paint()
          ..color = const Color(0x66FFD36B)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, r * 0.3),
      );
      paintDie(c, o.translate(-r * 0.45, 0), r * 0.85, 6, bone, angle: -0.12);
      paintDie(c, o.translate(r * 0.45, 0), r * 0.85, 6, bone, angle: 0.12);
    case 41: // Silk Purse: a drawstring pouch with two tokens
      final pouch = Path()
        ..moveTo(o.dx - r * 0.35, o.dy - r * 0.45)
        ..quadraticBezierTo(
          o.dx - r * 1.05,
          o.dy + r * 0.2,
          o.dx - r * 0.6,
          o.dy + r * 0.85,
        )
        ..lineTo(o.dx + r * 0.6, o.dy + r * 0.85)
        ..quadraticBezierTo(
          o.dx + r * 1.05,
          o.dy + r * 0.2,
          o.dx + r * 0.35,
          o.dy - r * 0.45,
        )
        ..close();
      c
        ..drawPath(pouch, fill(0xFF8E5BD6))
        ..drawLine(
          o.translate(-r * 0.4, -r * 0.45),
          o.translate(r * 0.4, -r * 0.45),
          line(0xFFFFD36B, r * 0.1),
        );
      for (final dx in [-0.25, 0.25]) {
        c.drawCircle(o.translate(dx * r, r * 0.3), r * 0.22, fill(0xFFFFD36B));
      }
    case 43: // Shackle: an iron cuff chained to a heavy ball
      c
        ..drawCircle(
          o.translate(-r * 0.45, -r * 0.4),
          r * 0.38,
          line(0xFF9AA4AE, r * 0.16),
        )
        ..drawCircle(o.translate(r * 0.4, r * 0.4), r * 0.48, fill(0xFF3A3F47));
      for (var i = 0; i < 3; i++) {
        c.drawOval(
          Rect.fromCenter(
            center: o.translate(
              -r * 0.15 + i * r * 0.18,
              -r * 0.08 + i * r * 0.18,
            ),
            width: r * 0.24,
            height: r * 0.16,
          ),
          line(0xFF9AA4AE, r * 0.07),
        );
      }
    case 44: // Pickpocket: a hand grabbing a gold coin
      c.drawCircle(o.translate(r * 0.35, r * 0.35), r * 0.42, fill(0xFFFFD36B));
      final hand = fill(0xFFD9A07A);
      c.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: o.translate(-r * 0.3, -r * 0.2),
            width: r * 0.9,
            height: r * 0.75,
          ),
          Radius.circular(r * 0.25),
        ),
        hand,
      );
      for (var i = 0; i < 3; i++) {
        c.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(
              o.dx + r * 0.1,
              o.dy - r * 0.55 + i * r * 0.26,
              r * 0.55,
              r * 0.2,
            ),
            Radius.circular(r * 0.1),
          ),
          hand,
        );
      }
    case 47: // Shield Wall: three shields in a row
      shield(o.translate(-r * 0.62, r * 0.05), r * 0.5, 0xFFB8C2CC);
      shield(o.translate(r * 0.62, r * 0.05), r * 0.5, 0xFFB8C2CC);
      shield(o.translate(0, -r * 0.05), r * 0.58, 0xFFE8EDF2);
    case 51: // Caltrops: two striped toll barriers
      for (final dy in [-0.4, 0.4]) {
        final bar = Rect.fromCenter(
          center: o.translate(0, dy * r),
          width: r * 1.8,
          height: r * 0.34,
        );
        c.drawRect(bar, fill(0xFFF3E9D2));
        for (var i = 0; i < 4; i++) {
          c.drawRect(
            Rect.fromLTWH(
              bar.left + i * r * 0.45,
              bar.top,
              r * 0.22,
              bar.height,
            ),
            fill(0xFFE0453A),
          );
        }
      }
    case 63: // Mirage: a palm tree over its shimmering reflection
      final trunk = line(0xFF8C6A48, r * 0.12);
      final leaf = line(0xFF2E9E5A, r * 0.12);
      c.drawLine(
        o.translate(0, -r * 0.05),
        o.translate(r * 0.1, -r * 0.85),
        trunk,
      );
      for (var i = 0; i < 4; i++) {
        final a = math.pi + i * math.pi / 3;
        c.drawLine(
          o.translate(r * 0.1, -r * 0.85),
          o.translate(r * 0.1, -r * 0.85) +
              Offset(math.cos(a), math.sin(a)) * r * 0.55,
          leaf,
        );
      }
      for (var k = 0; k < 3; k++) {
        final y = o.dy + r * (0.25 + k * 0.25);
        final wave = Path()..moveTo(o.dx - r * 0.8, y);
        for (var s = 0; s < 4; s++) {
          wave.relativeQuadraticBezierTo(
            r * 0.2,
            s.isEven ? -r * 0.1 : r * 0.1,
            r * 0.4,
            0,
          );
        }
        c.drawPath(wave, line(0x997FD6E0, r * 0.08));
      }
    case 72: // Eclipse: a black sun with a blazing corona
      c
        ..drawCircle(
          o,
          r * 0.95,
          Paint()
            ..color = const Color(0xFFFFB347)
            ..maskFilter = MaskFilter.blur(BlurStyle.normal, r * 0.18),
        )
        ..drawCircle(o, r * 0.72, fill(0xFF0E0C14));
    case 52: // Bait: a thick fishing hook with a wriggling worm on it
      final hook = line(0xFFC9D1D8, r * 0.2);
      c
        ..drawLine(
          o.translate(r * 0.2, -r * 1.0),
          o.translate(r * 0.2, r * 0.3),
          hook,
        )
        ..drawArc(
          Rect.fromCircle(
            center: o.translate(-r * 0.2, r * 0.3),
            radius: r * 0.4,
          ),
          0,
          math.pi,
          false,
          hook,
        )
        ..drawCircle(
          o.translate(r * 0.2, -r * 1.0),
          r * 0.16,
          line(0xFFC9D1D8, r * 0.1),
        );
      arrowHead(
        o.translate(-r * 0.6, r * 0.05),
        -math.pi / 2,
        r * 0.3,
        fill(0xFFC9D1D8),
      );
      final worm = Path()
        ..moveTo(o.dx + r * 0.2, o.dy - r * 0.35)
        ..cubicTo(
          o.dx + r * 0.75,
          o.dy - r * 0.55,
          o.dx + r * 0.95,
          o.dy - r * 0.05,
          o.dx + r * 0.55,
          o.dy + r * 0.05,
        )
        ..cubicTo(
          o.dx + r * 0.2,
          o.dy + r * 0.15,
          o.dx + r * 0.5,
          o.dy + r * 0.6,
          o.dx + r * 0.9,
          o.dy + r * 0.55,
        );
      c.drawPath(worm, line(0xFFFF7A9C, r * 0.22));
    default:
      return false;
  }
  return true;
}
