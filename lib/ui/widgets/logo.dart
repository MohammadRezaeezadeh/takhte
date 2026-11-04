import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:haftnard/game/themes/pieces.dart';
import 'package:haftnard/ui/theme.dart';

/// Game logo: the glowing seven-pip die and the bilingual wordmark.
class HaftNardLogo extends StatefulWidget {
  const HaftNardLogo({super.key, this.size = 1});
  final double size;

  @override
  State<HaftNardLogo> createState() => _HaftNardLogoState();
}

class _HaftNardLogoState extends State<HaftNardLogo>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 8),
  )..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.size;
    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) {
        final t = _c.value * 8;
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 92 * s,
              height: 92 * s,
              child: CustomPaint(painter: _DiePainter(t)),
            ),
            SizedBox(height: 4 * s),
            Text(
              'هفت‌نرد',
              textDirection: TextDirection.rtl,
              style: TextStyle(
                fontFamily: AppFonts.display,
                fontSize: 64 * s,
                height: 1.05,
                color: AppColors.goldLight,
                shadows: [
                  Shadow(
                    blurRadius: 18 + 6 * math.sin(t * 2),
                    color: const Color(0xAAFFB347),
                  ),
                  const Shadow(
                    offset: Offset(0, 3),
                    blurRadius: 2,
                    color: Colors.black87,
                  ),
                ],
              ),
            ),
            Text(
              'HAFTNARD',
              style: TextStyle(
                fontFamily: AppFonts.logoLatin,
                fontSize: 22 * s,
                letterSpacing: 6 * s,
                color: AppColors.ivory.withValues(alpha: 0.9),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _DiePainter extends CustomPainter {
  _DiePainter(this.t);
  final double t;
  @override
  void paint(Canvas canvas, Size size) {
    paintDie(
      canvas,
      size.center(Offset.zero),
      size.shortestSide * 0.7,
      7,
      kDiceStyles['dice_bone']!,
      angle: math.sin(t * 0.8) * 0.12,
      time: t,
    );
  }

  @override
  bool shouldRepaint(covariant _DiePainter old) => old.t != t;
}
