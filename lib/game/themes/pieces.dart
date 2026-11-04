import 'dart:math' as math;
import 'dart:ui' as ui;
import 'dart:ui';

import 'package:haftnard/core/rules/types.dart';
import 'package:haftnard/game/themes/board_themes.dart';

enum CheckerMaterial {
  wood,
  glass,
  jade,
  obsidian,
  pearl,
  neon,
  coin,
  gem,
  comet,
}

class CheckerStyle {
  const CheckerStyle({
    required this.id,
    required this.material,
    required this.light,
    required this.lightEdge,
    required this.dark,
    required this.darkEdge,
    this.trail = false,
    this.glowOnHit = false,
  });

  final String id;
  final CheckerMaterial material;
  final Color light;
  final Color lightEdge;
  final Color dark;
  final Color darkEdge;
  final bool trail;
  final bool glowOnHit;

  Color base(Side s) => s == Side.white ? light : dark;
  Color edge(Side s) => s == Side.white ? lightEdge : darkEdge;
}

const Map<String, CheckerStyle> kCheckerStyles = {
  'chk_wood': CheckerStyle(
    id: 'chk_wood',
    material: CheckerMaterial.wood,
    light: Color(0xFFE9CFA0),
    lightEdge: Color(0xFFB58A55),
    dark: Color(0xFF5A3420),
    darkEdge: Color(0xFF2E180C),
  ),
  'chk_glass': CheckerStyle(
    id: 'chk_glass',
    material: CheckerMaterial.glass,
    light: Color(0xCCE6F4FF),
    lightEdge: Color(0xFF9CC9E8),
    dark: Color(0xCC2A2560),
    darkEdge: Color(0xFF6A5FD0),
  ),
  'chk_jade': CheckerStyle(
    id: 'chk_jade',
    material: CheckerMaterial.jade,
    light: Color(0xFF7FCB9E),
    lightEdge: Color(0xFF3E8C63),
    dark: Color(0xFF2B2228),
    darkEdge: Color(0xFF8A2E3A),
  ),
  'chk_obsidian': CheckerStyle(
    id: 'chk_obsidian',
    material: CheckerMaterial.obsidian,
    light: Color(0xFFF4EBDA),
    lightEdge: Color(0xFFCDBB97),
    dark: Color(0xFF121216),
    darkEdge: Color(0xFF5A5A70),
  ),
  'chk_pearl': CheckerStyle(
    id: 'chk_pearl',
    material: CheckerMaterial.pearl,
    light: Color(0xFFF7F1EC),
    lightEdge: Color(0xFFE2CFE6),
    dark: Color(0xFF1F3C8C),
    darkEdge: Color(0xFFD4AF37),
  ),
  'chk_neon': CheckerStyle(
    id: 'chk_neon',
    material: CheckerMaterial.neon,
    light: Color(0xFF29F6FF),
    lightEdge: Color(0xFF0A1830),
    dark: Color(0xFFFF3EC8),
    darkEdge: Color(0xFF1A0820),
  ),
  'chk_coin': CheckerStyle(
    id: 'chk_coin',
    material: CheckerMaterial.coin,
    light: Color(0xFFE8E8EE),
    lightEdge: Color(0xFF9A9AA8),
    dark: Color(0xFFE2B33C),
    darkEdge: Color(0xFF8C6418),
  ),
  'chk_gem': CheckerStyle(
    id: 'chk_gem',
    material: CheckerMaterial.gem,
    light: Color(0xFF3FD18A),
    lightEdge: Color(0xFF0E6B3E),
    dark: Color(0xFFD12E4A),
    darkEdge: Color(0xFF6E0E20),
  ),
  'chk_comet': CheckerStyle(
    id: 'chk_comet',
    material: CheckerMaterial.comet,
    light: Color(0xFFFFF1C2),
    lightEdge: Color(0xFFFFB347),
    dark: Color(0xFF3A1E6E),
    darkEdge: Color(0xFF9D7BFF),
    trail: true,
    glowOnHit: true,
  ),
};

CheckerStyle checkerStyle(String id) =>
    kCheckerStyles[id] ?? kCheckerStyles['chk_wood']!;

/// Draws a checker of [side] centred at [c] with radius [r].
void paintChecker(
  Canvas canvas,
  Offset c,
  double r,
  Side side,
  CheckerStyle st, {
  double squash = 1,
  double lift = 0,
  bool selected = false,
  Color? glow,
  double time = 0,
}) {
  final base = st.base(side);
  final edge = st.edge(side);
  canvas.save();
  canvas.translate(c.dx, c.dy);
  canvas.scale(1 / math.sqrt(squash), squash);
  // Shadow grows with lift.
  canvas.drawCircle(
    Offset(lift * 0.25, r * 0.12 + lift * 0.5),
    r * (1 + lift * 0.01),
    Paint()
      ..color = Color.fromRGBO(0, 0, 0, 0.45 - math.min(lift, 30) * 0.008)
      ..maskFilter = MaskFilter.blur(
        BlurStyle.normal,
        _q(r * 0.18 + lift * 0.15),
      ),
  );
  if (glow != null || selected) {
    canvas.drawCircle(
      Offset.zero,
      r * 1.18,
      Paint()
        ..color = (glow ?? const Color(0xFFFFE08A)).withValues(alpha: 0.75)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, r * 0.35),
    );
  }
  switch (st.material) {
    case CheckerMaterial.neon:
      canvas.drawCircle(Offset.zero, r, Paint()..color = edge);
      final pulse = 0.75 + 0.25 * math.sin(time * 3 + (side.index * 1.7));
      canvas.drawCircle(
        Offset.zero,
        r * 0.8,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = r * 0.18
          ..color = base.withValues(alpha: pulse)
          ..maskFilter = MaskFilter.blur(BlurStyle.solid, r * 0.2),
      );
      canvas.drawCircle(
        Offset.zero,
        r * 0.38,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = r * 0.08
          ..color = base.withValues(alpha: 0.7),
      );
    case CheckerMaterial.coin:
      canvas.drawCircle(
        Offset.zero,
        r,
        Paint()
          ..shader = ui.Gradient.radial(
            Offset(-r * 0.3, -r * 0.35),
            r * 1.4,
            [Color.lerp(base, const Color(0xFFFFFFFF), 0.5)!, base, edge],
            [0, 0.55, 1],
          ),
      );
      final ridge = Paint()
        ..color = edge.withValues(alpha: 0.8)
        ..strokeWidth = r * 0.05;
      for (var i = 0; i < 36; i++) {
        final a = i * math.pi / 18;
        canvas.drawLine(
          Offset(math.cos(a), math.sin(a)) * r * 0.9,
          Offset(math.cos(a), math.sin(a)) * r,
          ridge,
        );
      }
      canvas.drawCircle(
        Offset.zero,
        r * 0.7,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = r * 0.06
          ..color = edge,
      );
      BoardArt.star(canvas, Offset.zero, r * 0.42, 6, Paint()..color = edge);
    case CheckerMaterial.gem:
      canvas.drawCircle(Offset.zero, r, Paint()..color = edge);
      const facets = 8;
      for (var i = 0; i < facets; i++) {
        final a0 = i * 2 * math.pi / facets;
        final a1 = (i + 1) * 2 * math.pi / facets;
        final path = Path()
          ..moveTo(0, 0)
          ..lineTo(math.cos(a0) * r * 0.92, math.sin(a0) * r * 0.92)
          ..lineTo(math.cos(a1) * r * 0.92, math.sin(a1) * r * 0.92)
          ..close();
        final shade = 0.5 + 0.5 * math.cos(a0 - 2.3);
        canvas.drawPath(
          path,
          Paint()
            ..color = Color.lerp(
              Color.lerp(base, const Color(0xFF000000), 0.35),
              Color.lerp(base, const Color(0xFFFFFFFF), 0.35),
              shade,
            )!,
        );
      }
      final table = Path();
      for (var i = 0; i < facets; i++) {
        final a = i * 2 * math.pi / facets + math.pi / facets;
        final p = Offset(math.cos(a), math.sin(a)) * r * 0.48;
        if (i == 0) {
          table.moveTo(p.dx, p.dy);
        } else {
          table.lineTo(p.dx, p.dy);
        }
      }
      table.close();
      canvas.drawPath(table, Paint()..color = base);
    default:
      // Body with soft radial shading.
      final translucent =
          st.material == CheckerMaterial.glass ||
          st.material == CheckerMaterial.comet;
      canvas.drawCircle(
        Offset.zero,
        r,
        Paint()
          ..shader = ui.Gradient.radial(
            Offset(-r * 0.25, -r * 0.3),
            r * 1.3,
            [
              Color.lerp(
                base,
                const Color(0xFFFFFFFF),
                translucent ? 0.6 : 0.25,
              )!,
              base,
              edge,
            ],
            const [0, 0.6, 1],
          ),
      );
      // Rim.
      canvas.drawCircle(
        Offset.zero,
        r * 0.97,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = r * 0.07
          ..color = edge,
      );
      // Inner groove ring.
      canvas.drawCircle(
        Offset.zero,
        r * 0.68,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = r * 0.06
          ..color = Color.lerp(edge, base, 0.4)!.withValues(alpha: 0.8),
      );
      switch (st.material) {
        case CheckerMaterial.wood:
          final grain = Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = r * 0.03
            ..color = edge.withValues(alpha: 0.35);
          for (var k = 1; k <= 3; k++) {
            canvas.drawOval(
              Rect.fromCenter(
                center: Offset(r * 0.08, r * 0.05),
                width: r * 0.35 * k,
                height: r * 0.28 * k,
              ),
              grain,
            );
          }
        case CheckerMaterial.jade:
        case CheckerMaterial.obsidian:
          canvas.drawCircle(
            Offset.zero,
            r * 0.32,
            Paint()..color = edge.withValues(alpha: 0.5),
          );
        case CheckerMaterial.pearl:
          // Iridescent sheen.
          canvas.drawCircle(
            Offset.zero,
            r * 0.9,
            Paint()
              ..shader = ui.Gradient.sweep(
                Offset.zero,
                const [
                  Color(0x22FF9AD5),
                  Color(0x229AD5FF),
                  Color(0x22B5FF9A),
                  Color(0x22FF9AD5),
                ],
                const [0, 0.33, 0.66, 1],
              ),
          );
          BoardArt.star(
            canvas,
            Offset.zero,
            r * 0.3,
            8,
            Paint()..color = edge.withValues(alpha: 0.6),
          );
        default:
          break;
      }
      // Specular highlight.
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(-r * 0.32, -r * 0.4),
          width: r * 0.7,
          height: r * 0.38,
        ),
        Paint()
          ..color = const Color(0x66FFFFFF)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, r * 0.08),
      );
  }
  // Outline for readability on any board.
  canvas.drawCircle(
    Offset.zero,
    r,
    Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(1, r * 0.05)
      ..color = side == Side.white
          ? const Color(0x99000000)
          : const Color(0x66FFFFFF),
  );
  if (selected) {
    canvas.drawCircle(
      Offset.zero,
      r * 1.06,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = r * 0.12
        ..color = const Color(0xFFFFE08A),
    );
  }
  canvas.restore();
}

/// A borne-off checker drawn edge-on in the tray.
void paintCheckerSlab(Canvas canvas, Rect r, Side side, CheckerStyle st) {
  final rr = RRect.fromRectAndRadius(r, Radius.circular(r.height * 0.45));
  canvas.drawRRect(
    rr,
    Paint()
      ..shader = ui.Gradient.linear(r.topCenter, r.bottomCenter, [
        Color.lerp(st.base(side), const Color(0xFFFFFFFF), 0.3)!,
        st.edge(side),
      ]),
  );
  canvas.drawRRect(
    rr,
    Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8
      ..color = const Color(0x88000000),
  );
}

enum DiceMaterial { bone, wood, crystal, gold, pixel, ember, smoke }

class DiceStyle {
  const DiceStyle({
    required this.id,
    required this.material,
    required this.face,
    required this.faceEdge,
    required this.pip,
    this.effect = DiceEffect.none,
  });
  final String id;
  final DiceMaterial material;
  final Color face;
  final Color faceEdge;
  final Color pip;
  final DiceEffect effect;
}

enum DiceEffect { none, sparks, smoke }

const Map<String, DiceStyle> kDiceStyles = {
  'dice_bone': DiceStyle(
    id: 'dice_bone',
    material: DiceMaterial.bone,
    face: Color(0xFFF6EEDC),
    faceEdge: Color(0xFFCDBF9F),
    pip: Color(0xFF2A1A12),
  ),
  'dice_wood': DiceStyle(
    id: 'dice_wood',
    material: DiceMaterial.wood,
    face: Color(0xFFB07B47),
    faceEdge: Color(0xFF6E4524),
    pip: Color(0xFFF3E1BC),
  ),
  'dice_crystal': DiceStyle(
    id: 'dice_crystal',
    material: DiceMaterial.crystal,
    face: Color(0xCC8FD3FF),
    faceEdge: Color(0xFF3F7FC0),
    pip: Color(0xFFFFFFFF),
  ),
  'dice_gold': DiceStyle(
    id: 'dice_gold',
    material: DiceMaterial.gold,
    face: Color(0xFFE9C25A),
    faceEdge: Color(0xFF9A6E1C),
    pip: Color(0xFF3A230A),
  ),
  'dice_pixel': DiceStyle(
    id: 'dice_pixel',
    material: DiceMaterial.pixel,
    face: Color(0xFF1B1F3A),
    faceEdge: Color(0xFF7CFFB2),
    pip: Color(0xFF7CFFB2),
  ),
  'dice_ember': DiceStyle(
    id: 'dice_ember',
    material: DiceMaterial.ember,
    face: Color(0xFF2A2220),
    faceEdge: Color(0xFFFF7A1A),
    pip: Color(0xFFFFA24D),
    effect: DiceEffect.sparks,
  ),
  'dice_smoke': DiceStyle(
    id: 'dice_smoke',
    material: DiceMaterial.smoke,
    face: Color(0xFF3A2266),
    faceEdge: Color(0xFFB79CFF),
    pip: Color(0xFFF0E6FF),
    effect: DiceEffect.smoke,
  ),
};

DiceStyle diceStyle(String id) => kDiceStyles[id] ?? kDiceStyles['dice_bone']!;

const _pipLayout = <int, List<Offset>>{
  1: [Offset.zero],
  2: [Offset(-1, -1), Offset(1, 1)],
  3: [Offset(-1, -1), Offset.zero, Offset(1, 1)],
  4: [Offset(-1, -1), Offset(1, -1), Offset(-1, 1), Offset(1, 1)],
  5: [Offset(-1, -1), Offset(1, -1), Offset.zero, Offset(-1, 1), Offset(1, 1)],
  6: [
    Offset(-1, -1),
    Offset(1, -1),
    Offset(-1, 0),
    Offset(1, 0),
    Offset(-1, 1),
    Offset(1, 1),
  ],
};

/// Draws a die showing [value] (7 = the glowing seven face).
void paintDie(
  Canvas canvas,
  Offset c,
  double size,
  int value,
  DiceStyle st, {
  double angle = 0,
  bool used = false,
  double time = 0,
  double lift = 0,
  double blur = 0,
}) {
  canvas.save();
  canvas.translate(c.dx, c.dy);
  canvas.rotate(angle);
  final s = size;
  // While tumbling the face is a spin blur: no readable pips until it lands.
  final pipsHidden = blur >= 0.99;
  final rect = Rect.fromCenter(center: Offset.zero, width: s, height: s);
  final rr = RRect.fromRectAndRadius(rect, Radius.circular(s * 0.2));
  // Shadow.
  canvas.drawRRect(
    rr.shift(Offset(s * 0.05 + lift * 0.2, s * 0.08 + lift * 0.4)),
    Paint()
      ..color = const Color(0x77000000)
      ..maskFilter = MaskFilter.blur(
        BlurStyle.normal,
        _q(s * 0.08 + lift * 0.1),
      ),
  );
  final seven = value == 7;
  if (seven) {
    final pulse = 0.7 + 0.3 * math.sin(time * 6);
    canvas.drawRRect(
      rr.inflate(s * 0.12),
      Paint()
        ..color = const Color(0xFFFFD36B).withValues(alpha: pulse)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, s * 0.25),
    );
  }
  final face = seven ? const Color(0xFF2A1450) : st.face;
  final edge = seven ? const Color(0xFFFFD36B) : st.faceEdge;
  canvas.drawRRect(
    rr,
    Paint()
      ..shader = ui.Gradient.linear(
        rect.topLeft,
        rect.bottomRight,
        [
          Color.lerp(face, const Color(0xFFFFFFFF), 0.25)!,
          face,
          Color.lerp(face, edge, 0.6)!,
        ],
        const [0, 0.55, 1],
      ),
  );
  canvas.drawRRect(
    rr,
    Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = s * 0.05
      ..color = edge,
  );
  if (st.material == DiceMaterial.crystal && !seven) {
    canvas.drawLine(
      Offset(-s * 0.3, -s * 0.38),
      Offset(s * 0.35, -s * 0.38),
      Paint()
        ..strokeWidth = s * 0.05
        ..color = const Color(0x88FFFFFF),
    );
  }
  final pipColor = seven ? const Color(0xFFFFE9A8) : st.pip;
  final pipR = s * 0.085;
  final g = s * 0.26;
  final pipPaint = Paint()..color = pipColor;
  if (blur > 0) {
    final streak = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = pipR * 1.6
      ..color = pipColor.withValues(alpha: 0.35 * blur);
    for (final (r, a0) in [(g * 0.55, 0.0), (g * 1.05, 2.1), (g * 1.4, 4.2)]) {
      canvas.drawArc(
        Rect.fromCircle(center: Offset.zero, radius: r),
        a0 - angle * 0.5,
        1.3,
        false,
        streak,
      );
    }
  }
  if (pipsHidden) {
    // Spin blur only.
  } else if (blur > 0) {
    canvas.saveLayer(
      rect,
      Paint()..color = Color.fromRGBO(0, 0, 0, (1 - blur).clamp(0.0, 1.0)),
    );
  }
  if (pipsHidden) {
    // Nothing readable while tumbling.
  } else if (seven) {
    // Seven pips: a flower of six around one, glowing.
    final glow = Paint()
      ..color = const Color(0xFFFFD36B)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, pipR * 0.8);
    final pts = <Offset>[Offset.zero];
    for (var i = 0; i < 6; i++) {
      final a = i * math.pi / 3 + time * 0.8;
      pts.add(Offset(math.cos(a), math.sin(a)) * g * 1.1);
    }
    for (final p in pts) {
      canvas.drawCircle(p, pipR * 1.2, glow);
      canvas.drawCircle(p, pipR, pipPaint);
    }
  } else if (st.material == DiceMaterial.pixel) {
    for (final o in _pipLayout[value.clamp(1, 6)]!) {
      canvas.drawRect(
        Rect.fromCenter(center: o * g, width: pipR * 2, height: pipR * 2),
        pipPaint,
      );
    }
  } else {
    final glowPips =
        st.material == DiceMaterial.ember || st.material == DiceMaterial.smoke;
    for (final o in _pipLayout[value.clamp(1, 6)]!) {
      if (glowPips) {
        canvas.drawCircle(
          o * g,
          pipR * 1.3,
          Paint()
            ..color = st.pip.withValues(alpha: 0.6)
            ..maskFilter = MaskFilter.blur(BlurStyle.normal, pipR),
        );
      }
      canvas.drawCircle(o * g, pipR, pipPaint);
      // Recessed look.
      canvas.drawCircle(
        o * g + Offset(-pipR * 0.25, -pipR * 0.25),
        pipR * 0.35,
        Paint()..color = const Color(0x33FFFFFF),
      );
    }
  }
  if (!pipsHidden && blur > 0) canvas.restore();
  if (used) {
    canvas.drawRRect(rr, Paint()..color = const Color(0x99000000));
  }
  canvas.restore();
}

/// Blur sigmas snapped to 0.5 px: a lift-dependent shadow otherwise asks the
/// renderer for a new blur mask every frame, which bloats its caches.
double _q(double sigma) => (sigma * 2).roundToDouble() / 2;
