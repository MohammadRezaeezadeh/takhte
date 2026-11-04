import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:haftnard/core/effects/cards.dart';
import 'package:haftnard/game/audio.dart';
import 'package:haftnard/ui/app.dart';
import 'package:haftnard/ui/theme.dart';
import 'package:haftnard/ui/widgets/card_art.dart';
import 'package:haftnard/ui/widgets/jewel.dart';
import 'package:sensors_plus/sensors_plus.dart';

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

  /// Device tilt parallax (disabled in tests / headless runs).
  static bool useSensors = true;

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
  StreamSubscription<AccelerometerEvent>? _accel;

  /// Smoothed device tilt (-1..1), drives the card parallax.
  Offset _gyro = Offset.zero;

  @override
  void initState() {
    super.initState();
    _listenToTilt();
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

  void _listenToTilt() {
    if (!SevenOverlay.useSensors) return;
    try {
      _accel =
          accelerometerEventStream(
            samplingPeriod: SensorInterval.uiInterval,
          ).listen(
            (e) {
              if (!mounted || MediaQuery.of(context).disableAnimations) return;
              final target = Offset(
                (-e.x / 6).clamp(-1, 1),
                ((e.y - 6.5) / 6).clamp(-1, 1),
              );
              setState(() => _gyro = Offset.lerp(_gyro, target, 0.3)!);
            },
            onError: (Object _) => _accel?.cancel(),
            cancelOnError: true,
          );
    } on Object {
      _accel = null;
    }
  }

  @override
  void dispose() {
    unawaited(_accel?.cancel());
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
                            gyro: _gyro,
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
                  const SizedBox(height: 18),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child: _selected == null
                        ? const SizedBox(height: 64)
                        : Padding(
                            key: ValueKey(_selected),
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            child: SizedBox(
                              height: 64,
                              child: _CardDetail(
                                card: cardById(widget.offer[_selected!]),
                                lang: lang,
                              ),
                            ),
                          ),
                  ),
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
    required this.gyro,
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
  final Offset gyro;
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
    final tiltX = _tilt.dy * 0.25 + sway * 0.03 + widget.gyro.dy * 0.18;
    final tiltY =
        _tilt.dx * 0.25 +
        widget.gyro.dx * 0.22 +
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

class _CardDetail extends StatelessWidget {
  const _CardDetail({required this.card, required this.lang});
  final CardDef card;
  final String lang;
  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      Text(
        card.desc(lang),
        textAlign: TextAlign.center,
        maxLines: 2,
        style: const TextStyle(
          fontSize: 15,
          color: AppColors.ivory,
          height: 1.35,
        ),
      ),
      if (card.drawback(lang) != null)
        Text(
          card.drawback(lang)!,
          textAlign: TextAlign.center,
          maxLines: 1,
          style: const TextStyle(fontSize: 13, color: Color(0xFFFF8A8A)),
        ),
    ],
  );
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
    return LayoutBuilder(
      builder: (context, box) => box.maxWidth < 260
          ? CardFace(
              card: def,
              lang: context.lang,
              width: math.min(88, box.maxWidth),
              frameId: frameId,
              compact: true,
            )
          : _wide(context, def),
    );
  }

  Widget _wide(BuildContext context, CardDef def) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 380),
      child: Panel(
        glow: AppColors.rarity(def.rarity.index),
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            CardFace(
              card: def,
              lang: context.lang,
              width: 88,
              frameId: frameId,
              compact: true,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    context.l10n.opponentChose(def.name(context.lang), who),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFamily: AppFonts.display,
                      fontSize: 18,
                      color: AppColors.goldLight,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    def.desc(context.lang),
                    maxLines: 4,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 13),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
