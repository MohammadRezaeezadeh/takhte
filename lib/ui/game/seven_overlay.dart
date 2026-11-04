import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:haftnard/core/effects/cards.dart';
import 'package:haftnard/game/audio.dart';
import 'package:haftnard/ui/app.dart';
import 'package:haftnard/ui/theme.dart';
import 'package:haftnard/ui/widgets/card_art.dart';
import 'package:haftnard/ui/widgets/jewel.dart';

/// The Double Seven moment: dim, fanfare title, three cards dealt face-down
/// that flip with a 3D tilt; tap to inspect, tap again (or Choose) to take.
class SevenOverlay extends StatefulWidget {
  const SevenOverlay({
    required this.offer,
    required this.picksLeft,
    required this.onPick,
    required this.backId,
    required this.frameId,
    super.key,
  });

  final List<String> offer;
  final int picksLeft;
  final void Function(int index) onPick;
  final String backId;
  final String frameId;

  @override
  State<SevenOverlay> createState() => _SevenOverlayState();
}

class _SevenOverlayState extends State<SevenOverlay>
    with TickerProviderStateMixin {
  late final AnimationController _intro = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1800),
  )..forward();
  late final AnimationController _idle = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 6),
  )..repeat();
  int? _selected;
  bool _picked = false;

  @override
  void initState() {
    super.initState();
    for (var i = 0; i < widget.offer.length; i++) {
      Timer(
        Duration(milliseconds: 600 + i * 140),
        () => Sfx.instance.play('card_whoosh', volume: 0.7),
      );
      Timer(
        Duration(milliseconds: 1050 + i * 140),
        () => Sfx.instance.play('card_flip'),
      );
    }
  }

  @override
  void didUpdateWidget(covariant SevenOverlay old) {
    super.didUpdateWidget(old);
    if (old.offer.length != widget.offer.length) {
      _selected = null;
      _picked = false;
    }
  }

  @override
  void dispose() {
    _intro.dispose();
    _idle.dispose();
    super.dispose();
  }

  void _tap(int i) {
    if (_picked) return;
    if (_selected == i) {
      _confirm();
      return;
    }
    Sfx.instance.play('ui_tick');
    Sfx.instance.haptic(HapticKind.light);
    setState(() => _selected = i);
  }

  void _confirm() {
    final i = _selected;
    if (i == null || _picked) return;
    setState(() => _picked = true);
    Sfx.instance.haptic(HapticKind.medium);
    widget.onPick(i);
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final lang = context.lang;
    final size = MediaQuery.sizeOf(context);
    final n = widget.offer.length;
    final cardW = math
        .min<double>((size.width - 40) / n - 10, 170)
        .clamp(90.0, 170.0);
    final reduce = MediaQuery.of(context).disableAnimations;
    return AnimatedBuilder(
      animation: Listenable.merge([_intro, _idle]),
      builder: (context, _) {
        final t = reduce ? 1.0 : _intro.value;
        final dim = Curves.easeOut.transform((t * 3).clamp(0, 1));
        final titleT = Curves.elasticOut.transform(((t - 0.1) * 2).clamp(0, 1));
        return Stack(
          children: [
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    radius: 1,
                    colors: [
                      Color.fromRGBO(80, 50, 10, 0.75 * dim),
                      Color.fromRGBO(5, 5, 15, 0.9 * dim),
                    ],
                  ),
                ),
              ),
            ),
            SafeArea(
              child: Column(
                children: [
                  const Spacer(),
                  Transform.scale(
                    scale: 0.4 + 0.6 * titleT,
                    child: Opacity(
                      opacity: titleT.clamp(0, 1),
                      child: Column(
                        children: [
                          Text(
                            l.sevenTitle,
                            style: TextStyle(
                              fontFamily: AppFonts.display,
                              fontSize: 44,
                              color: AppColors.goldLight,
                              shadows: [
                                Shadow(
                                  blurRadius:
                                      24 +
                                      8 *
                                          math.sin(
                                            _idle.value * 2 * math.pi * 3,
                                          ),
                                  color: const Color(0xFFFFB347),
                                ),
                                const Shadow(
                                  blurRadius: 2,
                                  offset: Offset(0, 3),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            widget.picksLeft > 1
                                ? l.chooseTwo(widget.picksLeft)
                                : l.choosePower,
                            style: const TextStyle(
                              fontSize: 18,
                              color: AppColors.ivory,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      for (var i = 0; i < n; i++)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 5),
                          child: _DealtCard(
                            card: cardById(widget.offer[i]),
                            lang: lang,
                            width: cardW,
                            deal: reduce
                                ? 1
                                : ((t - 0.3 - i * 0.08) / 0.35).clamp(0, 1),
                            flip: reduce
                                ? 1
                                : ((t - 0.55 - i * 0.08) / 0.3).clamp(0, 1),
                            idle: _idle.value,
                            index: i,
                            selected: _selected == i,
                            dimmed: _selected != null && _selected != i,
                            backId: widget.backId,
                            frameId: widget.frameId,
                            onTap: () => _tap(i),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 22),
                  AnimatedOpacity(
                    duration: const Duration(milliseconds: 200),
                    opacity: _selected == null ? 0 : 1,
                    child: JewelButton(
                      label: l.confirm,
                      icon: Icons.check,
                      color: AppColors.emerald,
                      expand: false,
                      onPressed: _selected == null ? null : _confirm,
                    ),
                  ),
                  const Spacer(),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _DealtCard extends StatefulWidget {
  const _DealtCard({
    required this.card,
    required this.lang,
    required this.width,
    required this.deal,
    required this.flip,
    required this.idle,
    required this.index,
    required this.selected,
    required this.dimmed,
    required this.backId,
    required this.frameId,
    required this.onTap,
  });

  final CardDef card;
  final String lang;
  final double width;
  final double deal;
  final double flip;
  final double idle;
  final int index;
  final bool selected;
  final bool dimmed;
  final String backId;
  final String frameId;
  final VoidCallback onTap;

  @override
  State<_DealtCard> createState() => _DealtCardState();
}

class _DealtCardState extends State<_DealtCard> {
  Offset _tilt = Offset.zero;

  @override
  Widget build(BuildContext context) {
    final d = Curves.easeOutCubic.transform(widget.deal);
    final f = Curves.easeInOutCubic.transform(widget.flip);
    final angleY = math.pi * (1 - f);
    final showFront = angleY < math.pi / 2;
    final sway = math.sin(widget.idle * 2 * math.pi + widget.index * 1.3);
    final tiltX = _tilt.dy * 0.25 + sway * 0.03;
    final tiltY =
        _tilt.dx * 0.25 +
        math.cos(widget.idle * 2 * math.pi + widget.index) * 0.04;
    final lift = widget.selected ? -26.0 : 0.0;
    final m = Matrix4.identity()
      ..setEntry(3, 2, 0.0016)
      ..translateByDouble(0, (1 - d) * -420 + lift, 0, 1)
      ..rotateZ((1 - d) * (widget.index - 1) * 0.6)
      ..rotateX(tiltX)
      ..rotateY(angleY + tiltY)
      ..scaleByDouble(
        widget.selected ? 1.1 : 1.0,
        widget.selected ? 1.1 : 1.0,
        1,
        1,
      );
    return Opacity(
      opacity: d.clamp(0, 1) * (widget.dimmed ? 0.6 : 1),
      child: Semantics(
        button: true,
        label:
            '${widget.card.name(widget.lang)}. ${widget.card.desc(widget.lang)}',
        child: GestureDetector(
          onTap: widget.onTap,
          onPanUpdate: (e) => setState(() {
            _tilt = Offset(
              (_tilt.dx + e.delta.dx / 120).clamp(-1, 1),
              (_tilt.dy - e.delta.dy / 120).clamp(-1, 1),
            );
          }),
          onPanEnd: (_) => setState(() => _tilt = Offset.zero),
          child: Transform(
            alignment: Alignment.center,
            transform: m,
            child: showFront
                ? CardFace(
                    card: widget.card,
                    lang: widget.lang,
                    width: widget.width,
                    frameId: widget.frameId,
                    time: widget.idle * 6,
                    shine: tiltY * 3 + sway * 0.4,
                  )
                : Transform(
                    alignment: Alignment.center,
                    transform: Matrix4.rotationY(math.pi),
                    child: CardBack(backId: widget.backId, width: widget.width),
                  ),
          ),
        ),
      ),
    );
  }
}

/// Shows which card the AI took.
class CardReveal extends StatelessWidget {
  const CardReveal({
    required this.who,
    required this.cardId,
    required this.frameId,
    super.key,
  });
  final String who;
  final String cardId;
  final String frameId;

  @override
  Widget build(BuildContext context) {
    final def = cardById(cardId);
    return Panel(
      glow: AppColors.rarity(def.rarity.index),
      padding: const EdgeInsets.all(12),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          CardFace(
            card: def,
            lang: context.lang,
            width: 88,
            frameId: frameId,
            compact: true,
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  context.l10n.opponentChose(who, def.name(context.lang)),
                  style: const TextStyle(
                    fontFamily: AppFonts.display,
                    fontSize: 18,
                    color: AppColors.goldLight,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  def.desc(context.lang),
                  style: const TextStyle(fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
