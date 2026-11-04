import 'dart:math' as math;
import 'dart:ui' as ui;
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flutter/painting.dart'
    show FontWeight, HSVColor, Shadow, TextPainter, TextSpan, TextStyle;

enum ParticleKind { spark, ember, petal, coin, smoke, star, ring, confetti }

class _Particle {
  Offset pos = Offset.zero;
  Offset vel = Offset.zero;
  double age = 0;
  double life = 1;
  Color color = const Color(0xFFFFFFFF);
  double size = 1;
  ParticleKind kind = ParticleKind.spark;
  double gravity = 0;
  double spin = 0;
  double angle = 0;
  double drag = 0.9;
}

class _Popup {
  _Popup(this.text, this.pos, this.color, this.size);
  final String text;
  Offset pos;
  final Color color;
  final double size;
  double age = 0;
  static const life = 1.1;

  /// Laid out once at full size; scaled and faded with the canvas. Text
  /// layouts own native memory, so they are disposed with the popup.
  TextPainter? _tp;

  /// Text layouts built so far (tests: must be one per popup, not per frame).
  static int debugLayouts = 0;

  TextPainter get painter => _tp ??= _layout();

  TextPainter _layout() {
    debugLayouts++;
    return TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          fontFamily: 'Lalezar',
          fontSize: size * 1.2,
          color: color,
          fontWeight: FontWeight.w700,
          shadows: const [Shadow(blurRadius: 6, color: Color(0xCC000000))],
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
  }

  void dispose() {
    _tp?.dispose();
    _tp = null;
  }
}

/// Lightweight particle + popup layer.
class FxLayer extends Component {
  FxLayer({required this.reducedMotion});
  bool reducedMotion;
  final List<_Particle> _ps = [];
  final List<_Popup> _pops = [];
  final _rng = math.Random(7);
  double flash = 0;
  Color flashColor = const Color(0xFFFFFFFF);

  /// Soft white glow sprite, tinted per particle. Far cheaper than a blur
  /// mask filter per particle per frame.
  static final ui.Image _glow = () {
    const s = 64.0;
    final rec = ui.PictureRecorder();
    Canvas(rec).drawCircle(
      const Offset(s / 2, s / 2),
      s / 2,
      Paint()
        ..shader = ui.Gradient.radial(
          const Offset(s / 2, s / 2),
          s / 2,
          const [Color(0xFFFFFFFF), Color(0x66FFFFFF), Color(0x00FFFFFF)],
          const [0, 0.35, 1],
        ),
    );
    return rec.endRecording().toImageSync(s.toInt(), s.toInt());
  }();
  static const Rect _glowSrc = Rect.fromLTWH(0, 0, 64, 64);

  void _soft(Canvas canvas, Offset at, double radius, Color color) {
    canvas.drawImageRect(
      _glow,
      _glowSrc,
      Rect.fromCircle(center: at, radius: radius),
      Paint()..colorFilter = ColorFilter.mode(color, BlendMode.modulate),
    );
  }

  double _r() => _rng.nextDouble();

  /// Hard caps: beyond these the oldest particle/popup is recycled.
  static const int maxParticles = 600;
  static const int maxPopups = 12;

  /// Dead particles kept for reuse (no allocation per spawn).
  final List<_Particle> _free = [];

  int get particleCount => _ps.length;
  int get popupCount => _pops.length;
  int get pooledCount => _free.length;

  /// See [_Popup.debugLayouts].
  static int get debugPopupLayouts => _Popup.debugLayouts;

  /// Popups spawned so far (tests).
  static int debugPopupsCreated = 0;

  void _spawn({
    required Offset pos,
    required Offset vel,
    required double life,
    required Color color,
    required double size,
    required ParticleKind kind,
    double gravity = 0,
    double spin = 0,
    double drag = 0.9,
  }) {
    final _Particle p;
    if (_ps.length >= maxParticles) {
      p = _ps.removeAt(0);
    } else {
      p = _free.isNotEmpty ? _free.removeLast() : _Particle();
    }
    _ps.add(
      p
        ..pos = pos
        ..vel = vel
        ..age = 0
        ..life = life
        ..color = color
        ..size = size
        ..kind = kind
        ..gravity = gravity
        ..spin = spin
        ..angle = 0
        ..drag = drag,
    );
  }

  /// Drops every particle and popup (scene teardown / new game).
  void clear() {
    _free.addAll(_ps);
    if (_free.length > maxParticles) {
      _free.removeRange(maxParticles, _free.length);
    }
    _ps.clear();
    for (final p in _pops) {
      p.dispose();
    }
    _pops.clear();
  }

  void burst(
    Offset at, {
    int count = 24,
    Color color = const Color(0xFFFFD36B),
    ParticleKind kind = ParticleKind.spark,
    double speed = 220,
    double size = 3,
    double life = 0.7,
    double gravity = 300,
  }) {
    final n = reducedMotion ? (count / 3).ceil() : count;
    for (var i = 0; i < n; i++) {
      final a = _r() * math.pi * 2;
      final s = speed * (0.35 + _r() * 0.65);
      _spawn(
        pos: at,
        vel: Offset(math.cos(a), math.sin(a)) * s,
        life: life * (0.6 + _r() * 0.6),
        color: color,
        size: size * (0.6 + _r() * 0.8),
        kind: kind,
        gravity: gravity,
        spin: (_r() - 0.5) * 10,
      );
    }
  }

  void ring(Offset at, Color color, {double size = 40}) {
    _spawn(
      pos: at,
      vel: Offset.zero,
      life: 0.5,
      color: color,
      size: size,
      kind: ParticleKind.ring,
    );
  }

  /// Ambient emitters (sparks rising, snow, etc.).
  void emit(
    Offset at,
    Offset vel, {
    required Color color,
    required ParticleKind kind,
    double size = 2,
    double life = 3,
    double gravity = 0,
  }) {
    if (_ps.length > 400) return;
    _spawn(
      pos: at,
      vel: vel,
      life: life,
      color: color,
      size: size,
      kind: kind,
      gravity: gravity,
      drag: 1,
      spin: (_r() - 0.5) * 3,
    );
  }

  void popup(
    String text,
    Offset at, {
    Color color = const Color(0xFFFFE9A8),
    double size = 22,
  }) {
    debugPopupsCreated++;
    if (_pops.length >= maxPopups) _pops.removeAt(0).dispose();
    _pops.add(_Popup(text, at, color, size));
  }

  void flashScreen(Color c, {double strength = 0.5}) {
    flash = reducedMotion ? strength * 0.4 : strength;
    flashColor = c;
  }

  /// Confetti-like celebration across [area].
  void celebrate(Rect area, String kind) {
    final n = reducedMotion ? 40 : 140;
    for (var i = 0; i < n; i++) {
      final x = area.left + _r() * area.width;
      switch (kind) {
        case 'vic_petals':
          emit(
            Offset(x, area.top - _r() * area.height * 0.5),
            Offset((_r() - 0.5) * 60, 60 + _r() * 80),
            color: Color.lerp(
              const Color(0xFFE23E57),
              const Color(0xFFFF9AB0),
              _r(),
            )!,
            kind: ParticleKind.petal,
            size: 5 + _r() * 4,
            life: 4,
          );
        case 'vic_coins':
          emit(
            Offset(x, area.top - _r() * area.height * 0.5),
            Offset((_r() - 0.5) * 40, 120 + _r() * 120),
            color: const Color(0xFFFFD36B),
            kind: ParticleKind.coin,
            size: 6 + _r() * 3,
            life: 3.5,
            gravity: 120,
          );
        case 'vic_lanterns':
          emit(
            Offset(x, area.bottom + _r() * 60),
            Offset((_r() - 0.5) * 20, -40 - _r() * 50),
            color: Color.lerp(
              const Color(0xFFFF9E3D),
              const Color(0xFFFFD36B),
              _r(),
            )!,
            kind: ParticleKind.ember,
            size: 6 + _r() * 4,
            life: 5,
          );
        default:
          if (i % 20 == 0) {
            final c = Offset(x, area.top + _r() * area.height * 0.6);
            burst(
              c,
              count: 30,
              color: HSVColor.fromAHSV(1, _r() * 360, 0.7, 1).toColor(),
              speed: 260,
              life: 1.2,
              gravity: 140,
            );
          }
      }
    }
  }

  @override
  void update(double dt) {
    flash = math.max(0, flash - dt * 2.2);
    for (final p in _ps) {
      p.age += dt;
      p.vel =
          Offset(p.vel.dx, p.vel.dy + p.gravity * dt) *
          math.pow(p.drag, dt * 3).toDouble();
      p.pos += p.vel * dt;
      p.angle += p.spin * dt;
    }
    _ps.removeWhere((p) {
      if (p.age < p.life) return false;
      if (_free.length < maxParticles) _free.add(p);
      return true;
    });
    for (final p in _pops) {
      p.age += dt;
      p.pos = p.pos.translate(0, -40 * dt);
    }
    _pops.removeWhere((p) {
      if (p.age < _Popup.life) return false;
      p.dispose();
      return true;
    });
  }

  @override
  void render(Canvas canvas) {
    for (final p in _ps) {
      final t = p.age / p.life;
      final alpha = (1 - t).clamp(0.0, 1.0);
      final paint = Paint()
        ..color = p.color.withValues(alpha: p.color.a * alpha);
      switch (p.kind) {
        case ParticleKind.ring:
          canvas.drawCircle(
            p.pos,
            p.size * (0.4 + t),
            Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = 4 * (1 - t)
              ..color = p.color.withValues(alpha: alpha),
          );
        case ParticleKind.spark:
        case ParticleKind.star:
          canvas.drawCircle(p.pos, p.size * (1 - t * 0.5), paint);
          _soft(
            canvas,
            p.pos,
            p.size * 2.6,
            p.color.withValues(alpha: alpha * 0.5),
          );
        case ParticleKind.ember:
          _soft(canvas, p.pos, p.size * 1.6, p.color.withValues(alpha: alpha));
        case ParticleKind.smoke:
          _soft(
            canvas,
            p.pos,
            p.size * (1.5 + t * 3),
            p.color.withValues(alpha: alpha * 0.4),
          );
        case ParticleKind.petal:
          canvas.save();
          canvas.translate(p.pos.dx, p.pos.dy);
          canvas.rotate(p.angle);
          canvas.drawOval(
            Rect.fromCenter(
              center: Offset.zero,
              width: p.size * 1.6,
              height: p.size,
            ),
            paint,
          );
          canvas.restore();
        case ParticleKind.coin:
          canvas.save();
          canvas.translate(p.pos.dx, p.pos.dy);
          canvas.scale(math.cos(p.angle * 2).abs() + 0.15, 1);
          canvas.drawCircle(Offset.zero, p.size, paint);
          canvas.drawCircle(
            Offset.zero,
            p.size * 0.65,
            Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = 1
              ..color = const Color(0xFF8C6418).withValues(alpha: alpha),
          );
          canvas.restore();
        case ParticleKind.confetti:
          canvas.save();
          canvas.translate(p.pos.dx, p.pos.dy);
          canvas.rotate(p.angle);
          canvas.drawRect(
            Rect.fromCenter(
              center: Offset.zero,
              width: p.size,
              height: p.size * 0.5,
            ),
            paint,
          );
          canvas.restore();
      }
    }
    for (final p in _pops) {
      final t = p.age / _Popup.life;
      final scale = t < 0.15 ? 0.6 + t / 0.15 * 0.6 : 1.2 - (t - 0.15) * 0.25;
      final tp = p.painter;
      final alpha = (1 - t).clamp(0.0, 1.0);
      final bounds = Rect.fromCenter(
        center: Offset.zero,
        width: tp.width + 24,
        height: tp.height + 24,
      );
      canvas
        ..save()
        ..translate(p.pos.dx, p.pos.dy)
        ..scale(scale / 1.2)
        ..saveLayer(bounds, Paint()..color = Color.fromRGBO(0, 0, 0, alpha));
      tp.paint(canvas, Offset(-tp.width / 2, -tp.height / 2));
      canvas
        ..restore()
        ..restore();
    }
  }

  void renderFlash(Canvas canvas, Size size) {
    if (flash <= 0) return;
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = flashColor.withValues(alpha: flash * 0.6),
    );
  }
}
