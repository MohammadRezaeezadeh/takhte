import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:haftnard/game/audio.dart';
import 'package:haftnard/game/match_controller.dart';
import 'package:haftnard/meta/meta_state.dart';
import 'package:haftnard/ui/app.dart';
import 'package:haftnard/ui/screens/game_screen.dart';
import 'package:haftnard/ui/screens/journey_screen.dart';
import 'package:haftnard/ui/screens/locker_screen.dart';
import 'package:haftnard/ui/screens/play_setup.dart';
import 'package:haftnard/ui/screens/profile_screen.dart';
import 'package:haftnard/ui/screens/settings_screen.dart';
import 'package:haftnard/ui/screens/store_screen.dart';
import 'package:haftnard/ui/screens/tutorial_screen.dart';
import 'package:haftnard/ui/theme.dart';
import 'package:haftnard/ui/widgets/jewel.dart';
import 'package:haftnard/ui/widgets/logo.dart';
import 'package:haftnard/ui/widgets/menu_background.dart';
import 'package:haftnard/ui/widgets/top_bar.dart';

class MainMenuScreen extends ConsumerStatefulWidget {
  const MainMenuScreen({super.key});

  @override
  ConsumerState<MainMenuScreen> createState() => _MainMenuScreenState();
}

class _MainMenuScreenState extends ConsumerState<MainMenuScreen> {
  @override
  void initState() {
    super.initState();
    unawaited(Sfx.instance.setAmbient(on: true));
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => unawaited(_onboarding()),
    );
  }

  /// First launch: offer the interactive tutorial once.
  Future<void> _onboarding() async {
    final meta = ref.read(metaProvider);
    if (meta.settings.tutorialDone ||
        meta.profile.stats.games > 0 ||
        !mounted) {
      return;
    }
    final l = context.l10n;
    final learn = await showDialog<bool>(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        child: Panel(
          glow: AppColors.goldLight,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const HaftNardLogo(size: 0.6),
              const SizedBox(height: 8),
              Text(
                l.welcomeTitle,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: AppFonts.display,
                  fontSize: 24,
                  color: AppColors.goldLight,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                l.welcomeBody,
                textAlign: TextAlign.center,
                style: const TextStyle(height: 1.5),
              ),
              const SizedBox(height: 14),
              JewelButton(
                label: l.tutorial,
                icon: Icons.school,
                color: AppColors.emerald,
                onPressed: () => Navigator.pop(ctx, true),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: Text(l.welcomeSkip),
              ),
            ],
          ),
        ),
      ),
    );
    if (!mounted) return;
    final n = ref.read(metaProvider.notifier);
    if (learn ?? false) {
      await _go(const TutorialScreen());
    } else {
      n.updateSettings(
        ref.read(metaProvider).settings.copyWith(tutorialDone: true),
      );
    }
  }

  Future<void> _go(Widget w) async {
    await Navigator.of(context).push(fadeRoute<void>(w));
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final meta = ref.watch(metaProvider);
    final notifier = ref.read(metaProvider.notifier);
    final active = notifier.data.activeMatch;
    final journey = notifier.data.journey;
    final daily = notifier.canClaimDaily(DateTime.now());
    final wide =
        MediaQuery.sizeOf(context).width > MediaQuery.sizeOf(context).height;
    final buttons = <Widget>[
      if (active != null)
        JewelButton(
          label: l.resumeMatch,
          icon: Icons.play_circle_fill,
          color: AppColors.emerald,
          onPressed: () {
            final MatchSession session;
            try {
              session = MatchSession.fromJson(active);
            } on Object {
              // Damaged or incompatible save: drop it instead of crashing.
              notifier.saveActiveMatch(null);
              setState(() {});
              return;
            }
            unawaited(_go(GameScreen(session: session)));
          },
        ),
      JewelButton(
        label: l.play,
        icon: Icons.casino,
        height: 74,
        fontSize: 28,
        onPressed: () => unawaited(_go(const PlaySetupScreen())),
      ),
      JewelButton(
        label: l.journey,
        subtitle: journey != null ? l.continueRun : null,
        icon: Icons.route,
        color: const Color(0xFF6E1420),
        onPressed: () => unawaited(_go(const JourneyScreen())),
      ),
      Row(
        children: [
          Expanded(
            child: JewelButton(
              label: l.store,
              icon: Icons.storefront,
              color: const Color(0xFF0E5A5A),
              fontSize: 20,
              onPressed: () => unawaited(_go(const StoreScreen())),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: JewelButton(
              label: l.locker,
              icon: Icons.checkroom,
              color: const Color(0xFF3B1C6E),
              fontSize: 20,
              onPressed: () => unawaited(_go(const LockerScreen())),
            ),
          ),
        ],
      ),
      Row(
        children: [
          Expanded(
            child: JewelButton(
              label: l.profile,
              icon: Icons.emoji_events,
              color: const Color(0xFF5A3D22),
              fontSize: 20,
              onPressed: () => unawaited(_go(const ProfileScreen())),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: JewelButton(
              label: l.tutorial,
              icon: Icons.school,
              color: const Color(0xFF1E4A66),
              fontSize: 20,
              badge: meta.settings.tutorialDone ? null : '!',
              onPressed: () => unawaited(_go(const TutorialScreen())),
            ),
          ),
        ],
      ),
      JewelButton(
        label: l.online,
        subtitle: l.comingSoon,
        icon: Icons.public,
        color: const Color(0xFF2A2A3A),
        accent: AppColors.turquoiseLight,
        onPressed: () => _onlineTeaser(context),
      ),
    ];
    return Scaffold(
      body: MenuBackground(
        child: SafeArea(
          child: Column(
            children: [
              ProfileBar(
                leading: Padding(
                  padding: const EdgeInsetsDirectional.only(end: 8),
                  child: JewelIconButton(
                    icon: Icons.settings,
                    tooltip: l.settings,
                    onPressed: () => unawaited(_go(const SettingsScreen())),
                  ),
                ),
              ),
              if (daily)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: _DailyBanner(
                    onClaim: () {
                      final n = notifier.claimDaily(DateTime.now());
                      Sfx.instance.play('coin');
                      ScaffoldMessenger.of(
                        context,
                      ).showSnackBar(SnackBar(content: Text(l.coinsEarned(n))));
                    },
                  ),
                ),
              Expanded(
                child: wide
                    ? Row(
                        children: [
                          const Expanded(child: Center(child: HaftNardLogo())),
                          Expanded(
                            child: Center(
                              child: SingleChildScrollView(
                                padding: const EdgeInsets.all(16),
                                child: ConstrainedBox(
                                  constraints: const BoxConstraints(
                                    maxWidth: 420,
                                  ),
                                  child: Column(children: _spaced(buttons)),
                                ),
                              ),
                            ),
                          ),
                        ],
                      )
                    : SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 8,
                        ),
                        child: Center(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 440),
                            child: Column(
                              children: [
                                const SizedBox(height: 8),
                                const HaftNardLogo(),
                                const SizedBox(height: 22),
                                ..._spaced(buttons),
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

  List<Widget> _spaced(List<Widget> ws) => [
    for (var i = 0; i < ws.length; i++) ...[
      ws[i],
      if (i < ws.length - 1) const SizedBox(height: 12),
    ],
  ];

  void _onlineTeaser(BuildContext context) {
    final l = context.l10n;
    unawaited(
      showDialog<void>(
        context: context,
        builder: (_) => Dialog(
          backgroundColor: Colors.transparent,
          child: Panel(
            glow: AppColors.turquoiseLight,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.public,
                  size: 56,
                  color: AppColors.turquoiseLight,
                ),
                const SizedBox(height: 8),
                OrnateTitle(l.comingSoon, size: 26),
                const SizedBox(height: 8),
                Text(l.onlineTeaser, textAlign: TextAlign.center),
                const SizedBox(height: 16),
                JewelButton(
                  label: l.ok,
                  onPressed: () => Navigator.pop(context),
                  height: 52,
                  fontSize: 18,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DailyBanner extends StatelessWidget {
  const _DailyBanner({required this.onClaim});
  final VoidCallback onClaim;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Panel(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      glow: AppColors.goldLight,
      child: Row(
        children: [
          CustomPaint(
            size: const Size(26, 26),
            painter: CurrencyIconPainter(gem: false),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              l.dailyBonus,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
          JewelButton(
            label: l.claim,
            onPressed: onClaim,
            height: 44,
            fontSize: 16,
            expand: false,
            color: AppColors.emerald,
          ),
        ],
      ),
    );
  }
}
