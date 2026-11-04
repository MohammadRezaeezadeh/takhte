import 'dart:math' as math;
import 'dart:ui' as ui;
import 'dart:ui';

import 'package:haftnard/game/layout.dart';

enum BoardPattern {
  khatam,
  caravanserai,
  turquoise,
  neon,
  marble,
  cosmic,
  frost,
  ember,
  garden,
}

/// Art direction for a board.
class BoardThemeData {
  const BoardThemeData({
    required this.id,
    required this.pattern,
    required this.frameA,
    required this.frameB,
    required this.inlay,
    required this.feltA,
    required this.feltB,
    required this.pointA,
    required this.pointB,
    required this.pointEdge,
    required this.barA,
    required this.barB,
    required this.highlight,
    required this.glow,
    this.label = const Color(0xCCF3E9D2),
    this.pitch = 1.0,
    this.nebulaA = const Color(0xFF120A2E),
    this.nebulaB = const Color(0xFF3B1C6E),
    this.nebulaC = const Color(0xFF2EC4D6),
  });

  final String id;
  final BoardPattern pattern;
  final Color frameA;
  final Color frameB;
  final Color inlay;
  final Color feltA;
  final Color feltB;
  final Color pointA;
  final Color pointB;
  final Color pointEdge;
  final Color barA;
  final Color barB;

  /// Legal-destination highlight.
  final Color highlight;

  /// Ambient/accent glow (used for 7–7 flares, selection).
  final Color glow;
  final Color label;

  /// Sound tint: playback rate for checker sounds.
  final double pitch;
  final Color nebulaA;
  final Color nebulaB;
  final Color nebulaC;

  bool get animated =>
      pattern == BoardPattern.cosmic ||
      pattern == BoardPattern.neon ||
      pattern == BoardPattern.ember ||
      pattern == BoardPattern.caravanserai ||
      pattern == BoardPattern.frost;
}

const Map<String, BoardThemeData> kBoardThemes = {
  'board_khatam': BoardThemeData(
    id: 'board_khatam',
    pattern: BoardPattern.khatam,
    frameA: Color(0xFF4A2716),
    frameB: Color(0xFF26120A),
    inlay: Color(0xFFD4AF37),
    feltA: Color(0xFF5C1A22),
    feltB: Color(0xFF3A0E15),
    pointA: Color(0xFFEFE2C4),
    pointB: Color(0xFF1C3D5A),
    pointEdge: Color(0xFFC9A646),
    barA: Color(0xFF3B1E10),
    barB: Color(0xFF1E0E07),
    highlight: Color(0xFF7CFFB2),
    glow: Color(0xFFFFD36B),
  ),
  'board_caravanserai': BoardThemeData(
    id: 'board_caravanserai',
    pattern: BoardPattern.caravanserai,
    frameA: Color(0xFF8C6A48),
    frameB: Color(0xFF5A402A),
    inlay: Color(0xFFFFB45E),
    feltA: Color(0xFF14183A),
    feltB: Color(0xFF070A1E),
    pointA: Color(0xFFD9B98C),
    pointB: Color(0xFF7A4B2A),
    pointEdge: Color(0xFFFFC27A),
    barA: Color(0xFF6E5034),
    barB: Color(0xFF3E2A18),
    highlight: Color(0xFFFFE08A),
    glow: Color(0xFFFF9E3D),
    pitch: 0.92,
  ),
  'board_turquoise': BoardThemeData(
    id: 'board_turquoise',
    pattern: BoardPattern.turquoise,
    frameA: Color(0xFF0F6E78),
    frameB: Color(0xFF07434A),
    inlay: Color(0xFFE8C766),
    feltA: Color(0xFF0B2C4A),
    feltB: Color(0xFF061A2E),
    pointA: Color(0xFF34C3C3),
    pointB: Color(0xFFF2EAD3),
    pointEdge: Color(0xFFE8C766),
    barA: Color(0xFF0A5560),
    barB: Color(0xFF053238),
    highlight: Color(0xFFFFF27A),
    glow: Color(0xFF6CF2FF),
    pitch: 1.08,
  ),
  'board_neon': BoardThemeData(
    id: 'board_neon',
    pattern: BoardPattern.neon,
    frameA: Color(0xFF1A0B2E),
    frameB: Color(0xFF0A0418),
    inlay: Color(0xFFFF3EC8),
    feltA: Color(0xFF0D0A24),
    feltB: Color(0xFF05030F),
    pointA: Color(0xFF29F6FF),
    pointB: Color(0xFFFF3EC8),
    pointEdge: Color(0xFFFFFFFF),
    barA: Color(0xFF190A30),
    barB: Color(0xFF0A0418),
    highlight: Color(0xFFB6FF3E),
    glow: Color(0xFFFF3EC8),
    label: Color(0xCC29F6FF),
    pitch: 1.2,
  ),
  'board_marble': BoardThemeData(
    id: 'board_marble',
    pattern: BoardPattern.marble,
    frameA: Color(0xFFF4F1EA),
    frameB: Color(0xFFCFC8BA),
    inlay: Color(0xFFC8A04A),
    feltA: Color(0xFFE9E4D8),
    feltB: Color(0xFFD5CEBF),
    pointA: Color(0xFF2B2A33),
    pointB: Color(0xFFB8913E),
    pointEdge: Color(0xFFC8A04A),
    barA: Color(0xFFDAD3C4),
    barB: Color(0xFFBDB4A2),
    highlight: Color(0xFF2EC27E),
    glow: Color(0xFFFFD36B),
    label: Color(0xCC4A4237),
    pitch: 1.12,
  ),
  'board_cosmic': BoardThemeData(
    id: 'board_cosmic',
    pattern: BoardPattern.cosmic,
    frameA: Color(0xFF231446),
    frameB: Color(0xFF0B0620),
    inlay: Color(0xFF9D7BFF),
    feltA: Color(0xFF120A2E),
    feltB: Color(0xFF05030F),
    pointA: Color(0xAA9D7BFF),
    pointB: Color(0xAA2EC4D6),
    pointEdge: Color(0xFFE0D4FF),
    barA: Color(0xFF1B1038),
    barB: Color(0xFF0B0620),
    highlight: Color(0xFFFFF27A),
    glow: Color(0xFF9D7BFF),
    pitch: 0.85,
  ),
  'board_frost': BoardThemeData(
    id: 'board_frost',
    pattern: BoardPattern.frost,
    frameA: Color(0xFFBFE6F5),
    frameB: Color(0xFF7FB7D0),
    inlay: Color(0xFFFFFFFF),
    feltA: Color(0xFF1E4A66),
    feltB: Color(0xFF0E2A40),
    pointA: Color(0xCCE8F7FF),
    pointB: Color(0xCC5FA8D3),
    pointEdge: Color(0xFFFFFFFF),
    barA: Color(0xFF9AD0E6),
    barB: Color(0xFF5E9BB8),
    highlight: Color(0xFFFFD36B),
    glow: Color(0xFFBFF4FF),
    label: Color(0xCC0E2A40),
    pitch: 1.25,
  ),
  'board_ember': BoardThemeData(
    id: 'board_ember',
    pattern: BoardPattern.ember,
    frameA: Color(0xFF3A3532),
    frameB: Color(0xFF1A1716),
    inlay: Color(0xFFFF7A1A),
    feltA: Color(0xFF221A17),
    feltB: Color(0xFF110D0B),
    pointA: Color(0xFFB8471A),
    pointB: Color(0xFF55504B),
    pointEdge: Color(0xFFFFA24D),
    barA: Color(0xFF2E2A27),
    barB: Color(0xFF161312),
    highlight: Color(0xFF7CFFB2),
    glow: Color(0xFFFF7A1A),
    pitch: 0.8,
  ),
  'board_garden': BoardThemeData(
    id: 'board_garden',
    pattern: BoardPattern.garden,
    frameA: Color(0xFF6B4A2B),
    frameB: Color(0xFF3F2A17),
    inlay: Color(0xFFE6C36A),
    feltA: Color(0xFF1E5A3A),
    feltB: Color(0xFF0F3522),
    pointA: Color(0xFFF2E6C8),
    pointB: Color(0xFFB0413E),
    pointEdge: Color(0xFFE6C36A),
    barA: Color(0xFF5A3D22),
    barB: Color(0xFF2F1F10),
    highlight: Color(0xFFFFF27A),
    glow: Color(0xFF9CFF8A),
  ),
};

BoardThemeData boardTheme(String id) =>
    kBoardThemes[id] ?? kBoardThemes['board_khatam']!;

/// Deterministic pseudo-random for art (not gameplay).
class ArtRng {
  ArtRng(this._s);
  int _s;
  double next() {
    _s = (_s * 1103515245 + 12345) & 0x7FFFFFFF;
    return _s / 0x7FFFFFFF;
  }
}

/// Paints the static parts of a board. Animated layers are drawn elsewhere.
/// Renders digits with Persian numerals when [persian].
String boardDigits(int n, {required bool persian}) {
  if (!persian) return '$n';
  const fa = '۰۱۲۳۴۵۶۷۸۹';
  return '$n'.split('').map((d) => fa[int.parse(d)]).join();
}

class BoardArt {
  BoardArt(this.t, this.l, {this.persianDigits = false});
  final BoardThemeData t;
  final BoardLayout l;

  /// Point labels in Persian numerals.
  final bool persianDigits;

  Paint _lin(
    Rect r,
    List<Color> c, {
    bool vertical = true,
    List<double>? stops,
  }) => Paint()
    ..shader = ui.Gradient.linear(
      vertical ? r.topCenter : r.centerLeft,
      vertical ? r.bottomCenter : r.centerRight,
      c,
      stops,
    );

  /// Everything in one go (previews, store cards).
  void paint(Canvas c) {
    paintBase(c);
    paintFelt(c);
    paintTop(c);
  }

  /// Shadow, frame and decorative band.
  void paintBase(Canvas c) {
    final o = l.outer;
    final radius = Radius.circular(l.frame * 1.2);
    // Drop shadow.
    c.drawRRect(
      RRect.fromRectAndRadius(o.shift(Offset(0, l.frame * 0.6)), radius),
      Paint()
        ..color = const Color(0x99000000)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, l.frame * 1.2),
    );
    // Frame.
    final frameRR = RRect.fromRectAndRadius(o, radius);
    c.drawRRect(frameRR, _lin(o, [t.frameA, t.frameB]));
    _frameTexture(c, o);
    // Inlay borders.
    final inlay = Paint()
      ..color = t.inlay
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(1, l.frame * 0.12);
    c.drawRRect(frameRR.deflate(l.frame * 0.22), inlay);
    _patternBand(c);
  }

  /// The playing surface of both halves.
  void paintFelt(Canvas c) {
    final left = Rect.fromLTRB(
      l.field.left,
      l.field.top,
      l.bar.left,
      l.field.bottom,
    );
    final right = Rect.fromLTRB(
      l.bar.right,
      l.field.top,
      l.field.right,
      l.field.bottom,
    );
    for (final half in [left, right]) {
      c.drawRect(
        half,
        _lin(half, [t.feltA, t.feltB, t.feltA], stops: const [0, 0.5, 1]),
      );
      _feltTexture(c, half);
      // Inner shadow at edges.
      c.drawRect(
        half,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = l.frame * 0.5
          ..color = const Color(0x55000000)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, l.frame * 0.3),
      );
    }
  }

  /// Points, bar, trays and labels.
  void paintTop(Canvas c) {
    // Points.
    for (var abs = 1; abs <= 24; abs++) {
      _point(c, abs);
    }
    // Bar.
    c.drawRect(
      l.bar,
      _lin(
        l.bar,
        [t.barB, t.barA, t.barB],
        vertical: false,
        stops: const [0, 0.5, 1],
      ),
    );
    _barMedallion(c);
    // Trays.
    for (final tray in [l.whiteTray, l.blackTray]) {
      final rr = RRect.fromRectAndRadius(tray, Radius.circular(l.frame * 0.5));
      c.drawRRect(rr, Paint()..color = const Color(0x66000000));
      c.drawRRect(
        rr,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1
          ..color = t.inlay.withValues(alpha: 0.5),
      );
    }
    // Field border.
    c.drawRect(
      l.field,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(1, l.frame * 0.1)
        ..color = t.inlay.withValues(alpha: 0.8),
    );
    _labels(c);
  }

  void _point(Canvas c, int abs) {
    final r = l.pointRect(abs);
    final top = l.isTop(abs);
    final even = abs.isEven;
    final color = even ? t.pointA : t.pointB;
    final tip = top
        ? Offset(r.center.dx, r.bottom)
        : Offset(r.center.dx, r.top);
    final b1 = top ? r.topLeft : r.bottomLeft;
    final b2 = top ? r.topRight : r.bottomRight;
    final inset = r.width * 0.06;
    final path = Path()
      ..moveTo(b1.dx + inset, b1.dy)
      ..lineTo(tip.dx, tip.dy)
      ..lineTo(b2.dx - inset, b2.dy)
      ..close();
    if (t.pattern == BoardPattern.neon) {
      c.drawPath(
        path,
        Paint()
          ..color = color.withValues(alpha: 0.18)
          ..style = PaintingStyle.fill,
      );
      c.drawPath(
        path,
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.2
          ..maskFilter = const MaskFilter.blur(BlurStyle.solid, 3),
      );
      return;
    }
    final shade = Color.lerp(color, const Color(0xFF000000), 0.28)!;
    c.drawPath(
      path,
      Paint()
        ..shader = ui.Gradient.linear(top ? r.topCenter : r.bottomCenter, tip, [
          color,
          shade,
        ]),
    );
    // Inner motif: a slim inner triangle line and small diamonds.
    final innerPath = Path()
      ..moveTo(b1.dx + inset * 3, b1.dy)
      ..lineTo(
        tip.dx,
        top ? tip.dy - r.height * 0.12 : tip.dy + r.height * 0.12,
      )
      ..lineTo(b2.dx - inset * 3, b2.dy);
    c.drawPath(
      innerPath,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.8
        ..color = t.pointEdge.withValues(alpha: 0.45),
    );
    if (t.pattern == BoardPattern.khatam ||
        t.pattern == BoardPattern.turquoise ||
        t.pattern == BoardPattern.garden) {
      final dPaint = Paint()..color = t.pointEdge.withValues(alpha: 0.7);
      for (var k = 1; k <= 3; k++) {
        final y = top
            ? r.top + r.height * 0.18 * k
            : r.bottom - r.height * 0.18 * k;
        final s = r.width * 0.07 * (1 - k * 0.15);
        final d = Path()
          ..moveTo(r.center.dx, y - s)
          ..lineTo(r.center.dx + s, y)
          ..lineTo(r.center.dx, y + s)
          ..lineTo(r.center.dx - s, y)
          ..close();
        c.drawPath(d, dPaint);
      }
    }
    c.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = t.pointEdge.withValues(alpha: 0.8),
    );
  }

  void _frameTexture(Canvas c, Rect o) {
    final rng = ArtRng(t.id.hashCode);
    switch (t.pattern) {
      case BoardPattern.khatam:
      case BoardPattern.garden:
      case BoardPattern.caravanserai:
        // Wood grain / stone striations.
        final p = Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.7
          ..color = const Color(0x22000000);
        for (var i = 0; i < 40; i++) {
          final y = o.top + rng.next() * o.height;
          final path = Path()..moveTo(o.left, y);
          for (var x = o.left; x <= o.right; x += o.width / 12) {
            path.lineTo(
              x,
              y + math.sin(x * 0.05 + i) * 2 + (rng.next() - 0.5) * 2,
            );
          }
          c.drawPath(path, p);
        }
      case BoardPattern.marble:
        _veins(
          c,
          o,
          rng,
          18,
          t.inlay.withValues(alpha: 0.6),
          const Color(0x33999999),
        );
      case BoardPattern.ember:
        // Rivets.
        final riv = Paint()..color = const Color(0xFF6E6762);
        final hi = Paint()..color = const Color(0x55FFFFFF);
        for (var x = o.left + l.frame; x < o.right; x += o.width / 14) {
          for (final y in [o.top + l.frame * 0.5, o.bottom - l.frame * 0.5]) {
            c.drawCircle(Offset(x, y), l.frame * 0.18, riv);
            c.drawCircle(Offset(x - 1, y - 1), l.frame * 0.06, hi);
          }
        }
      case BoardPattern.frost:
        final p = Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.8
          ..color = const Color(0x66FFFFFF);
        for (var i = 0; i < 26; i++) {
          final s = Offset(
            o.left + rng.next() * o.width,
            o.top + rng.next() * o.height,
          );
          var pt = s;
          final path = Path()..moveTo(s.dx, s.dy);
          for (var k = 0; k < 4; k++) {
            pt = pt + Offset((rng.next() - 0.5) * 22, (rng.next() - 0.5) * 22);
            path.lineTo(pt.dx, pt.dy);
          }
          c.drawPath(path, p);
        }
      default:
        break;
    }
  }

  void _veins(Canvas c, Rect o, ArtRng rng, int n, Color gold, Color grey) {
    for (var i = 0; i < n; i++) {
      final p = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.6 + rng.next() * 1.4
        ..color = i % 3 == 0 ? gold : grey;
      final start = Offset(
        o.left + rng.next() * o.width,
        o.top + rng.next() * o.height,
      );
      final path = Path()..moveTo(start.dx, start.dy);
      var pt = start;
      for (var k = 0; k < 5; k++) {
        final next =
            pt +
            Offset(
              (rng.next() - 0.3) * o.width * 0.2,
              (rng.next() - 0.5) * o.height * 0.15,
            );
        final ctrl = Offset(
          (pt.dx + next.dx) / 2 + (rng.next() - 0.5) * 30,
          (pt.dy + next.dy) / 2 + (rng.next() - 0.5) * 30,
        );
        path.quadraticBezierTo(ctrl.dx, ctrl.dy, next.dx, next.dy);
        pt = next;
      }
      c.drawPath(path, p);
    }
  }

  /// Decorative band inside the frame.
  void _patternBand(Canvas c) {
    final o = l.outer;
    final band = l.frame * 0.36;
    final y1 = o.top + l.frame * 0.62;
    final y2 = o.bottom - l.frame * 0.62;
    switch (t.pattern) {
      case BoardPattern.khatam:
        // Tiny alternating triangles and stars, the khatam micro-mosaic.
        final pA = Paint()..color = t.inlay;
        final pB = Paint()..color = const Color(0xFFEFE2C4);
        final pC = Paint()..color = const Color(0xFF1C3D5A);
        final step = band * 1.1;
        for (final y in [y1, y2]) {
          var i = 0;
          for (var x = o.left + l.frame; x < o.right - l.frame; x += step) {
            final tri = Path();
            if (i.isEven) {
              tri
                ..moveTo(x, y + band / 2)
                ..lineTo(x + step / 2, y - band / 2)
                ..lineTo(x + step, y + band / 2);
            } else {
              tri
                ..moveTo(x, y - band / 2)
                ..lineTo(x + step / 2, y + band / 2)
                ..lineTo(x + step, y - band / 2);
            }
            tri.close();
            c.drawPath(tri, i % 3 == 0 ? pA : (i % 3 == 1 ? pB : pC));
            i++;
          }
        }
        for (final x in [o.left + l.frame * 0.62, o.right - l.frame * 0.62]) {
          for (
            var y = o.top + l.frame * 1.5;
            y < o.bottom - l.frame;
            y += band * 2.4
          ) {
            _star(c, Offset(x, y), band * 0.7, 6, pA);
          }
        }
      case BoardPattern.turquoise:
        final p = Paint()..color = t.inlay;
        final q = Paint()..color = const Color(0xFFF2EAD3);
        for (final y in [y1, y2]) {
          for (
            var x = o.left + l.frame * 1.2;
            x < o.right - l.frame;
            x += band * 2.6
          ) {
            _star(c, Offset(x, y), band * 0.8, 8, p);
            c.drawCircle(Offset(x, y), band * 0.22, q);
          }
        }
      case BoardPattern.neon:
        c.drawRRect(
          RRect.fromRectAndRadius(
            o.deflate(l.frame * 0.55),
            Radius.circular(l.frame),
          ),
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2
            ..color = const Color(0xFF29F6FF)
            ..maskFilter = const MaskFilter.blur(BlurStyle.solid, 4),
        );
      case BoardPattern.garden:
        final leaf = Paint()..color = const Color(0xFF2E7D4F);
        for (final y in [y1, y2]) {
          for (
            var x = o.left + l.frame * 1.2;
            x < o.right - l.frame;
            x += band * 2.2
          ) {
            c.drawOval(
              Rect.fromCenter(
                center: Offset(x, y),
                width: band * 0.7,
                height: band * 1.4,
              ),
              leaf,
            );
          }
        }
      case BoardPattern.caravanserai:
        final p = Paint()..color = t.inlay.withValues(alpha: 0.8);
        for (final y in [y1, y2]) {
          for (
            var x = o.left + l.frame * 1.5;
            x < o.right - l.frame;
            x += band * 4
          ) {
            // Little pointed arches.
            final a = Path()
              ..moveTo(x - band * 0.6, y + band * 0.5)
              ..lineTo(x - band * 0.6, y)
              ..quadraticBezierTo(
                x - band * 0.6,
                y - band * 0.6,
                x,
                y - band * 0.8,
              )
              ..quadraticBezierTo(
                x + band * 0.6,
                y - band * 0.6,
                x + band * 0.6,
                y,
              )
              ..lineTo(x + band * 0.6, y + band * 0.5)
              ..close();
            c.drawPath(a, p);
          }
        }
      default:
        break;
    }
  }

  void _feltTexture(Canvas c, Rect r) {
    final rng = ArtRng(t.id.hashCode ^ r.left.round());
    switch (t.pattern) {
      case BoardPattern.khatam:
      case BoardPattern.garden:
        // Subtle diamond lattice like tooled leather.
        final p = Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.6
          ..color = const Color(0x16FFFFFF);
        final s = r.width / 6;
        c.save();
        c.clipRect(r);
        for (var x = r.left - r.height; x < r.right + r.height; x += s) {
          c.drawLine(Offset(x, r.top), Offset(x + r.height, r.bottom), p);
          c.drawLine(Offset(x, r.bottom), Offset(x + r.height, r.top), p);
        }
        c.restore();
        if (t.pattern == BoardPattern.garden) {
          // Water channel across the middle.
          final ch = Rect.fromCenter(
            center: r.center,
            width: r.width,
            height: r.height * 0.05,
          );
          c.drawRect(ch, Paint()..color = const Color(0x553FA9C9));
        }
      case BoardPattern.caravanserai:
      case BoardPattern.cosmic:
        // Static stars (twinkle is animated separately).
        final p = Paint()..color = const Color(0xAAFFFFFF);
        for (var i = 0; i < 40; i++) {
          c.drawCircle(
            Offset(
              r.left + rng.next() * r.width,
              r.top + rng.next() * r.height,
            ),
            rng.next() * 1.1 + 0.2,
            p,
          );
        }
      case BoardPattern.turquoise:
        // Tile grid.
        final p = Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.7
          ..color = const Color(0x2234C3C3);
        final s = r.width / 6;
        for (var x = r.left; x <= r.right; x += s) {
          c.drawLine(Offset(x, r.top), Offset(x, r.bottom), p);
        }
        for (var y = r.top; y <= r.bottom; y += s) {
          c.drawLine(Offset(r.left, y), Offset(r.right, y), p);
        }
      case BoardPattern.neon:
        final p = Paint()
          ..strokeWidth = 0.8
          ..color = const Color(0x33FF3EC8);
        final s = r.width / 8;
        for (var x = r.left; x <= r.right; x += s) {
          c.drawLine(Offset(x, r.top), Offset(x, r.bottom), p);
        }
        for (var y = r.top; y <= r.bottom; y += s) {
          c.drawLine(Offset(r.left, y), Offset(r.right, y), p);
        }
      case BoardPattern.marble:
        c.save();
        c.clipRect(r);
        _veins(
          c,
          r,
          rng,
          10,
          t.inlay.withValues(alpha: 0.35),
          const Color(0x22888888),
        );
        c.restore();
      case BoardPattern.frost:
        final p = Paint()..color = const Color(0x22FFFFFF);
        for (var i = 0; i < 18; i++) {
          _star(
            c,
            Offset(
              r.left + rng.next() * r.width,
              r.top + rng.next() * r.height,
            ),
            2 + rng.next() * 4,
            6,
            p,
          );
        }
      case BoardPattern.ember:
        final p = Paint()
          ..strokeWidth = 0.8
          ..color = const Color(0x22FF7A1A);
        for (var i = 0; i < 12; i++) {
          final y = r.top + rng.next() * r.height;
          c.drawLine(
            Offset(r.left, y),
            Offset(r.right, y + (rng.next() - 0.5) * 10),
            p,
          );
        }
    }
  }

  void _barMedallion(Canvas c) {
    final ctr = l.bar.center;
    final rad = l.barW * 0.42;
    final p = Paint()..color = t.inlay;
    switch (t.pattern) {
      case BoardPattern.neon:
        c.drawCircle(
          ctr,
          rad,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2
            ..color = t.inlay
            ..maskFilter = const MaskFilter.blur(BlurStyle.solid, 3),
        );
      default:
        _star(c, ctr, rad, 8, p);
        c.drawCircle(ctr, rad * 0.4, Paint()..color = t.barB);
        _star(c, ctr, rad * 0.3, 8, p);
    }
  }

  void _labels(Canvas c) {
    final fs = math.max<double>(7, l.frame * 0.48);
    for (var abs = 1; abs <= 24; abs++) {
      final r = l.pointRect(abs);
      final top = l.isTop(abs);
      final pb =
          ui.ParagraphBuilder(
              ui.ParagraphStyle(textAlign: TextAlign.center, fontSize: fs),
            )
            ..pushStyle(
              ui.TextStyle(
                color: t.label.withValues(alpha: 0.55),
                fontSize: fs,
              ),
            )
            ..addText(boardDigits(abs, persian: persianDigits));
      final para = pb.build()..layout(ui.ParagraphConstraints(width: r.width));
      final y = top
          ? l.outer.top + (l.frame - para.height) / 2
          : l.outer.bottom - (l.frame + para.height) / 2;
      c.drawParagraph(para, Offset(r.left, y));
    }
  }

  static void _star(Canvas c, Offset center, double r, int n, Paint p) {
    final path = Path();
    for (var i = 0; i < n * 2; i++) {
      final ang = math.pi * i / n - math.pi / 2;
      final rr = i.isEven ? r : r * 0.48;
      final pt = center + Offset(math.cos(ang) * rr, math.sin(ang) * rr);
      if (i == 0) {
        path.moveTo(pt.dx, pt.dy);
      } else {
        path.lineTo(pt.dx, pt.dy);
      }
    }
    path.close();
    c.drawPath(path, p);
  }

  static void star(Canvas c, Offset center, double r, int n, Paint p) =>
      _star(c, center, r, n, p);
}
