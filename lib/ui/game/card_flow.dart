import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:haftnard/core/effects/cards.dart';
import 'package:haftnard/ui/app.dart';
import 'package:haftnard/ui/game/card_tags.dart';
import 'package:haftnard/ui/theme.dart';
import 'package:haftnard/ui/widgets/card_art.dart';
import 'package:haftnard/ui/widgets/jewel.dart';

/// The opponent's 7–7: the offer for a moment, then the chosen card large in
/// the centre with its plain sentence, until the player taps «فهمیدم».
class AiPickOverlay extends StatelessWidget {
  const AiPickOverlay({
    required this.offer,
    required this.picked,
    required this.frameId,
    required this.onAck,
    super.key,
  });

  final List<String> offer;

  /// Null while the opponent is still choosing.
  final String? picked;
  final String frameId;
  final VoidCallback onAck;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final lang = context.lang;
    final pick = picked;
    return ColoredBox(
      color: const Color(0xC0000000),
      child: SafeArea(
        child: Center(
          child: pick == null
              ? Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      l.aiOffer,
                      style: const TextStyle(
                        fontFamily: AppFonts.display,
                        fontSize: 22,
                        color: AppColors.goldLight,
                      ),
                    ),
                    const SizedBox(height: 12),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          for (final id in offer)
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 4,
                              ),
                              child: CardFace(
                                card: cardById(id),
                                lang: lang,
                                width: 96,
                                frameId: frameId,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                )
              : TweenAnimationBuilder<double>(
                  key: ValueKey('ai-pick-$pick'),
                  tween: Tween(begin: 0, end: 1),
                  duration: const Duration(milliseconds: 380),
                  curve: Curves.easeOutBack,
                  builder: (_, v, child) => Transform.scale(
                    scale: 0.6 + 0.4 * v,
                    child: Opacity(opacity: v.clamp(0, 1), child: child),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Panel(
                      key: const ValueKey('ai-pick-overlay'),
                      glow: AppColors.rarity(cardById(pick).rarity.index),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            l.aiPickedHeader,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontFamily: AppFonts.display,
                              fontSize: 20,
                              color: AppColors.goldLight,
                            ),
                          ),
                          const SizedBox(height: 10),
                          CardFace(
                            card: cardById(pick),
                            lang: lang,
                            frameId: frameId,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            cardById(pick).name(lang),
                            style: const TextStyle(
                              fontFamily: AppFonts.display,
                              fontSize: 22,
                            ),
                          ),
                          const SizedBox(height: 4),
                          ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 320),
                            child: Text(
                              cardById(pick).desc(lang),
                              textAlign: TextAlign.center,
                              style: const TextStyle(fontSize: 15, height: 1.5),
                            ),
                          ),
                          const SizedBox(height: 6),
                          CardTags(card: cardById(pick)),
                          const SizedBox(height: 12),
                          JewelButton(
                            key: const ValueKey('ai-pick-ack'),
                            label: l.guideNext,
                            icon: Icons.check,
                            color: AppColors.emerald,
                            expand: false,
                            onPressed: onAck,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
        ),
      ),
    );
  }
}

/// A card (or a pending chip) flying across the board with a fading trail.
class CardFlight extends StatelessWidget {
  const CardFlight({
    required this.cardId,
    required this.from,
    required this.to,
    required this.onDone,
    this.chip = false,
    super.key,
  });

  final String cardId;
  final Offset from;
  final Offset to;
  final VoidCallback onDone;

  /// A small round HUD chip instead of a card.
  final bool chip;

  @override
  Widget build(BuildContext context) {
    final def = cardById(cardId);
    final size = chip ? 34.0 : 64.0;
    Widget icon(double opacity, double scale) => Opacity(
      opacity: opacity,
      child: Transform.scale(
        scale: scale,
        child: Container(
          width: size,
          height: chip ? size : size * 1.35,
          decoration: BoxDecoration(
            color: const Color(0xEE1B1530),
            shape: chip ? BoxShape.circle : BoxShape.rectangle,
            borderRadius: chip ? null : BorderRadius.circular(8),
            border: Border.all(
              color: AppColors.rarity(def.rarity.index),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.rarity(def.rarity.index)
                    .withValues(alpha: 0.6),
                blurRadius: 12,
              ),
            ],
          ),
          child: CustomPaint(
            painter: CardGlyphPainter(
              def.glyph,
              AppColors.rarity(def.rarity.index),
            ),
          ),
        ),
      ),
    );
    return IgnorePointer(
      child: TweenAnimationBuilder<double>(
        key: ValueKey('flight-$cardId-$from-$to'),
        tween: Tween(begin: 0, end: 1),
        duration: Duration(milliseconds: chip ? 520 : 620),
        curve: Curves.easeInOutCubic,
        onEnd: onDone,
        builder: (_, t, _) {
          Offset at(double u) {
            // A gentle arc above the straight line.
            final p = Offset.lerp(from, to, u)!;
            return p.translate(0, -math.sin(u * math.pi) * 60);
          }

          final h = chip ? size : size * 1.35;
          return Stack(
            children: [
              for (var k = 4; k >= 1; k--)
                if (t - k * 0.06 > 0)
                  Positioned(
                    left: at(t - k * 0.06).dx - size / 2,
                    top: at(t - k * 0.06).dy - h / 2,
                    child: icon(0.12 * (5 - k), 1 - k * 0.08),
                  ),
              Positioned(
                key: const ValueKey('card-flight'),
                left: at(t).dx - size / 2,
                top: at(t).dy - h / 2,
                child: icon(1, 1 - 0.35 * t),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// The last cards used by both players, to re-read anything missed.
Future<void> showCardHistory(
  BuildContext context,
  List<({String who, String cardId})> history,
) {
  final l = context.l10n;
  final lang = context.lang;
  return showDialog<void>(
    context: context,
    builder: (ctx) => Dialog(
      backgroundColor: Colors.transparent,
      child: Panel(
        key: const ValueKey('card-history'),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: 420,
            maxHeight: MediaQuery.sizeOf(ctx).height * 0.7,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                l.cardHistory,
                style: const TextStyle(
                  fontFamily: AppFonts.display,
                  fontSize: 22,
                  color: AppColors.goldLight,
                ),
              ),
              const SizedBox(height: 8),
              if (history.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(l.cardHistoryEmpty),
                ),
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    for (final h in history)
                      ListTile(
                        dense: true,
                        leading: SizedBox(
                          width: 34,
                          height: 34,
                          child: CustomPaint(
                            painter: CardGlyphPainter(
                              cardById(h.cardId).glyph,
                              AppColors.rarity(cardById(h.cardId).rarity.index),
                            ),
                          ),
                        ),
                        title: Text(
                          '${h.who} · ${cardById(h.cardId).name(lang)}',
                        ),
                        subtitle: Text(
                          cardById(h.cardId).desc(lang),
                          style: const TextStyle(color: AppColors.muted),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
