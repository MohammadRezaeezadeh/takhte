import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:haftnard/core/rules/match.dart';
import 'package:haftnard/game/match_controller.dart';
import 'package:haftnard/meta/meta_state.dart';
import 'package:haftnard/ui/app.dart';
import 'package:haftnard/ui/screens/game_screen.dart';
import 'package:haftnard/ui/theme.dart';
import 'package:haftnard/ui/tutorial.dart';
import 'package:haftnard/ui/widgets/jewel.dart';
import 'package:haftnard/ui/widgets/menu_background.dart';
import 'package:haftnard/ui/widgets/top_bar.dart';

/// Chooser between the two interactive tutorials.
class TutorialScreen extends ConsumerWidget {
  const TutorialScreen({super.key});

  Future<void> _open(
    BuildContext context,
    WidgetRef ref,
    List<TutorialStep> steps, {
    required bool sevens,
  }) async {
    final session = MatchSession(
      match: MatchState(const MatchConfig()),
      white: SeatConfig.human(context.l10n.you),
      black: SeatConfig.human(context.l10n.player2),
      origin: 'tutorial',
    );
    await Navigator.of(context)
        .push(fadeRoute<void>(GameScreen(session: session, tutorial: steps)));
    final n = ref.read(metaProvider.notifier);
    final s = ref.read(metaProvider).settings;
    n.updateSettings(
      sevens
          ? s.copyWith(sevenTutorialDone: true)
          : s.copyWith(tutorialDone: true),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final s = ref.watch(metaProvider).settings;
    return Scaffold(
      body: MenuBackground(
        child: SafeArea(
          child: Column(
            children: [
              ScreenHeader(title: l.tutorial),
              Expanded(
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 440),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          JewelButton(
                            label: l.tutorialBasics,
                            icon: Icons.school,
                            badge: s.tutorialDone ? null : '!',
                            onPressed: () => unawaited(
                              _open(
                                context,
                                ref,
                                kBasicsTutorial,
                                sevens: false,
                              ),
                            ),
                          ),
                          const SizedBox(height: 14),
                          JewelButton(
                            label: l.tutorialSevens,
                            icon: Icons.auto_awesome,
                            color: AppColors.violet,
                            badge: s.sevenTutorialDone ? null : '!',
                            onPressed: () => unawaited(
                              _open(context, ref, kSevenTutorial, sevens: true),
                            ),
                          ),
                        ],
                      ),
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
