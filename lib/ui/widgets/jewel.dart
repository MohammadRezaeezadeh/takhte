import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:haftnard/game/audio.dart';
import 'package:haftnard/game/themes/board_themes.dart';
import 'package:haftnard/ui/theme.dart';

/// Big tactile button with press depth, sound and haptics.
class JewelButton extends StatefulWidget {
  const JewelButton({
    required this.label,
    required this.onPressed,
    super.key,
    this.icon,
    this.color = AppColors.lapis,
    this.accent = AppColors.gold,
    this.subtitle,
    this.height = 64,
    this.fontSize = 22,
    this.badge,
    this.enabled = true,
    this.expand = true,
  });

  final String label;
  final String? subtitle;
  final VoidCallback? onPressed;
  final IconData? icon;
  final Color color;
  final Color accent;
  final double height;
  final double fontSize;
  final String? badge;
  final bool enabled;
  final bool expand;

  @override
  State<JewelButton> createState() => _JewelButtonState();
}

class _JewelButtonState extends State<JewelButton> {
  bool _down = false;

  bool get _active => widget.enabled && widget.onPressed != null;

  @override
  Widget build(BuildContext context) {
    final depth = _down ? 1.0 : 5.0;
    final c = _active
        ? widget.color
        : Color.lerp(widget.color, Colors.black, 0.5)!;
    final content = Row(
      mainAxisSize: widget.expand ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (widget.icon != null) ...[
          Icon(
            widget.icon,
            color: AppColors.goldLight,
            size: widget.fontSize + 4,
          ),
          const SizedBox(width: 10),
        ],
        Flexible(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                widget.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: AppFonts.display,
                  fontSize: widget.fontSize,
                  height: 1.1,
                  color: _active ? AppColors.ivory : AppColors.muted,
                  shadows: const [Shadow(blurRadius: 4, color: Colors.black54)],
                ),
              ),
              if (widget.subtitle != null)
                Text(
                  widget.subtitle!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: widget.fontSize * 0.5,
                    color: AppColors.ivory.withValues(alpha: 0.7),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
    return Semantics(
      button: true,
      enabled: _active,
      label: widget.label,
      child: GestureDetector(
        onTapDown: _active ? (_) => setState(() => _down = true) : null,
        onTapCancel: () => setState(() => _down = false),
        onTapUp: _active
            ? (_) {
                setState(() => _down = false);
                Sfx.instance.play('ui_confirm', volume: 0.7);
                Sfx.instance.haptic(HapticKind.light);
                widget.onPressed!();
              }
            : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 70),
          constraints: BoxConstraints(minHeight: math.max(48, widget.height)),
          margin: EdgeInsets.only(top: 5 - depth),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color.lerp(c, Colors.white, 0.18)!,
                c,
                Color.lerp(c, Colors.black, 0.25)!,
              ],
            ),
            border: Border.all(
              color: widget.accent.withValues(alpha: _active ? 0.9 : 0.3),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Color.lerp(c, Colors.black, 0.6)!,
                offset: Offset(0, depth),
              ),
              if (_active)
                BoxShadow(
                  color: widget.accent.withValues(alpha: 0.18),
                  blurRadius: 18,
                ),
            ],
          ),
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              content,
              if (widget.badge != null)
                PositionedDirectional(
                  top: -10,
                  end: -12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.ruby,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.goldLight),
                    ),
                    child: Text(
                      widget.badge!,
                      style: const TextStyle(fontSize: 11, color: Colors.white),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Small round icon button (48dp min) with the same feel.
class JewelIconButton extends StatelessWidget {
  const JewelIconButton({
    required this.icon,
    required this.onPressed,
    required this.tooltip,
    super.key,
    this.color = AppColors.inkLight,
    this.size = 48,
  });

  final IconData icon;
  final VoidCallback? onPressed;
  final String tooltip;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Semantics(
        button: true,
        label: tooltip,
        child: Material(
          color: Colors.transparent,
          child: InkResponse(
            radius: size * 0.7,
            onTap: onPressed == null
                ? null
                : () {
                    Sfx.instance.play('ui_tick');
                    Sfx.instance.haptic(HapticKind.light);
                    onPressed!();
                  },
            child: Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color,
                border: Border.all(
                  color: AppColors.gold.withValues(
                    alpha: onPressed == null ? 0.25 : 0.8,
                  ),
                ),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black54,
                    offset: Offset(0, 3),
                    blurRadius: 4,
                  ),
                ],
              ),
              child: Icon(
                icon,
                color: onPressed == null
                    ? AppColors.muted
                    : AppColors.goldLight,
                size: size * 0.5,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Ornamented panel.
class Panel extends StatelessWidget {
  const Panel({
    required this.child,
    super.key,
    this.padding = const EdgeInsets.all(16),
    this.glow,
  });
  final Widget child;
  final EdgeInsets padding;
  final Color? glow;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.inkLight.withValues(alpha: 0.95),
            AppColors.ink.withValues(alpha: 0.95),
          ],
        ),
        border: Border.all(
          color: (glow ?? AppColors.gold).withValues(alpha: 0.55),
        ),
        boxShadow: [
          const BoxShadow(
            color: Colors.black45,
            blurRadius: 12,
            offset: Offset(0, 6),
          ),
          if (glow != null)
            BoxShadow(color: glow!.withValues(alpha: 0.3), blurRadius: 20),
        ],
      ),
      child: CustomPaint(foregroundPainter: _CornerOrnaments(), child: child),
    );
  }
}

class _CornerOrnaments extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()..color = AppColors.gold.withValues(alpha: 0.6);
    for (final o in [
      const Offset(-6, -6),
      Offset(size.width + 6, -6),
      Offset(-6, size.height + 6),
      Offset(size.width + 6, size.height + 6),
    ]) {
      BoardArt.star(canvas, o, 5, 4, p);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Coins / gems pill.
class CurrencyChip extends StatelessWidget {
  const CurrencyChip({required this.amount, required this.gem, super.key});
  final int amount;
  final bool gem;

  @override
  Widget build(BuildContext context) {
    final lang = Localizations.localeOf(context).languageCode;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.black45,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: (gem ? AppColors.turquoiseLight : AppColors.goldLight)
              .withValues(alpha: 0.6),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          CustomPaint(
            size: const Size(18, 18),
            painter: CurrencyIconPainter(gem: gem),
          ),
          const SizedBox(width: 6),
          Text(
            formatNumber(amount, lang),
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
          ),
        ],
      ),
    );
  }
}

class CurrencyIconPainter extends CustomPainter {
  CurrencyIconPainter({required this.gem});
  final bool gem;
  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.shortestSide / 2;
    if (gem) {
      final path = Path()
        ..moveTo(c.dx, c.dy - r)
        ..lineTo(c.dx + r * 0.85, c.dy - r * 0.2)
        ..lineTo(c.dx, c.dy + r)
        ..lineTo(c.dx - r * 0.85, c.dy - r * 0.2)
        ..close();
      canvas.drawPath(path, Paint()..color = AppColors.turquoiseLight);
      canvas.drawPath(
        Path()
          ..moveTo(c.dx, c.dy - r)
          ..lineTo(c.dx + r * 0.85, c.dy - r * 0.2)
          ..lineTo(c.dx, c.dy)
          ..close(),
        Paint()..color = Colors.white.withValues(alpha: 0.5),
      );
    } else {
      canvas.drawCircle(c, r, Paint()..color = const Color(0xFFB8861C));
      canvas.drawCircle(c, r * 0.82, Paint()..color = AppColors.goldLight);
      BoardArt.star(
        canvas,
        c,
        r * 0.5,
        7,
        Paint()..color = const Color(0xFFB8861C),
      );
    }
  }

  @override
  bool shouldRepaint(covariant CurrencyIconPainter oldDelegate) =>
      oldDelegate.gem != gem;
}

/// Formats [n] with Persian digits for 'fa'.
String formatNumber(int n, String lang) {
  final s = n.toString().replaceAllMapped(
    RegExp(r'\B(?=(\d{3})+(?!\d))'),
    (_) => ',',
  );
  return lang == 'fa' ? toPersianDigits(s.replaceAll(',', '٬')) : s;
}

String toPersianDigits(String s) {
  const fa = '۰۱۲۳۴۵۶۷۸۹';
  return s.replaceAllMapped(RegExp('[0-9]'), (m) => fa[int.parse(m[0]!)]);
}

/// Title with ornamental flourishes.
class OrnateTitle extends StatelessWidget {
  const OrnateTitle(this.text, {super.key, this.size = 30});
  final String text;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const _Flourish(),
        const SizedBox(width: 10),
        Flexible(
          child: Text(
            text,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: AppFonts.display,
              fontSize: size,
              color: AppColors.goldLight,
              shadows: const [Shadow(blurRadius: 12, color: Color(0x99FFB347))],
            ),
          ),
        ),
        const SizedBox(width: 10),
        const _Flourish(flip: true),
      ],
    );
  }
}

class _Flourish extends StatelessWidget {
  const _Flourish({this.flip = false});
  final bool flip;
  @override
  Widget build(BuildContext context) {
    return Transform.flip(
      flipX: flip,
      child: CustomPaint(size: const Size(36, 14), painter: _FlourishPainter()),
    );
  }
}

class _FlourishPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = AppColors.gold
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    final y = size.height / 2;
    canvas.drawLine(Offset(0, y), Offset(size.width - 8, y), p);
    BoardArt.star(
      canvas,
      Offset(size.width - 4, y),
      4,
      4,
      Paint()..color = AppColors.goldLight,
    );
    canvas.drawCircle(
      Offset(size.width * 0.3, y),
      2,
      Paint()..color = AppColors.gold,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
