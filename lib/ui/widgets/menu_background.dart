import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:haftnard/game/themes/board_themes.dart';
import 'package:haftnard/ui/theme.dart';

/// Living backdrop for menus: slowly rotating girih rosette, drifting motes
/// and a breathing glow.
class MenuBackground extends StatefulWidget {
  const MenuBackground({super.key, this.child, this.hue = 0});
  final Widget? child;
  final double hue;

  @override
  State<MenuBackground> createState() => _MenuBackgroundState();
}

class _MenuBackgroundState extends State<MenuBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 60),
  )..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduce = MediaQuery.of(context).disableAnimations;
    return Stack(
      fit: StackFit.expand,
      children: [
        RepaintBoundary(
          child: AnimatedBuilder(
            animation: _c,
            builder: (_, _) =>
                CustomPaint(painter: _MenuPainter(reduce ? 0 : _c.value * 60)),
          ),
        ),
        if (widget.child != null) widget.child!,
      ],
    );
  }
}

class _MenuPainter extends CustomPainter {
  _MenuPainter(this.t);
  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawRect(
      rect,
      Paint()
        ..shader = const RadialGradient(
          center: Alignment(0, -0.3),
          radius: 1.1,
          colors: [Color(0xFF22184A), Color(0xFF0E1230), AppColors.night],
          stops: [0, 0.5, 1],
        ).createShader(rect),
    );
    // Tile lattice.
    final lattice = Paint()..color = const Color(0x0FFFFFFF);
    const s = 48.0;
    for (var y = 0.0; y < size.height + s; y += s) {
      for (
        var x = ((y / s).round().isOdd ? s / 2 : 0.0);
        x < size.width + s;
        x += s
      ) {
        BoardArt.star(canvas, Offset(x, y), s * 0.3, 8, lattice);
      }
    }
    // Rotating rosette.
    final c = Offset(size.width / 2, size.height * 0.3);
    final r = size.shortestSide * 0.62;
    canvas.save();
    canvas.translate(c.dx, c.dy);
    canvas.rotate(t * 0.03);
    final ring = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..color = AppColors.gold.withValues(alpha: 0.12);
    for (var k = 0; k < 4; k++) {
      final rr = r * (0.35 + k * 0.2);
      final path = Path();
      const n = 16;
      for (var i = 0; i <= n * 2; i++) {
        final a = math.pi * i / n;
        final rad = i.isEven ? rr : rr * 0.82;
        final p = Offset(math.cos(a), math.sin(a)) * rad;
        if (i == 0) {
          path.moveTo(p.dx, p.dy);
        } else {
          path.lineTo(p.dx, p.dy);
        }
      }
      canvas.drawPath(path, ring);
    }
    canvas.restore();
    // Glow.
    final glow = 0.15 + 0.05 * math.sin(t * 0.8);
    canvas.drawCircle(
      c,
      r * 0.6,
      Paint()
        ..color = AppColors.goldLight.withValues(alpha: glow)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 80),
    );
    // Drifting motes.
    final rng = ArtRng(77);
    for (var i = 0; i < 60; i++) {
      final x0 = rng.next() * size.width;
      final y0 = rng.next() * size.height;
      final sp = 4 + rng.next() * 10;
      final y = (y0 - t * sp) % size.height;
      final x = x0 + math.sin(t * 0.3 + i) * 10;
      final a = 0.2 + 0.4 * (0.5 + 0.5 * math.sin(t + i));
      canvas.drawCircle(
        Offset(x, y),
        0.8 + rng.next() * 1.6,
        Paint()..color = AppColors.goldLight.withValues(alpha: a),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _MenuPainter old) => old.t != t;
}
