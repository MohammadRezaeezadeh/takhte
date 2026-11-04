import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:haftnard/core/effects/cards.dart';
import 'package:haftnard/core/rules/board.dart';
import 'package:haftnard/core/rules/types.dart';
import 'package:haftnard/game/layout.dart';
import 'package:haftnard/game/scene/environment.dart';
import 'package:haftnard/game/scene/fx.dart';
import 'package:haftnard/game/themes/board_themes.dart';
import 'package:haftnard/game/themes/pieces.dart';
import 'package:haftnard/meta/cosmetics.dart';
import 'package:haftnard/ui/theme.dart';
import 'package:haftnard/ui/widgets/card_art.dart';

/// Live, animated preview for any cosmetic item.
class ItemPreview extends StatefulWidget {
  const ItemPreview({required this.item, super.key, this.loadout});
  final CosmeticItem item;

  /// Other equipped items to compose with (board previews use the checkers).
  final Map<ItemType, String>? loadout;

  @override
  State<ItemPreview> createState() => _ItemPreviewState();
}

class _ItemPreviewState extends State<ItemPreview>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 20),
  )..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final i = widget.item;
    final lang = Localizations.localeOf(context).languageCode;
    switch (i.type) {
      case ItemType.cardBack:
        return Center(
          child: AspectRatio(
            aspectRatio: 1 / 1.45,
            child: CustomPaint(painter: CardBackPainter(i.id)),
          ),
        );
      case ItemType.cardFrame:
        return Center(
          child: FittedBox(
            child: CardFace(
              card: cardById(CardId.timeStop),
              lang: lang,
              frameId: i.id,
              width: 120,
              compact: true,
            ),
          ),
        );
      case ItemType.emote:
        return Center(child: EmoteBubble(text: i.name(lang)));
      default:
        return RepaintBoundary(
          child: AnimatedBuilder(
            animation: _c,
            builder: (_, _) => CustomPaint(
              painter: _PreviewPainter(
                i,
                _c.value * 20,
                widget.loadout ?? kDefaultLoadout,
              ),
              size: Size.infinite,
            ),
          ),
        );
    }
  }
}

class _PreviewPainter extends CustomPainter {
  _PreviewPainter(this.item, this.t, this.loadout);
  final CosmeticItem item;
  final double t;
  final Map<ItemType, String> loadout;

  static final Map<String, EnvironmentLayer> _envs = {};

  @override
  void paint(Canvas canvas, Size size) {
    switch (item.type) {
      case ItemType.board:
        paintBoardScene(
          canvas,
          size,
          boardId: item.id,
          checkerId: loadout[ItemType.checker]!,
          diceId: loadout[ItemType.dice]!,
          time: t,
        );
      case ItemType.environment:
        paintEnvironment(
          canvas,
          size,
          item.id,
          t,
          boardId: loadout[ItemType.board]!,
        );
      case ItemType.checker:
        final st = checkerStyle(item.id);
        final r = size.shortestSide * 0.22;
        final bob = math.sin(t * 2) * 3;
        canvas.drawRect(
          Offset.zero & size,
          Paint()..color = const Color(0xFF3A0E15),
        );
        paintChecker(
          canvas,
          size.center(Offset(-r * 1.15, bob)),
          r,
          Side.white,
          st,
          time: t,
        );
        paintChecker(
          canvas,
          size.center(Offset(r * 1.15, -bob)),
          r,
          Side.black,
          st,
          time: t,
        );
      case ItemType.dice:
        final st = diceStyle(item.id);
        final s = size.shortestSide * 0.38;
        canvas.drawRect(
          Offset.zero & size,
          Paint()..color = const Color(0xFF1B2A6B),
        );
        final v1 = (t * 1.5).floor() % 6 + 1;
        final v2 = (t * 1.5 + 3).floor() % 6 + 1;
        paintDie(
          canvas,
          size.center(Offset(-s * 0.62, 0)),
          s,
          v1,
          st,
          angle: math.sin(t) * 0.2,
          time: t,
        );
        paintDie(
          canvas,
          size.center(Offset(s * 0.62, 0)),
          s,
          v2,
          st,
          angle: -math.sin(t) * 0.2,
          time: t,
        );
      case ItemType.victory:
        _victory(canvas, size);
      default:
        break;
    }
  }

  void _victory(Canvas canvas, Size size) {
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = const Color(0xFF0B0F1F),
    );
    final rng = ArtRng(item.id.hashCode);
    for (var k = 0; k < 40; k++) {
      final x = rng.next() * size.width;
      final speed = 20 + rng.next() * 40;
      final phase = rng.next() * 10;
      final y = (phase * 30 + t * speed) % (size.height + 20) - 10;
      switch (item.id) {
        case 'vic_petals':
          canvas.save();
          canvas.translate(x + math.sin(t + k) * 8, y);
          canvas.rotate(t + k);
          canvas.drawOval(
            const Rect.fromLTWH(-5, -3, 10, 6),
            Paint()
              ..color = Color.lerp(
                const Color(0xFFE23E57),
                const Color(0xFFFF9AB0),
                rng.next(),
              )!,
          );
          canvas.restore();
        case 'vic_coins':
          canvas.save();
          canvas.translate(x, y);
          canvas.scale(math.cos(t * 3 + k).abs() + 0.2, 1);
          canvas.drawCircle(
            Offset.zero,
            6,
            Paint()..color = AppColors.goldLight,
          );
          canvas.restore();
        case 'vic_lanterns':
          final yy = size.height - y;
          canvas.drawCircle(
            Offset(x, yy),
            10,
            Paint()
              ..color = const Color(0x55FF9E3D)
              ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
          );
          canvas.drawRRect(
            RRect.fromRectAndRadius(
              Rect.fromCenter(center: Offset(x, yy), width: 8, height: 11),
              const Radius.circular(3),
            ),
            Paint()..color = const Color(0xFFFFC27A),
          );
        default:
          final c = Offset(
            size.width * (0.25 + (k % 3) * 0.25),
            size.height * 0.4,
          );
          final a = k / 40 * math.pi * 2;
          final pr = ((t * 0.8 + (k % 3) * 0.3) % 1) * size.shortestSide * 0.4;
          canvas.drawCircle(
            c + Offset(math.cos(a), math.sin(a)) * pr,
            2.2,
            Paint()
              ..color = HSVColor.fromAHSV(
                1,
                (k * 37 + (k % 3) * 120) % 360.0,
                0.7,
                1,
              ).toColor(),
          );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _PreviewPainter old) =>
      old.t != t || old.item != item;

  static void paintEnvironment(
    Canvas canvas,
    Size size,
    String envId,
    double t, {
    required String boardId,
  }) {
    final env = _envs.putIfAbsent(envId, () {
      return EnvironmentLayer(
        envId: envId,
        fx: FxLayer(reducedMotion: true),
        boardRect: () => Rect.zero,
        reducedMotion: true,
      );
    });
    final l = BoardLayout(Size(size.width * 0.7, size.height * 0.7));
    env
      ..size = size
      ..time = t
      ..boardRect = (() =>
          l.outer.shift(Offset(size.width * 0.15, size.height * 0.15)));
    env.render(canvas);
    canvas.save();
    canvas.translate(size.width * 0.15, size.height * 0.15);
    BoardArt(boardTheme(boardId), l).paint(canvas);
    canvas.restore();
  }
}

/// Board + checkers + dice composite used by store tiles and the locker.
void paintBoardScene(
  Canvas canvas,
  Size size, {
  required String boardId,
  required String checkerId,
  required String diceId,
  double time = 0,
}) {
  final l = BoardLayout(size);
  final theme = boardTheme(boardId);
  final art = BoardArt(theme, l)..paintBase(canvas);
  if (theme.pattern == BoardPattern.cosmic) {
    canvas.save();
    canvas.clipRect(l.field);
    Shaders.paintNebula(
      canvas,
      l.field,
      time,
      theme.nebulaA,
      theme.nebulaB,
      theme.nebulaC,
    );
    canvas.restore();
  } else {
    art.paintFelt(canvas);
  }
  art.paintTop(canvas);
  final b = Board.initial();
  final st = checkerStyle(checkerId);
  for (var abs = 1; abs <= 24; abs++) {
    final (side, n) = b.atAbsolute(abs);
    if (side == null) continue;
    for (var k = 0; k < n; k++) {
      paintChecker(
        canvas,
        l.checkerCenter(PointSlot(abs), k, n),
        l.checkerR,
        side,
        st,
        time: time,
      );
    }
  }
  final dc = l.diceCenter(Side.white);
  final ds = diceStyle(diceId);
  paintDie(
    canvas,
    dc.translate(-l.dieSize * 0.65, 0),
    l.dieSize,
    6,
    ds,
    angle: 0.15,
    time: time,
  );
  paintDie(
    canvas,
    dc.translate(l.dieSize * 0.65, 0),
    l.dieSize,
    3,
    ds,
    angle: -0.1,
    time: time,
  );
}

class EmoteBubble extends StatelessWidget {
  const EmoteBubble({required this.text, super.key});
  final String text;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
    decoration: BoxDecoration(
      color: AppColors.ivory,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: AppColors.gold, width: 2),
      boxShadow: const [
        BoxShadow(color: Colors.black45, blurRadius: 6, offset: Offset(0, 3)),
      ],
    ),
    child: Text(
      text,
      style: const TextStyle(
        color: AppColors.night,
        fontFamily: AppFonts.display,
        fontSize: 20,
      ),
    ),
  );
}

/// Big composite preview for the locker.
class LoadoutPreview extends StatefulWidget {
  const LoadoutPreview({required this.loadout, super.key});
  final Map<ItemType, String> loadout;

  @override
  State<LoadoutPreview> createState() => _LoadoutPreviewState();
}

class _LoadoutPreviewState extends State<LoadoutPreview>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 20),
  )..repeat();
  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _c,
        builder: (_, _) => CustomPaint(
          size: Size.infinite,
          painter: _LoadoutPainter(widget.loadout, _c.value * 20),
        ),
      ),
    );
  }
}

class _LoadoutPainter extends CustomPainter {
  _LoadoutPainter(this.loadout, this.t);
  final Map<ItemType, String> loadout;
  final double t;
  @override
  void paint(Canvas canvas, Size size) {
    _PreviewPainter.paintEnvironment(
      canvas,
      size,
      loadout[ItemType.environment]!,
      t,
      boardId: loadout[ItemType.board]!,
    );
    final inner = Size(size.width * 0.7, size.height * 0.7);
    canvas.save();
    canvas.translate(size.width * 0.15, size.height * 0.15);
    paintBoardScene(
      canvas,
      inner,
      boardId: loadout[ItemType.board]!,
      checkerId: loadout[ItemType.checker]!,
      diceId: loadout[ItemType.dice]!,
      time: t,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _LoadoutPainter old) => true;
}
