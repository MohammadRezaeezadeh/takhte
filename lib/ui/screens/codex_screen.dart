import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:haftnard/core/effects/cards.dart';
import 'package:haftnard/meta/meta_state.dart';
import 'package:haftnard/meta/profile.dart';
import 'package:haftnard/ui/app.dart';
import 'package:haftnard/ui/theme.dart';
import 'package:haftnard/ui/widgets/card_art.dart';
import 'package:haftnard/ui/widgets/menu_background.dart';
import 'package:haftnard/ui/widgets/top_bar.dart';

/// Every power card, with unlock levels and how often you've taken it.
class CodexScreen extends ConsumerWidget {
  const CodexScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final lang = context.lang;
    final p = ref.watch(metaProvider).profile;
    final unlocked = p.unlockedCards.toSet();
    final width = MediaQuery.sizeOf(context).width;
    final cols = (width / 120).floor().clamp(3, 8);
    final cards = [...kCards]
      ..sort((a, b) {
        final la = kCardUnlockLevel[a.id] ?? 0;
        final lb = kCardUnlockLevel[b.id] ?? 0;
        return la != lb
            ? la.compareTo(lb)
            : a.rarity.index.compareTo(b.rarity.index);
      });
    return Scaffold(
      body: MenuBackground(
        child: SafeArea(
          child: Column(
            children: [
              ScreenHeader(title: l.codex),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  l.codexProgress(unlocked.length, kCards.length),
                  style: const TextStyle(color: AppColors.muted),
                ),
              ),
              Expanded(
                child: GridView.builder(
                  padding: const EdgeInsets.all(12),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: cols,
                    childAspectRatio: 1 / 1.45,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                  ),
                  itemCount: cards.length,
                  itemBuilder: (context, i) {
                    final c = cards[i];
                    final open = unlocked.contains(c.id);
                    final taken = p.stats.cardCounts[c.id] ?? 0;
                    return LayoutBuilder(
                      builder: (context, box) => GestureDetector(
                        onTap: open
                            ? () => _show(context, c, lang, taken)
                            : null,
                        child: Semantics(
                          button: open,
                          label: open
                              ? c.name(lang)
                              : l.level(kCardUnlockLevel[c.id] ?? 1),
                          child: Stack(
                            children: [
                              CardFace(
                                card: c,
                                lang: lang,
                                width: box.maxWidth,
                                compact: true,
                              ),
                              if (!open)
                                Positioned.fill(
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: Colors.black.withValues(
                                        alpha: 0.72,
                                      ),
                                      borderRadius: BorderRadius.circular(
                                        box.maxWidth * 0.08,
                                      ),
                                    ),
                                    alignment: Alignment.center,
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(
                                          Icons.lock,
                                          color: AppColors.muted,
                                        ),
                                        Text(
                                          l.level(kCardUnlockLevel[c.id] ?? 1),
                                          style: const TextStyle(fontSize: 12),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              if (open && taken > 0)
                                PositionedDirectional(
                                  top: 4,
                                  end: 4,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 1,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.emerald,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      '×${formatTaken(taken, lang)}',
                                      style: const TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String formatTaken(int n, String lang) {
    const fa = '۰۱۲۳۴۵۶۷۸۹';
    final s = '$n';
    return lang == 'fa' ? s.split('').map((d) => fa[int.parse(d)]).join() : s;
  }

  void _show(BuildContext context, CardDef c, String lang, int taken) {
    unawaited(_open(context, c, lang));
  }

  Future<void> _open(BuildContext context, CardDef c, String lang) {
    return showDialog<void>(
      context: context,
      builder: (ctx) => GestureDetector(
        onTap: () => Navigator.pop(ctx),
        child: Center(
          child: CardFace(card: c, lang: lang, width: 240),
        ),
      ),
    );
  }
}
