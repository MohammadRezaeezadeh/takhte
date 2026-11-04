import 'dart:async';

import 'package:flutter/material.dart';
import 'package:haftnard/core/effects/cards.dart';
import 'package:haftnard/core/rules/actions.dart';
import 'package:haftnard/core/rules/engine.dart';
import 'package:haftnard/core/rules/state.dart';
import 'package:haftnard/core/rules/types.dart';
import 'package:haftnard/game/match_controller.dart';
import 'package:haftnard/ui/app.dart';
import 'package:haftnard/ui/theme.dart';
import 'package:haftnard/ui/widgets/avatar.dart';
import 'package:haftnard/ui/widgets/card_art.dart';
import 'package:haftnard/ui/widgets/jewel.dart';

/// Card used to illustrate an ongoing effect.
String cardForEffect(EffectKind k) => switch (k) {
  EffectKind.brokenDie => CardId.brokenDie,
  EffectKind.fog => CardId.fog,
  EffectKind.curse => CardId.curse,
  EffectKind.chains => CardId.chains,
  EffectKind.shield => CardId.holyShield,
  EffectKind.ironGate => CardId.ironGate,
  EffectKind.quicksand => CardId.quicksand,
  EffectKind.quicksandFreeze => CardId.quicksand,
  EffectKind.toll => CardId.tollGate,
  EffectKind.landmine => CardId.landmine,
  EffectKind.sevenMagnet => CardId.sevenMagnet,
  EffectKind.loadedHand => CardId.loadedHand,
  EffectKind.fateEdit => CardId.fatesEdit,
  EffectKind.mirrorWatch => CardId.mirror,
  EffectKind.mirrorBonus => CardId.mirror,
  EffectKind.skipTurn => CardId.gamblersCoin,
  EffectKind.bonusPick => CardId.timeStop,
  EffectKind.bonusOffer => CardId.greed,
  EffectKind.sevenBlock => CardId.nightfall,
  EffectKind.sixNext => CardId.luckySix,
  EffectKind.truce => CardId.truce,
  EffectKind.tailwind => CardId.tailwind,
  EffectKind.headwind => CardId.headwind,
};

/// Effects whose turn counter is meaningful to show.
bool _showsCounter(EffectKind k) =>
    !(k == EffectKind.bonusPick ||
        k == EffectKind.bonusOffer ||
        k == EffectKind.mirrorBonus);

class EffectChip extends StatelessWidget {
  const EffectChip({
    required this.cardId,
    required this.buff,
    super.key,
    this.turns,
    this.count,
  });
  final String cardId;
  final bool buff;
  final int? turns;
  final int? count;

  @override
  Widget build(BuildContext context) {
    final def = cardById(cardId);
    final lang = context.lang;
    final color = buff ? AppColors.emerald : AppColors.ruby;
    final label =
        '${def.name(lang)}${turns != null ? ' · ${context.l10n.turnsLeft(turns!)}' : ''}';
    return Tooltip(
      triggerMode: TooltipTriggerMode.longPress,
      message:
          '${def.name(lang)}\n${def.desc(lang)}${turns != null ? '\n${context.l10n.turnsLeft(turns!)}' : ''}',
      child: Semantics(
        label: label,
        child: Container(
          width: 34,
          height: 34,
          margin: const EdgeInsets.symmetric(horizontal: 2),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.black54,
            border: Border.all(color: color, width: 2),
          ),
          child: Stack(
            children: [
              Positioned.fill(
                child: CustomPaint(
                  painter: CardGlyphPainter(
                    def.glyph,
                    AppColors.rarity(def.rarity.index),
                  ),
                ),
              ),
              if (turns != null || count != null)
                PositionedDirectional(
                  bottom: -1,
                  end: -1,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      formatNumber(count ?? turns!, lang),
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
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

/// Player/opponent information strip.
class PlayerPanel extends StatefulWidget {
  const PlayerPanel({
    required this.controller,
    required this.side,
    required this.showPips,
    super.key,
  });
  final MatchController controller;
  final Side side;
  final bool showPips;

  @override
  State<PlayerPanel> createState() => _PlayerPanelState();
}

class _PlayerPanelState extends State<PlayerPanel>
    with SingleTickerProviderStateMixin {
  late final AnimationController _t = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 10),
  )..repeat();

  @override
  void dispose() {
    _t.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.controller;
    final s = c.state;
    final side = widget.side;
    final seat = c.session.seat(side);
    final l = context.l10n;
    final lang = context.lang;
    final active =
        !s.isOver && Engine.actor(s) == side && s.phase != Phase.opening;
    final inv = s.inv(side);
    final effects = s.effects
        .where(
          (e) =>
              e.affected == side &&
              (e.kind != EffectKind.landmine || c.isHuman(e.owner)),
        )
        .toList();
    final p = seat.personality;
    final checkerColor = side == Side.white
        ? const Color(0xFFE9CFA0)
        : const Color(0xFF5A3420);
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: AppColors.ink.withValues(alpha: 0.88),
        border: Border.all(
          color: active ? AppColors.goldLight : Colors.white10,
          width: 2,
        ),
        boxShadow: active
            ? [
                BoxShadow(
                  color: AppColors.goldLight.withValues(alpha: 0.35),
                  blurRadius: 16,
                ),
              ]
            : null,
      ),
      child: Row(
        children: [
          AnimatedBuilder(
            animation: _t,
            builder: (_, _) => p != null
                ? Avatar.forPersonality(p, size: 44, time: _t.value * 10)
                : Avatar(
                    style: 'player',
                    hue: side == Side.white ? 30 : 250,
                    size: 44,
                    seed: side.index + 2,
                  ),
          ),
          const SizedBox(width: 8),
          Container(
            width: 14,
            height: 14,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: checkerColor,
              border: Border.all(color: Colors.black54),
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        seat.name.isEmpty
                            ? (p?.name(lang) ?? l.you)
                            : seat.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                        ),
                      ),
                    ),
                    if (c.aiThinking &&
                        Engine.actor(s) == side &&
                        !c.isHuman(side)) ...[
                      const SizedBox(width: 6),
                      const _ThinkingDots(),
                    ],
                  ],
                ),
                Row(
                  children: [
                    if (widget.showPips)
                      Text(
                        l.pipsN(s.board.pips(side)),
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.muted,
                        ),
                      ),
                    if (c.match.config.length > 1) ...[
                      const SizedBox(width: 8),
                      Text(
                        '${l.score}: ${formatNumber(c.match.score(side), lang)}/${formatNumber(c.match.config.length, lang)}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.goldLight,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          if (inv.rerolls > 0)
            EffectChip(
              cardId: CardId.secondChance,
              buff: true,
              count: inv.rerolls,
            ),
          if (inv.lucky > 0)
            EffectChip(cardId: CardId.luckyCharm, buff: true, count: inv.lucky),
          if (inv.ghost > 0)
            EffectChip(cardId: CardId.ghostStep, buff: true, count: inv.ghost),
          if (inv.phoenix > 0)
            EffectChip(cardId: CardId.phoenix, buff: true, count: inv.phoenix),
          for (final e in effects.take(4))
            EffectChip(
              cardId: cardForEffect(e.kind),
              buff: e.owner == side,
              turns: _showsCounter(e.kind) && e.turnsLeft < 50
                  ? e.turnsLeft
                  : null,
            ),
          if (s.config.cubeEnabled &&
              (s.cubeOwner == side ||
                  (s.cubeOwner == null &&
                      side == Side.black &&
                      s.cubeValue > 1)))
            _CubeBadge(value: s.cubeValue),
        ],
      ),
    );
  }
}

class _CubeBadge extends StatelessWidget {
  const _CubeBadge({required this.value});
  final int value;
  @override
  Widget build(BuildContext context) => Container(
    width: 30,
    height: 30,
    margin: const EdgeInsetsDirectional.only(start: 4),
    alignment: Alignment.center,
    decoration: BoxDecoration(
      color: AppColors.ivory,
      borderRadius: BorderRadius.circular(6),
      border: Border.all(color: AppColors.gold, width: 2),
    ),
    child: Text(
      '${value < 2 ? 64 : value}',
      style: const TextStyle(
        color: AppColors.night,
        fontWeight: FontWeight.w900,
        fontSize: 13,
      ),
    ),
  );
}

class _ThinkingDots extends StatefulWidget {
  const _ThinkingDots();
  @override
  State<_ThinkingDots> createState() => _ThinkingDotsState();
}

class _ThinkingDotsState extends State<_ThinkingDots>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..repeat();
  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _c,
    builder: (_, _) => Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < 3; i++)
          Container(
            width: 5,
            height: 5,
            margin: const EdgeInsets.symmetric(horizontal: 1.5),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.goldLight.withValues(
                alpha: ((_c.value * 3 - i) % 3) < 1 ? 1 : 0.3,
              ),
            ),
          ),
      ],
    ),
  );
}

/// Context-sensitive action buttons for the human whose turn it is.
class ActionBar extends StatelessWidget {
  const ActionBar({
    required this.controller,
    required this.onLucky,
    required this.onFate,
    required this.leftHanded,
    super.key,
  });
  final MatchController controller;
  final VoidCallback onLucky;
  final VoidCallback onFate;
  final bool leftHanded;

  @override
  Widget build(BuildContext context) {
    final c = controller;
    final s = c.state;
    final l = context.l10n;
    if (!c.waitingForHuman) return const SizedBox(height: 64);
    final buttons = <Widget>[];
    void add(Widget w) => buttons.add(
      Padding(padding: const EdgeInsets.symmetric(horizontal: 4), child: w),
    );
    switch (s.phase) {
      case Phase.opening:
        add(
          JewelButton(
            label: l.rollOpening,
            icon: Icons.casino,
            color: AppColors.emerald,
            expand: false,
            height: 54,
            fontSize: 18,
            onPressed: () => unawaited(c.act(const RollOpening())),
          ),
        );
      case Phase.preRoll:
        if (Engine.canOfferDouble(s)) {
          add(
            JewelButton(
              label: l.double,
              icon: Icons.filter_2,
              color: AppColors.ruby,
              expand: false,
              height: 54,
              fontSize: 18,
              onPressed: () => unawaited(c.act(const OfferDouble())),
            ),
          );
        }
        add(
          JewelButton(
            label: l.tapToRoll,
            icon: Icons.casino,
            color: AppColors.emerald,
            expand: false,
            height: 54,
            fontSize: 16,
            onPressed: () => unawaited(c.act(const RollDice())),
          ),
        );
      case Phase.moving:
        if (c.canUndo) {
          add(
            JewelIconButton(
              icon: Icons.undo,
              tooltip: l.undo,
              onPressed: c.undo,
            ),
          );
        }
        if (Engine.canAlterRoll(s)) {
          final inv = s.inv(s.current);
          if (inv.rerolls > 0) {
            add(
              JewelButton(
                label: l.useReroll,
                icon: Icons.refresh,
                color: AppColors.violet,
                expand: false,
                height: 50,
                fontSize: 15,
                onPressed: () => unawaited(c.act(const UseReroll())),
              ),
            );
          }
          if (inv.lucky > 0 && s.dice.any((d) => d < 6)) {
            add(
              JewelButton(
                label: l.useLucky,
                color: AppColors.violet,
                expand: false,
                height: 50,
                fontSize: 18,
                onPressed: onLucky,
              ),
            );
          }
          if (Engine.canSetFate(s)) {
            add(
              JewelButton(
                label: l.useFate,
                icon: Icons.auto_fix_high,
                color: AppColors.violet,
                expand: false,
                height: 50,
                fontSize: 15,
                onPressed: onFate,
              ),
            );
          }
        }
        if (Engine.canEndTurn(s)) {
          add(
            JewelButton(
              label: l.done,
              icon: Icons.check,
              color: AppColors.emerald,
              expand: false,
              height: 54,
              fontSize: 20,
              onPressed: () => unawaited(c.act(const EndTurn())),
            ),
          );
        }
      default:
        break;
    }
    return SizedBox(
      height: 64,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: leftHanded ? buttons.reversed.toList() : buttons,
      ),
    );
  }
}
