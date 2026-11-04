import 'dart:async';

import 'package:flutter/material.dart';
import 'package:haftnard/core/rules/types.dart';
import 'package:haftnard/game/audio.dart';
import 'package:haftnard/game/themes/pieces.dart';
import 'package:haftnard/meta/meta_state.dart';
import 'package:haftnard/ui/app.dart';
import 'package:haftnard/ui/theme.dart';
import 'package:haftnard/ui/widgets/jewel.dart';

/// Dice picker used by Loaded Hand, Lucky Charm and Fate's Edit.
class DicePicker extends StatelessWidget {
  const DicePicker({
    required this.values,
    required this.onTap,
    required this.diceId,
    super.key,
    this.selected = const {},
    this.disabled = const {},
    this.size = 58,
  });
  final List<int> values;
  final Set<int> selected;
  final Set<int> disabled;
  final void Function(int index) onTap;
  final String diceId;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 10,
      runSpacing: 10,
      children: [
        for (var i = 0; i < values.length; i++)
          Semantics(
            button: true,
            selected: selected.contains(i),
            label: '${values[i]}',
            child: GestureDetector(
              onTap: disabled.contains(i) ? null : () => onTap(i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: selected.contains(i)
                        ? AppColors.goldLight
                        : Colors.transparent,
                    width: 3,
                  ),
                  color: selected.contains(i)
                      ? AppColors.goldLight.withValues(alpha: 0.15)
                      : Colors.transparent,
                ),
                child: Opacity(
                  opacity: disabled.contains(i) ? 0.35 : 1,
                  child: CustomPaint(
                    size: Size(size, size),
                    painter: _DiePainter(values[i], diceStyle(diceId)),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _DiePainter extends CustomPainter {
  _DiePainter(this.v, this.st);
  final int v;
  final DiceStyle st;
  @override
  void paint(Canvas canvas, Size size) => paintDie(
    canvas,
    size.center(Offset.zero),
    size.shortestSide * 0.86,
    v,
    st,
  );
  @override
  bool shouldRepaint(covariant _DiePainter old) => old.v != v || old.st != st;
}

/// Loaded Hand: choose two of three dice.
class ChooseDiceOverlay extends StatefulWidget {
  const ChooseDiceOverlay({
    required this.values,
    required this.onChoose,
    required this.diceId,
    super.key,
  });
  final List<int> values;
  final void Function(int a, int b) onChoose;
  final String diceId;

  @override
  State<ChooseDiceOverlay> createState() => _ChooseDiceOverlayState();
}

class _ChooseDiceOverlayState extends State<ChooseDiceOverlay> {
  final Set<int> _sel = {};

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Center(
      child: Panel(
        glow: AppColors.goldLight,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              l.chooseDiceTitle,
              style: const TextStyle(
                fontFamily: AppFonts.display,
                fontSize: 22,
                color: AppColors.goldLight,
              ),
            ),
            const SizedBox(height: 12),
            DicePicker(
              values: widget.values,
              selected: _sel,
              diceId: widget.diceId,
              onTap: (i) => setState(() {
                Sfx.instance.play('ui_tick');
                if (!_sel.remove(i)) {
                  if (_sel.length == 2) _sel.remove(_sel.first);
                  _sel.add(i);
                }
              }),
            ),
            const SizedBox(height: 12),
            JewelButton(
              label: l.confirm,
              expand: false,
              color: AppColors.emerald,
              onPressed: _sel.length == 2
                  ? () => widget.onChoose(_sel.first, _sel.last)
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}

/// Generic modal panel helper.
Future<T?> showPanelDialog<T>(
  BuildContext context,
  Widget Function(BuildContext) builder,
) => showDialog<T>(
  context: context,
  barrierColor: Colors.black54,
  builder: (ctx) => Dialog(
    backgroundColor: Colors.transparent,
    insetPadding: const EdgeInsets.all(20),
    child: Panel(glow: AppColors.goldLight, child: builder(ctx)),
  ),
);

/// Lucky Charm: pick a die to +1. Returns the index.
Future<int?> pickLuckyDie(
  BuildContext context,
  List<int> dice,
  String diceId,
) async {
  final distinct = <int>{};
  final disabled = <int>{};
  for (var i = 0; i < dice.length; i++) {
    if (dice[i] >= 6 || !distinct.add(dice[i])) disabled.add(i);
  }
  return await showPanelDialog<int>(
    context,
    (ctx) => Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          context.l10n.itemLucky,
          style: const TextStyle(
            fontFamily: AppFonts.display,
            fontSize: 22,
            color: AppColors.goldLight,
          ),
        ),
        const SizedBox(height: 12),
        DicePicker(
          values: dice,
          disabled: disabled,
          diceId: diceId,
          onTap: (i) => Navigator.pop(ctx, i),
        ),
        const SizedBox(height: 8),
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: Text(context.l10n.cancel),
        ),
      ],
    ),
  );
}

/// Fate's Edit: choose a die and its new value. Returns (index, value).
Future<(int, int)?> pickFate(
  BuildContext context,
  List<int> rolled,
  String diceId,
) async {
  var index = 0;
  return await showPanelDialog<(int, int)>(
    context,
    (ctx) => StatefulBuilder(
      builder: (ctx, setState) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            context.l10n.fateTitle,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: AppFonts.display,
              fontSize: 20,
              color: AppColors.goldLight,
            ),
          ),
          const SizedBox(height: 10),
          DicePicker(
            values: rolled,
            selected: {index},
            diceId: diceId,
            onTap: (i) => setState(() => index = i),
          ),
          const Divider(color: Colors.white24, height: 24),
          DicePicker(
            values: const [1, 2, 3, 4, 5, 6],
            diceId: diceId,
            size: 40,
            disabled: {rolled[index] - 1},
            onTap: (v) => Navigator.pop(ctx, (index, v + 1)),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(context.l10n.cancel),
          ),
        ],
      ),
    ),
  );
}

/// The opponent offered a double.
class CubeOfferPanel extends StatelessWidget {
  const CubeOfferPanel({
    required this.name,
    required this.value,
    required this.onTake,
    required this.onDrop,
    super.key,
  });
  final String name;

  /// Stakes if accepted; declining loses half of this now.
  final int value;
  final VoidCallback onTake;
  final VoidCallback onDrop;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Center(
      child: Panel(
        glow: AppColors.ruby,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.ivory,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.gold, width: 3),
              ),
              child: Text(
                '$value',
                style: const TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.w900,
                  color: AppColors.night,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              l.doubleOffered(name, value),
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 8),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 300),
              child: Text(
                l.cubeExplain(value, value ~/ 2),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 13,
                  height: 1.5,
                  color: AppColors.muted,
                ),
              ),
            ),
            const SizedBox(height: 14),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                JewelButton(
                  label: l.drop,
                  expand: false,
                  color: AppColors.ruby,
                  onPressed: onDrop,
                ),
                const SizedBox(width: 12),
                JewelButton(
                  label: l.take,
                  expand: false,
                  color: AppColors.emerald,
                  onPressed: onTake,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// End-of-game summary with animated rewards.
class GameOverPanel extends StatefulWidget {
  const GameOverPanel({
    required this.title,
    required this.subtitle,
    required this.won,
    required this.scoreLine,
    required this.rewards,
    required this.actions,
    super.key,
  });

  final String title;
  final String subtitle;
  final bool won;
  final String? scoreLine;
  final Rewards? rewards;
  final List<Widget> actions;

  @override
  State<GameOverPanel> createState() => _GameOverPanelState();
}

class _GameOverPanelState extends State<GameOverPanel>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1600),
  )..forward();

  @override
  void initState() {
    super.initState();
    if ((widget.rewards?.coins ?? 0) > 0) {
      Timer(const Duration(milliseconds: 700), () => Sfx.instance.play('coin'));
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final lang = context.lang;
    final r = widget.rewards;
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: ScaleTransition(
          scale: CurvedAnimation(
            parent: _c,
            curve: const Interval(0, 0.4, curve: Curves.easeOutBack),
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Panel(
              glow: widget.won ? AppColors.goldLight : AppColors.ruby,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  OrnateTitle(widget.title, size: 36),
                  Text(
                    widget.subtitle,
                    style: const TextStyle(
                      fontSize: 18,
                      color: AppColors.ivory,
                    ),
                  ),
                  if (widget.scoreLine != null) ...[
                    const SizedBox(height: 6),
                    Text(
                      widget.scoreLine!,
                      style: const TextStyle(
                        fontSize: 16,
                        color: AppColors.goldLight,
                      ),
                    ),
                  ],
                  if (r != null) ...[
                    const SizedBox(height: 14),
                    AnimatedBuilder(
                      animation: _c,
                      builder: (_, _) {
                        final t = Curves.easeOut.transform(
                          ((_c.value - 0.35) / 0.5).clamp(0, 1),
                        );
                        return Wrap(
                          alignment: WrapAlignment.center,
                          spacing: 10,
                          runSpacing: 8,
                          children: [
                            if (r.coins > 0)
                              CurrencyChip(
                                amount: (r.coins * t).round(),
                                gem: false,
                              ),
                            if (r.gems > 0)
                              CurrencyChip(
                                amount: (r.gems * t).round(),
                                gem: true,
                              ),
                            if (r.xp > 0)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 5,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.black45,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: AppColors.violet),
                                ),
                                child: Text(
                                  l.xpEarned((r.xp * t).round()),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                          ],
                        );
                      },
                    ),
                    for (final lv in r.levelUps)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          l.levelUp(lv),
                          style: const TextStyle(
                            fontFamily: AppFonts.display,
                            fontSize: 22,
                            color: AppColors.turquoiseLight,
                          ),
                        ),
                      ),
                    for (final a in r.achievements)
                      Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.emoji_events,
                              color: AppColors.goldLight,
                              size: 20,
                            ),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                '${l.unlocked}: ${a.name(lang)}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                  const SizedBox(height: 16),
                  for (final a in widget.actions)
                    Padding(padding: const EdgeInsets.only(top: 8), child: a),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Transient message bubbles.
class ToastData {
  ToastData(
    this.text, {
    this.icon = Icons.info_outline,
    this.color = AppColors.goldLight,
  }) : id = _next++;
  static int _next = 0;
  final int id;
  final String text;
  final IconData icon;
  final Color color;
}

class ToastStack extends StatelessWidget {
  const ToastStack({required this.toasts, super.key});
  final List<ToastData> toasts;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final t in toasts)
            TweenAnimationBuilder<double>(
              key: ValueKey(t.id),
              tween: Tween(begin: 0, end: 1),
              duration: const Duration(milliseconds: 260),
              builder: (_, v, child) => Opacity(
                opacity: v,
                child: Transform.translate(
                  offset: Offset(0, (1 - v) * -12),
                  child: child,
                ),
              ),
              child: Container(
                margin: const EdgeInsets.only(top: 6),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: AppColors.ink.withValues(alpha: 0.95),
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: t.color),
                  boxShadow: [
                    BoxShadow(
                      color: t.color.withValues(alpha: 0.3),
                      blurRadius: 12,
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(t.icon, color: t.color, size: 18),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        t.text,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

String sideLabel(Side s) => s == Side.white ? 'white' : 'black';
