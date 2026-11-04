import 'dart:math' as math;
import 'dart:ui' as ui;
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:haftnard/game/scene/fx.dart';
import 'package:haftnard/game/themes/board_themes.dart';

/// Loads the shared nebula shader once (best effort).
class Shaders {
  static ui.FragmentProgram? nebula;
  static bool _tried = false;

  static Future<void> load() async {
    if (_tried) return;
    _tried = true;
    try {
      nebula = await ui.FragmentProgram.fromAsset('shaders/nebula.frag');
    } on Object {
      nebula = null;
    }
  }

  /// Paints the nebula into [rect], falling back to a gradient.
  static void paintNebula(
    Canvas c,
    Rect rect,
    double time,
    Color a,
    Color b,
    Color d,
  ) {
    final prog = nebula;
    if (prog == null) {
      c.drawRect(
        rect,
        Paint()
          ..shader = ui.Gradient.radial(rect.center, rect.longestSide * 0.7, [
            b,
            a,
          ]),
      );
      return;
    }
    final sh = prog.fragmentShader()
      ..setFloat(0, rect.width)
      ..setFloat(1, rect.height)
      ..setFloat(2, time)
      ..setFloat(3, a.r)
      ..setFloat(4, a.g)
      ..setFloat(5, a.b)
      ..setFloat(6, 1)
      ..setFloat(7, b.r)
      ..setFloat(8, b.g)
      ..setFloat(9, b.b)
      ..setFloat(10, 1)
      ..setFloat(11, d.r)
      ..setFloat(12, d.g)
      ..setFloat(13, d.b)
      ..setFloat(14, 1);
    c.save();
    c.translate(rect.left, rect.top);
    c.drawRect(Offset.zero & rect.size, Paint()..shader = sh);
    c.restore();
  }
}

/// The animated world around the board.
class EnvironmentLayer extends Component {
  EnvironmentLayer({
    required this.envId,
    required this.fx,
    required this.boardRect,
    required this.reducedMotion,
  });

  String envId;
  final FxLayer fx;
  Rect Function() boardRect;
  bool reducedMotion;
  Size size = Size.zero;
  double time = 0;

  /// 0..1 burst of light (7–7, big hits).
  double flare = 0;

  /// -1 (losing badly) .. 1 (winning): darkens/brightens the scene.
  double mood = 0;
  double _shownMood = 0;
  double _emitAcc = 0;
  final _rng = math.Random(3);

  @override
  void update(double dt) {
    time += dt;
    flare = math.max(0, flare - dt * 0.6);
    _shownMood += (mood - _shownMood) * math.min(1, dt * 1.5);
    if (reducedMotion) return;
    _emitAcc += dt;
    final b = boardRect();
    while (_emitAcc > 0.08) {
      _emitAcc -= 0.08;
      _ambient(b);
    }
  }

  void _ambient(Rect b) {
    final w = size.width;
    final h = size.height;
    double r() => _rng.nextDouble();
    switch (envId) {
      case 'env_snowfall':
        fx.emit(
          Offset(r() * w, -5),
          Offset((r() - 0.5) * 20, 30 + r() * 30),
          color: const Color(0xDDFFFFFF),
          kind: ParticleKind.spark,
          size: 1 + r() * 2,
          life: h / 40,
        );
      case 'env_forge':
        if (r() < 0.7) {
          fx.emit(
            Offset(r() * w, h + 5),
            Offset((r() - 0.5) * 30, -40 - r() * 70),
            color: Color.lerp(
              const Color(0xFFFF7A1A),
              const Color(0xFFFFD36B),
              r(),
            )!,
            kind: ParticleKind.ember,
            size: 1 + r() * 2.5,
            life: 4,
          );
        }
      case 'env_cosmos':
        if (r() < 0.04) {
          fx.emit(
            Offset(r() * w, r() * h * 0.3),
            const Offset(260, 120),
            color: const Color(0xFFFFFFFF),
            kind: ParticleKind.spark,
            size: 1.5,
            life: 0.7,
          );
        }
      case 'env_desert_night':
        if (r() < 0.02) {
          fx.emit(
            Offset(r() * w, r() * h * 0.2),
            const Offset(-220, 90),
            color: const Color(0xFFFFF1C2),
            kind: ParticleKind.spark,
            size: 1.2,
            life: 0.8,
          );
        }
      case 'env_lantern_hall':
        if (r() < 0.25) {
          fx.emit(
            Offset(r() * w, r() * h),
            Offset((r() - 0.5) * 6, -4 - r() * 6),
            color: const Color(0x66FFD9A0),
            kind: ParticleKind.spark,
            size: 0.8 + r(),
            life: 5,
          );
        }
      default:
        break;
    }
  }

  @override
  void render(Canvas canvas) {
    final c = canvas;
    final rect = Offset.zero & size;
    if (size.isEmpty) return;
    switch (envId) {
      case 'env_desert_night':
        _desert(c, rect);
      case 'env_mosque_court':
        _mosque(c, rect);
      case 'env_neon_city':
        _neon(c, rect);
      case 'env_cosmos':
        Shaders.paintNebula(
          c,
          rect,
          time,
          const Color(0xFF07041A),
          const Color(0xFF2A1458),
          const Color(0xFF1FA3A3),
        );
      case 'env_snowfall':
        _snow(c, rect);
      case 'env_forge':
        _forge(c, rect);
      default:
        _lanternHall(c, rect);
    }
    // Mood tint and flare.
    final m = _shownMood;
    if (m < -0.05) {
      c.drawRect(
        rect,
        Paint()..color = Color.fromRGBO(10, 0, 20, (-m * 0.35).clamp(0, 0.35)),
      );
    }
    if (flare > 0) {
      c.drawRect(
        rect,
        Paint()
          ..shader = ui.Gradient.radial(rect.center, rect.longestSide * 0.7, [
            Color.fromRGBO(255, 211, 107, 0.35 * flare),
            const Color(0x00000000),
          ]),
      );
    }
  }

  void _lanternHall(Canvas c, Rect r) {
    c.drawRect(
      r,
      Paint()
        ..shader = ui.Gradient.radial(r.center, r.longestSide * 0.75, const [
          Color(0xFF3B1F14),
          Color(0xFF140A08),
        ]),
    );
    // Carpet under the board.
    final b = boardRect().inflate(r.width * 0.06);
    final carpet = RRect.fromRectAndRadius(b, const Radius.circular(10));
    c.drawRRect(carpet, Paint()..color = const Color(0xFF6E1420));
    final border = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..color = const Color(0xFF1C3D5A);
    c.drawRRect(carpet.deflate(6), border);
    final gold = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..color = const Color(0xFFD4AF37);
    c.drawRRect(carpet.deflate(11), gold);
    for (var x = b.left + 20; x < b.right - 10; x += 18) {
      BoardArt.star(
        c,
        Offset(x, b.top + 6),
        3,
        4,
        Paint()..color = const Color(0xFFE9CFA0),
      );
      BoardArt.star(
        c,
        Offset(x, b.bottom - 6),
        3,
        4,
        Paint()..color = const Color(0xFFE9CFA0),
      );
    }
    // Lanterns.
    final n = (r.width / 120).clamp(3, 6).round();
    for (var i = 0; i < n; i++) {
      final x = r.width * (i + 0.5) / n;
      final sway = math.sin(time * 0.9 + i * 1.3) * 0.08;
      final len = r.height * (0.06 + 0.03 * (i % 2));
      final top = Offset(x, 0);
      final end = top + Offset(math.sin(sway) * len, math.cos(sway) * len);
      c.drawLine(
        top,
        end,
        Paint()
          ..color = const Color(0xFF6B4A2B)
          ..strokeWidth = 1.5,
      );
      final glow = 0.55 + 0.15 * math.sin(time * 3 + i) + flare * 0.6;
      c.drawCircle(
        end + const Offset(0, 14),
        46 + flare * 30,
        Paint()
          ..color = Color.fromRGBO(255, 170, 80, 0.22 * glow)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 30),
      );
      final body = Rect.fromCenter(
        center: end + const Offset(0, 14),
        width: 18,
        height: 26,
      );
      c.drawRRect(
        RRect.fromRectAndRadius(body, const Radius.circular(8)),
        Paint()..color = Color.fromRGBO(255, 190, 110, glow.clamp(0, 1)),
      );
      c.drawRRect(
        RRect.fromRectAndRadius(body, const Radius.circular(8)),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5
          ..color = const Color(0xFF8C6418),
      );
      for (var k = -1; k <= 1; k++) {
        c.drawLine(
          body.topCenter + Offset(k * 5.0, 0),
          body.bottomCenter + Offset(k * 5.0, 0),
          Paint()
            ..strokeWidth = 1
            ..color = const Color(0xAA8C6418),
        );
      }
    }
  }

  void _desert(Canvas c, Rect r) {
    c.drawRect(
      r,
      Paint()
        ..shader = ui.Gradient.linear(
          r.topCenter,
          r.bottomCenter,
          const [Color(0xFF070A1E), Color(0xFF1B1F4A), Color(0xFF3A2A4A)],
          const [0, 0.6, 1],
        ),
    );
    final rng = ArtRng(42);
    final rot = time * 0.01;
    final ctr = Offset(r.width * 0.5, -r.height * 0.2);
    for (var i = 0; i < 120; i++) {
      final ang = rng.next() * math.pi * 2 + rot;
      final dist = rng.next() * r.longestSide;
      final p = ctr + Offset(math.cos(ang) * dist, math.sin(ang) * dist);
      final tw = 0.5 + 0.5 * math.sin(time * 2 + i);
      c.drawCircle(
        p,
        0.6 + rng.next(),
        Paint()..color = Color.fromRGBO(255, 255, 255, 0.4 + 0.5 * tw),
      );
    }
    for (var layer = 0; layer < 3; layer++) {
      final base = r.height * (0.78 + layer * 0.08);
      final shift = math.sin(time * 0.05 + layer) * 10 * (layer + 1);
      final path = Path()..moveTo(0, r.height);
      for (var x = 0.0; x <= r.width; x += 12) {
        path.lineTo(
          x,
          base + math.sin((x + shift) / (90 + layer * 30)) * (18 - layer * 4),
        );
      }
      path
        ..lineTo(r.width, r.height)
        ..close();
      c.drawPath(
        path,
        Paint()
          ..color = Color.lerp(
            const Color(0xFF3A2440),
            const Color(0xFF120A18),
            layer / 2,
          )!,
      );
    }
  }

  void _mosque(Canvas c, Rect r) {
    c.drawRect(
      r,
      Paint()
        ..shader = ui.Gradient.linear(r.topCenter, r.bottomCenter, const [
          Color(0xFF0B3A5C),
          Color(0xFF06243A),
        ]),
    );
    // Tile lattice.
    final tile = Paint()..color = const Color(0x2234C3C3);
    const s = 36.0;
    for (var x = 0.0; x < r.width + s; x += s) {
      for (var y = 0.0; y < r.height + s; y += s) {
        BoardArt.star(c, Offset(x, y), s * 0.32, 8, tile);
      }
    }
    // Arch.
    final arch = Path()
      ..moveTo(r.width * 0.12, r.height)
      ..lineTo(r.width * 0.12, r.height * 0.35)
      ..quadraticBezierTo(
        r.width * 0.12,
        r.height * 0.08,
        r.width * 0.5,
        r.height * 0.02,
      )
      ..quadraticBezierTo(
        r.width * 0.88,
        r.height * 0.08,
        r.width * 0.88,
        r.height * 0.35,
      )
      ..lineTo(r.width * 0.88, r.height);
    c.drawPath(
      arch,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 10
        ..color = const Color(0xFFE8C766),
    );
    // Light shafts.
    for (var i = 0; i < 4; i++) {
      final x = r.width * (0.25 + i * 0.17) + math.sin(time * 0.3 + i) * 10;
      final shaft = Path()
        ..moveTo(x, 0)
        ..lineTo(x + 30, 0)
        ..lineTo(x + 140, r.height)
        ..lineTo(x + 60, r.height)
        ..close();
      c.drawPath(
        shaft,
        Paint()
          ..color = Color.fromRGBO(
            255,
            240,
            200,
            0.05 + 0.03 * math.sin(time + i) + flare * 0.1,
          )
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12),
      );
    }
  }

  void _neon(Canvas c, Rect r) {
    c.drawRect(
      r,
      Paint()
        ..shader = ui.Gradient.linear(
          r.topCenter,
          r.bottomCenter,
          const [Color(0xFF0A0418), Color(0xFF2A0B3E), Color(0xFF0A0418)],
          const [0, 0.55, 1],
        ),
    );
    final sun = Offset(r.width / 2, r.height * 0.5);
    final sr = r.width * 0.32;
    c.save();
    c.clipRect(Rect.fromLTRB(0, 0, r.width, sun.dy));
    c.drawCircle(
      sun,
      sr,
      Paint()
        ..shader = ui.Gradient.linear(sun - Offset(0, sr), sun, const [
          Color(0xFFFFD36B),
          Color(0xFFFF3EC8),
        ]),
    );
    for (var i = 0; i < 6; i++) {
      final y = sun.dy - sr * 0.5 + i * sr * 0.1;
      c.drawRect(
        Rect.fromLTWH(0, y, r.width, 2 + i * 1.2),
        Paint()..color = const Color(0xFF2A0B3E),
      );
    }
    c.restore();
    // Perspective grid floor.
    final p = Paint()
      ..color = const Color(0xAA29F6FF)
      ..strokeWidth = 1.2;
    final horizon = sun.dy;
    for (var i = -12; i <= 12; i++) {
      c.drawLine(
        Offset(r.width / 2 + i * 8, horizon),
        Offset(r.width / 2 + i * r.width * 0.12, r.height),
        p,
      );
    }
    final scroll = (time * 0.4) % 1;
    for (var k = 0; k < 10; k++) {
      final u = (k + scroll) / 10;
      final y = horizon + (r.height - horizon) * u * u;
      c.drawLine(Offset(0, y), Offset(r.width, y), p);
    }
  }

  void _snow(Canvas c, Rect r) {
    c.drawRect(
      r,
      Paint()
        ..shader = ui.Gradient.linear(r.topCenter, r.bottomCenter, const [
          Color(0xFF2B4B6A),
          Color(0xFF8FB4CC),
        ]),
    );
    final rng = ArtRng(9);
    for (var i = 0; i < 5; i++) {
      final x = rng.next() * r.width;
      final h = r.height * (0.15 + rng.next() * 0.2);
      final path = Path()
        ..moveTo(x, r.height)
        ..lineTo(x - 30, r.height)
        ..lineTo(x, r.height - h)
        ..lineTo(x + 30, r.height)
        ..close();
      c.drawPath(path, Paint()..color = const Color(0x55E8F7FF));
    }
  }

  void _forge(Canvas c, Rect r) {
    c.drawRect(
      r,
      Paint()
        ..shader = ui.Gradient.linear(r.topCenter, r.bottomCenter, const [
          Color(0xFF0E0B0A),
          Color(0xFF2A1208),
        ]),
    );
    final glow =
        0.6 +
        0.2 * math.sin(time * 1.7) +
        0.1 * math.sin(time * 4.3) +
        flare * 0.5;
    c.drawRect(
      Rect.fromLTWH(0, r.height * 0.7, r.width, r.height * 0.3),
      Paint()
        ..shader = ui.Gradient.linear(
          Offset(0, r.height),
          Offset(0, r.height * 0.6),
          [Color.fromRGBO(255, 110, 30, 0.5 * glow), const Color(0x00000000)],
        ),
    );
  }
}
