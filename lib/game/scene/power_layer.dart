import 'dart:math' as math;
import 'dart:ui' as ui;
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:haftnard/core/effects/cards.dart';
import 'package:haftnard/game/audio.dart';
import 'package:haftnard/game/scene/board_game.dart';
import 'package:haftnard/game/scene/fx.dart';
import 'package:haftnard/game/scene/paragraph_cache.dart';
import 'package:haftnard/game/scene/power_visuals.dart';
import 'package:haftnard/ui/theme.dart';
import 'package:haftnard/ui/widgets/card_art.dart';
import 'package:meta/meta.dart';

/// Draws every active power on the board for its whole duration and plays a
/// distinct visual + sound at the moment a power lands, fires or ends.
class PowerLayer extends Component {
  PowerLayer(this.game);
  final BoardGame game;

  final ParagraphCache _text = ParagraphCache(capacity: 24);
  final List<String> _drawn = [];
  final List<MomentKind> _log = [];
  double _freeze = 0;

  /// Test hooks: indicators drawn last frame, and recent moments.
  @visibleForTesting
  List<String> get debugDrawn => List.unmodifiable(_drawn);
  @visibleForTesting
  List<MomentKind> get debugMoments => List.unmodifiable(_log);

  @override
  void onRemove() {
    _text.clear();
    super.onRemove();
  }

  @override
  void update(double dt) {
    if (_freeze > 0) _freeze = math.max(0, _freeze - dt);
  }

  // --- Moments ---------------------------------------------------------------

  void play(List<Moment> moments) {
    for (final m in moments) {
      _log.add(m.kind);
      if (_log.length > 200) _log.removeAt(0);
      _moment(m);
    }
  }

  Offset _anchor(Moment m) {
    if (m.point > 0) {
      final ps = game.checkerPositionsAt(m.point);
      if (ps.isNotEmpty) return ps.last;
      return game.layout.pointRect(m.point).center;
    }
    return game.layout.diceCenter(m.side);
  }

  void _sound(String name, double rate, {double volume = 1}) =>
      Sfx.instance.play(name, rate: rate, volume: volume);

  void _moment(Moment m) {
    final fx = game.fx;
    final at = _anchor(m);
    final r = game.layout.checkerR;
    const ice = Color(0xFF9FE8FF);
    const gold = Color(0xFFFFD36B);
    const dark = Color(0xFF7A3FB8);
    switch (m.kind) {
      case MomentKind.iceForm:
        fx
          ..burst(at, color: ice, count: 26, speed: 140, gravity: 0, life: 0.8)
          ..ring(at, ice, size: r * 3);
        _sound('magic', 1.5);
      case MomentKind.iceCrack:
        fx
          ..burst(at, color: const Color(0xFFE6FAFF), count: 22)
          ..popup('❄', at.translate(0, -r * 1.4), color: ice);
        _sound('card_flip', 0.7);
        _sound('pop', 1.4, volume: 0.7);
      case MomentKind.shieldUp:
        fx.ring(at, const Color(0xFF8AD8FF), size: r * 3.2);
        _sound('magic', 1.2);
      case MomentKind.shieldPop:
      case MomentKind.shieldBlock:
        fx.burst(at, color: const Color(0xFF8AD8FF), count: 16, speed: 180);
        _sound('hit', 1.8, volume: 0.7);
      case MomentKind.gateSlam:
        fx.burst(at, color: const Color(0xFFB8C2CC), count: 14, speed: 120);
        _sound('hit', 0.6);
      case MomentKind.gateOpen:
        fx.ring(at, const Color(0xFFB8C2CC), size: r * 2.4);
        _sound('slide', 0.7);
      case MomentKind.mineSet:
        fx.burst(at, color: const Color(0xFF8C6A48), count: 10, speed: 60);
        _sound('slide', 0.5);
      case MomentKind.mineBoom:
        fx
          ..flashScreen(const Color(0xFFFF8A3D))
          ..burst(at, color: const Color(0xFFFF8A3D), count: 46, speed: 340)
          ..burst(
            at,
            color: const Color(0xFF555555),
            count: 18,
            kind: ParticleKind.smoke,
            gravity: -30,
            size: 8,
            life: 1.2,
          );
        _sound('mine', 1);
        Sfx.instance.haptic(HapticKind.heavy);
      case MomentKind.sandSwirl:
        fx.burst(at, color: const Color(0xFFD9B26F), speed: 90, gravity: 0);
        _sound('card_whoosh', 0.6);
      case MomentKind.tollSet:
        fx.ring(at, gold, size: r * 2.6);
        _sound('coin', 0.8);
      case MomentKind.diceShatter:
        fx.burst(at, color: const Color(0xFFF3E9D2), count: 30, speed: 260);
        _sound('hit', 1.6);
      case MomentKind.fogRoll:
        fx.burst(
          at,
          color: const Color(0xFFCFD8DC),
          count: 16,
          kind: ParticleKind.smoke,
          gravity: -10,
          size: 10,
          life: 1.6,
        );
        _sound('card_whoosh', 0.5);
      case MomentKind.curseDrain:
        fx.burst(
          at,
          color: dark,
          count: 20,
          kind: ParticleKind.smoke,
          gravity: 40,
          size: 6,
          life: 1.1,
        );
        _sound('magic', 0.6);
      case MomentKind.windGust:
        fx.burst(at, color: const Color(0xFFE0F7FA), count: 18, speed: 260);
        _sound('card_whoosh', 1.3);
      case MomentKind.magnetPulse:
        fx.ring(at, gold, size: r * 3.4);
        _sound('magic', 0.9);
      case MomentKind.sevenSeal:
        fx.ring(at, const Color(0xFFFF6B6B), size: r * 3);
        _sound('card_pick', 0.7);
      case MomentKind.buffSparkle:
        fx.burst(at, count: 22, kind: ParticleKind.star);
        _sound('magic', 1.3);
      case MomentKind.tokensFly:
        fx.burst(at, count: 18, kind: ParticleKind.coin);
        _sound('coin', 1);
      case MomentKind.steal:
        fx.burst(at, color: const Color(0xFF8E44AD), count: 14, speed: 200);
        _sound('card_whoosh', 1.4);
      case MomentKind.teleportBlink:
        fx
          ..ring(at, const Color(0xFFB79CFF), size: r * 2.6)
          ..burst(at, color: const Color(0xFFB79CFF), count: 20, gravity: 0);
        _sound('magic', 1.6);
      case MomentKind.timeFreeze:
        _freeze = game.reducedMotion ? 0.5 : 1.2;
        _sound('magic', 0.5);
      case MomentKind.coinFlip:
        fx.burst(at, count: 12, kind: ParticleKind.coin);
        _sound('coin', 1.3);
      case MomentKind.phoenixRise:
        fx.burst(
          at,
          color: const Color(0xFFFF7A2F),
          count: 30,
          kind: ParticleKind.ember,
          gravity: -120,
        );
        _sound('magic', 1.1);
      case MomentKind.bearOffBlessing:
        fx.burst(at, count: 30, kind: ParticleKind.star);
        _sound('bear_off', 1.2);
      case MomentKind.exileStrike:
        fx.flashScreen(const Color(0xFFFF6B6B), strength: 0.3);
        _sound('hit', 0.9);
      case MomentKind.stakesUp:
        fx.popup('×2', at.translate(0, -r * 1.5), color: gold, size: 30);
        _sound('card_pick', 1.2);
      case MomentKind.cleanse:
        fx.burst(at, color: const Color(0xFF34C3C3), gravity: -60);
        _sound('magic', 1.4);
      case MomentKind.reveal:
        fx.flashScreen(const Color(0xFFFFF4C2), strength: 0.35);
        _sound('magic', 1.7);
      case MomentKind.quake:
        fx.flashScreen(const Color(0xFF8C6A48), strength: 0.3);
        _sound('mine', 0.6, volume: 0.7);
      case MomentKind.copy:
        fx.ring(at, const Color(0xFFDDE3EA), size: r * 2.8);
        _sound('card_flip', 1.2);
      case MomentKind.rollAgain:
        fx.burst(at, count: 16, kind: ParticleKind.star);
        _sound('dice_roll', 1.3, volume: 0.6);
      case MomentKind.offerBoost:
        fx.popup('+🂠', at.translate(0, -r), color: gold);
        _sound('card_flip', 1.1);
      case MomentKind.offerHex:
        fx.popup('−🂠', at.translate(0, -r), color: const Color(0xFFFF8A8A));
        _sound('card_flip', 0.8);
      case MomentKind.mirrorShine:
        fx.ring(at, const Color(0xFFE6EEF5), size: r * 3);
        _sound('magic', 1.8);
      case MomentKind.truceFlag:
        fx.burst(
          game.layout.bar.center,
          color: const Color(0xFFFFFFFF),
          count: 20,
          gravity: 0,
        );
        _sound('ui_confirm', 0.8);
      case MomentKind.skipTurn:
        fx.ring(at, const Color(0xFFB0BEC5), size: r * 2.6);
        _sound('ui_back', 0.7);
      case MomentKind.fizzle:
        fx.burst(at, color: const Color(0xFF9E9E9E), count: 10, speed: 60);
        _sound('ui_back', 1);
      case MomentKind.fade:
        fx.ring(at, const Color(0x99FFFFFF), size: r * 2);
    }
  }

  // --- Persistent indicators -------------------------------------------------

  @override
  void render(Canvas canvas) {
    final c = canvas;
    _drawn.clear();
    final s = game.shownState;
    if (s == null || !game.isLoaded) return;
    final visuals = PowerVisuals.forState(s, viewer: game.controller.localSide);
    final t = game.time;
    for (final v in visuals) {
      _drawn.add(v.key);
      final alpha = v.pending ? 0.5 : 1.0;
      if (v.point > 0) {
        _point(c, v, t, alpha);
      } else {
        _side(c, v, t, alpha);
      }
    }
    if (_freeze > 0) _renderFreeze(c, t);
  }

  void _point(Canvas c, PowerVisual v, double t, double alpha) {
    final l = game.layout;
    final r = l.checkerR;
    final ps = game.checkerPositionsAt(v.point);
    final base = ps.isNotEmpty ? ps.first : l.pointRect(v.point).center;
    final top = ps.isNotEmpty ? ps.last : base;
    switch (v.kind) {
      case VisualKind.ice:
        final n = v.count <= 0 ? 1 : math.min(v.count, ps.length);
        final frozen = ps.isEmpty ? [base] : ps.sublist(ps.length - n);
        for (final p in frozen) {
          final rect = Rect.fromCircle(center: p, radius: r * 1.12);
          final rr = RRect.fromRectAndRadius(rect, Radius.circular(r * 0.3));
          c
            ..drawRRect(
              rr,
              Paint()
                ..color = const Color(0xFF9FE8FF)
                    .withValues(alpha: 0.42 * alpha),
            )
            ..drawRRect(
              rr,
              Paint()
                ..style = PaintingStyle.stroke
                ..strokeWidth = 2
                ..color = const Color(0xFFE6FAFF)
                    .withValues(alpha: 0.9 * alpha),
            )
            ..drawLine(
              p.translate(-r * 0.6, -r * 0.5),
              p.translate(-r * 0.2, -r * 0.8),
              Paint()
                ..strokeWidth = 2
                ..color = const Color(0xCCFFFFFF),
            );
          for (var i = 0; i < 3; i++) {
            final a = t * 1.5 + i * 2.1;
            c.drawCircle(
              p + Offset(math.cos(a), math.sin(a)) * r * 0.9,
              1.6,
              Paint()..color = const Color(0xFFFFFFFF).withValues(alpha: alpha),
            );
          }
        }
        _badge(
          c,
          top.translate(r * 0.9, -r * 0.9),
          '❄',
          v.turns,
          alpha,
          cardId: v.cardId,
        );
      case VisualKind.shield:
        final pulse = 0.85 + 0.15 * math.sin(t * 3);
        c
          ..drawCircle(
            top,
            r * 1.3 * pulse,
            Paint()
              ..color = const Color(0xFF8AD8FF).withValues(alpha: 0.18 * alpha),
          )
          ..drawCircle(
            top,
            r * 1.3 * pulse,
            Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = 2.5
              ..color = const Color(0xFF8AD8FF).withValues(alpha: 0.85 * alpha),
          );
        _badge(
          c,
          top.translate(r * 1.1, -r * 1.1),
          '🛡',
          v.turns,
          alpha,
          cardId: v.cardId,
        );
      case VisualKind.gate:
        final paint = Paint()
          ..strokeWidth = 3
          ..color = const Color(0xFFB8C2CC).withValues(alpha: alpha);
        for (var i = -1; i <= 1; i++) {
          c.drawLine(
            top.translate(i * r * 0.55, -r * 1.2),
            top.translate(i * r * 0.55, r * 1.2),
            paint,
          );
        }
        c.drawLine(
          top.translate(-r * 0.9, -r * 1.2),
          top.translate(r * 0.9, -r * 1.2),
          paint..strokeWidth = 4,
        );
        _badge(
          c,
          top.translate(r * 1.1, -r * 1.3),
          '⛩',
          v.turns,
          alpha,
          cardId: v.cardId,
        );
      case VisualKind.mine:
        final p = l.pointRect(v.point).center;
        final dash = Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..color = const Color(0xFFFF6B6B).withValues(alpha: 0.55 * alpha);
        for (var i = 0; i < 8; i++) {
          c.drawArc(
            Rect.fromCircle(center: p, radius: r * 0.7),
            i * math.pi / 4,
            math.pi / 8,
            false,
            dash,
          );
        }
      case VisualKind.quicksand:
        final p = l.pointRect(v.point).center;
        for (var i = 0; i < 3; i++) {
          c.drawArc(
            Rect.fromCircle(center: p, radius: r * (0.5 + i * 0.35)),
            t * (1.5 + i * 0.4) + i,
            math.pi * 1.2,
            false,
            Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = 3
              ..color = const Color(0xFFD9B26F).withValues(alpha: 0.6 * alpha),
          );
        }
        _badge(c, p.translate(r, -r), '⏳', v.turns, alpha, cardId: v.cardId);
      case VisualKind.toll:
        final rect = l.pointRect(v.point);
        final y = rect.center.dy;
        final paint = Paint()
          ..strokeWidth = 3
          ..color = const Color(0xFFFFD36B).withValues(alpha: 0.85 * alpha);
        c
          ..drawLine(
            Offset(rect.left + 3, y - r),
            Offset(rect.left + 3, y + r),
            paint,
          )
          ..drawLine(
            Offset(rect.right - 3, y - r),
            Offset(rect.right - 3, y + r),
            paint,
          )
          ..drawLine(
            Offset(rect.left + 3, y - r * 0.6),
            Offset(rect.right - 3, y - r * 0.6),
            paint,
          );
        _badge(
          c,
          Offset(rect.right, y - r),
          '¤',
          v.turns,
          alpha,
          cardId: v.cardId,
        );
      default:
        _side(c, v, t, alpha);
    }
  }

  void _side(Canvas c, PowerVisual v, double t, double alpha) {
    final l = game.layout;
    final at = v.kind == VisualKind.truce ? l.bar.center : l.diceCenter(v.side);
    final sz = l.dieSize;
    String? glyph;
    switch (v.kind) {
      case VisualKind.diceCrack:
        final p = Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5
          ..color = const Color(0xFFFF8A8A).withValues(alpha: alpha);
        final path = Path()
          ..moveTo(at.dx + sz * 0.2, at.dy - sz * 0.6)
          ..lineTo(at.dx + sz * 0.45, at.dy - sz * 0.1)
          ..lineTo(at.dx + sz * 0.3, at.dy + sz * 0.1)
          ..lineTo(at.dx + sz * 0.6, at.dy + sz * 0.6);
        c.drawPath(path, p);
        glyph = '💥';
      case VisualKind.diceFog:
        for (var i = 0; i < 4; i++) {
          final dx = math.sin(t * 0.6 + i * 1.7) * sz * 0.9;
          c.drawCircle(
            at.translate(dx + (i - 1.5) * sz * 0.5, math.cos(t + i) * 4),
            sz * 0.55,
            Paint()
              ..color = const Color(0xFFCFD8DC).withValues(alpha: 0.28 * alpha)
              ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
          );
        }
        glyph = '🌫';
      case VisualKind.diceCurse:
        final pulse = 0.6 + 0.4 * math.sin(t * 2.5);
        c.drawCircle(
          at,
          sz * 1.4,
          Paint()
            ..color = const Color(0xFF4A1F73)
                .withValues(alpha: 0.35 * pulse * alpha)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12),
        );
        glyph = '☠';
      case VisualKind.diceHeadwind:
      case VisualKind.diceTailwind:
        final up = v.kind == VisualKind.diceTailwind;
        final p = Paint()
          ..strokeWidth = 2.5
          ..strokeCap = StrokeCap.round
          ..color = (up ? const Color(0xFF7CF29A) : const Color(0xFFFF8A8A))
              .withValues(alpha: alpha);
        for (final dx in [-0.8, 0.8]) {
          final x = at.dx + dx * sz;
          final y0 = at.dy + (up ? sz * 0.5 : -sz * 0.5);
          final y1 = at.dy + (up ? -sz * 0.5 : sz * 0.5);
          c
            ..drawLine(Offset(x, y0), Offset(x, y1), p)
            ..drawLine(Offset(x, y1), Offset(x - 5, y1 + (up ? 6 : -6)), p)
            ..drawLine(Offset(x, y1), Offset(x + 5, y1 + (up ? 6 : -6)), p);
        }
        glyph = up ? '+1' : '−1';
      case VisualKind.magnet:
        c.drawArc(
          Rect.fromCircle(center: at, radius: sz * 1.3),
          math.pi,
          math.pi,
          false,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 4
            ..color = const Color(0xFFFFD36B)
                .withValues(alpha: (0.5 + 0.4 * math.sin(t * 4)) * alpha),
        );
        glyph = '🧲';
      case VisualKind.noSeven:
        glyph = '⊘7';
      case VisualKind.diceBuff:
        for (var i = 0; i < 4; i++) {
          final a = t * 2 + i * math.pi / 2;
          c.drawCircle(
            at + Offset(math.cos(a), math.sin(a)) * sz * 1.1,
            2.5,
            Paint()..color = const Color(0xFFFFD36B).withValues(alpha: alpha),
          );
        }
        glyph = '✨';
      case VisualKind.skip:
        glyph = '⌛';
      case VisualKind.offerUp:
        glyph = '+🂠';
      case VisualKind.offerDown:
        glyph = '−🂠';
      case VisualKind.mirror:
        glyph = '🪞';
      case VisualKind.truce:
        final pole = Paint()
          ..strokeWidth = 2
          ..color = const Color(0xFFE0E0E0).withValues(alpha: alpha);
        c
          ..drawLine(at.translate(0, -sz), at.translate(0, sz * 0.3), pole)
          ..drawRect(
            Rect.fromLTWH(at.dx, at.dy - sz, sz * 0.7, sz * 0.45),
            Paint()..color = const Color(0xFFFFFFFF).withValues(alpha: alpha),
          );
        glyph = '🏳';
      default:
        break;
    }
    if (glyph != null) {
      _badge(
        c,
        at.translate(sz * 1.5, -sz * 0.8),
        glyph,
        v.turns,
        alpha,
        cardId: v.cardId,
      );
    }
  }

  /// A marker: the card's own icon (the same one as on the card and the HUD
  /// chip) in a dark disc, with the turns left beside it. [glyph] is only a
  /// fallback for effects without a card.
  void _badge(
    Canvas c,
    Offset at,
    String glyph,
    int? turns,
    double alpha, {
    String? cardId,
  }) {
    final card = cardId == null ? null : kCardById[cardId];
    if (card != null) {
      const r = 11.0;
      final color = AppColors.rarity(card.rarity.index);
      c
        ..drawCircle(
          at,
          r + 1.5,
          Paint()..color = color.withValues(alpha: alpha),
        )
        ..drawCircle(
          at,
          r,
          Paint()..color = Color.fromRGBO(20, 16, 36, 0.92 * alpha),
        );
      if (alpha < 0.99) {
        c.saveLayer(
          Rect.fromCircle(center: at, radius: r),
          Paint()..color = Color.fromRGBO(0, 0, 0, alpha),
        );
      } else {
        c.save();
      }
      c.translate(at.dx - r, at.dy - r);
      CardGlyphPainter(card.glyph, color).paint(c, const Size(r * 2, r * 2));
      c.restore();
      if (turns != null) {
        _badge(c, at.translate(r + 7, r * 0.6), '', turns, alpha);
      }
      return;
    }
    final digits = turns == null
        ? ''
        : game.persianDigits
        ? turns
              .toString()
              .split('')
              .map((d) => '۰۱۲۳۴۵۶۷۸۹'[int.parse(d)])
              .join()
        : '$turns';
    final label = digits.isEmpty
        ? glyph
        : glyph.isEmpty
        ? digits
        : '$glyph $digits';
    final para = _text.get('b|$label', () {
      final pb =
          ui.ParagraphBuilder(ui.ParagraphStyle(textAlign: TextAlign.center))
            ..pushStyle(
              ui.TextStyle(
                color: const Color(0xFFFFFFFF),
                fontSize: 11,
                fontWeight: FontWeight.w700,
                fontFamily: AppFonts.body,
              ),
            )
            ..addText(label);
      return pb.build()..layout(const ui.ParagraphConstraints(width: 48));
    });
    final w = math.max<double>(18, para.longestLine + 8);
    final rect = Rect.fromCenter(center: at, width: w, height: 16);
    c
      ..drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(8)),
        Paint()..color = Color.fromRGBO(0, 0, 0, 0.65 * alpha),
      )
      ..drawParagraph(para, Offset(at.dx - 24, at.dy - para.height / 2));
  }

  void _renderFreeze(Canvas c, double t) {
    final k = (_freeze / 1.2).clamp(0.0, 1.0);
    final area = game.layout.outer;
    c.drawRect(
      area,
      Paint()..color = const Color(0xFF8899AA).withValues(alpha: 0.35 * k),
    );
    final center = area.center;
    final rr = game.layout.checkerR * 3;
    final p = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..color = const Color(0xFFFFFFFF).withValues(alpha: 0.8 * k);
    c
      ..drawCircle(center, rr, p)
      ..drawLine(center, center.translate(0, -rr * 0.7), p)
      ..drawLine(
        center,
        center + Offset(math.cos(t * 6), math.sin(t * 6)) * rr * 0.85,
        p,
      );
  }

  /// For tests: is this side's freeze tint showing?
  @visibleForTesting
  bool get debugFrozenScene => _freeze > 0;
}
