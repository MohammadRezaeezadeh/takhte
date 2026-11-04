import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:haftnard/core/effects/cards.dart';
import 'package:haftnard/core/rules/record.dart';
import 'package:haftnard/meta/achievements.dart';
import 'package:haftnard/meta/meta_state.dart';
import 'package:haftnard/ui/app.dart';
import 'package:haftnard/ui/screens/codex_screen.dart';
import 'package:haftnard/ui/screens/replay_screen.dart';
import 'package:haftnard/ui/theme.dart';
import 'package:haftnard/ui/widgets/jewel.dart';
import 'package:haftnard/ui/widgets/menu_background.dart';
import 'package:haftnard/ui/widgets/top_bar.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final lang = context.lang;
    final p = ref.watch(metaProvider).profile;
    final st = p.stats;
    final last = ref.read(metaProvider.notifier).data.lastRecord;
    String n(int v) => formatNumber(v, lang);
    final fav = st.favoriteCard;
    final stats = <(String, String)>[
      (l.statGames, n(st.games)),
      (l.statWins, n(st.wins)),
      (
        l.statWinRate,
        st.games == 0 ? l.none : '${n((st.wins * 100 / st.games).round())}%',
      ),
      (l.statMars, n(st.mars)),
      (l.statKupMars, n(st.kupMars)),
      (l.statSevens, n(st.sevens)),
      (l.statHits, n(st.hits)),
      (l.statStreak, n(st.bestStreak)),
      (l.statJourneysWon, n(st.journeysWon)),
      (l.statFavoriteCard, fav == null ? l.none : cardById(fav).name(lang)),
    ];
    return Scaffold(
      body: MenuBackground(
        child: SafeArea(
          child: Column(
            children: [
              ScreenHeader(title: l.profile),
              const ProfileBar(),
              Expanded(
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 640),
                    child: ListView(
                      padding: const EdgeInsets.all(12),
                      children: [
                        Panel(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                l.statistics,
                                style: const TextStyle(
                                  fontFamily: AppFonts.display,
                                  fontSize: 22,
                                  color: AppColors.goldLight,
                                ),
                              ),
                              const SizedBox(height: 8),
                              GridView.count(
                                crossAxisCount: 2,
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                childAspectRatio: 3.2,
                                children: [
                                  for (final (k, v) in stats)
                                    Padding(
                                      padding: const EdgeInsets.all(4),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.black26,
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                        ),
                                        child: Row(
                                          children: [
                                            Expanded(
                                              child: Text(
                                                k,
                                                style: const TextStyle(
                                                  fontSize: 12,
                                                  color: AppColors.muted,
                                                ),
                                                maxLines: 2,
                                              ),
                                            ),
                                            Flexible(
                                              child: Text(
                                                v,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.w800,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              if (last != null) ...[
                                const SizedBox(height: 10),
                                JewelButton(
                                  label: l.replayLast,
                                  icon: Icons.slow_motion_video,
                                  color: AppColors.violet,
                                  height: 50,
                                  fontSize: 17,
                                  onPressed: () {
                                    try {
                                      final rec = GameRecord.fromJson(last);

                                      unawaited(
                                        Navigator.of(context).push(
                                          fadeRoute<void>(
                                            ReplayScreen(record: rec),
                                          ),
                                        ),
                                      );
                                    } on Object {
                                      // Incompatible record from an older version.
                                    }
                                  },
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        JewelButton(
                          label: l.codex,
                          icon: Icons.style,
                          color: const Color(0xFF3B1C6E),
                          height: 52,
                          fontSize: 18,
                          onPressed: () => unawaited(
                            Navigator.of(context)
                                .push(fadeRoute<void>(const CodexScreen())),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Panel(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                '${l.achievements} · ${n(p.achievements.length)}/${n(kAchievements.length)}',
                                style: const TextStyle(
                                  fontFamily: AppFonts.display,
                                  fontSize: 22,
                                  color: AppColors.goldLight,
                                ),
                              ),
                              const SizedBox(height: 8),
                              for (final a in kAchievements)
                                _AchievementRow(
                                  a: a,
                                  unlocked: p.achievements.contains(a.id),
                                ),
                            ],
                          ),
                        ),
                      ],
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

class _AchievementRow extends StatelessWidget {
  const _AchievementRow({required this.a, required this.unlocked});
  final Achievement a;
  final bool unlocked;

  @override
  Widget build(BuildContext context) {
    final lang = context.lang;
    return Semantics(
      label:
          '${a.name(lang)}. ${a.desc(lang)}. ${unlocked ? context.l10n.unlocked : context.l10n.locked}',
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 3),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: unlocked
              ? AppColors.gold.withValues(alpha: 0.12)
              : Colors.black26,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: unlocked
                ? AppColors.gold.withValues(alpha: 0.6)
                : Colors.white10,
          ),
        ),
        child: Row(
          children: [
            Icon(
              unlocked ? Icons.emoji_events : Icons.lock_outline,
              color: unlocked ? AppColors.goldLight : AppColors.muted,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    a.name(lang),
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  Text(
                    a.desc(lang),
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.muted,
                    ),
                  ),
                ],
              ),
            ),
            CurrencyChip(amount: a.gems, gem: true),
          ],
        ),
      ),
    );
  }
}
