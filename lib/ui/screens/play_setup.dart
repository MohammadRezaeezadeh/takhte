import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:haftnard/core/ai/personality.dart';
import 'package:haftnard/core/rules/match.dart';
import 'package:haftnard/core/rules/seven_odds.dart';
import 'package:haftnard/core/rules/state.dart';
import 'package:haftnard/game/match_controller.dart';
import 'package:haftnard/meta/meta_state.dart';
import 'package:haftnard/ui/app.dart';
import 'package:haftnard/ui/screens/game_screen.dart';
import 'package:haftnard/ui/screens/lan_screen.dart';
import 'package:haftnard/ui/theme.dart';
import 'package:haftnard/ui/widgets/jewel.dart';
import 'package:haftnard/ui/widgets/menu_background.dart';
import 'package:haftnard/ui/widgets/top_bar.dart';

class PlaySetupScreen extends ConsumerStatefulWidget {
  const PlaySetupScreen({super.key, this.lan = false});

  /// Open with "Friend (Wi-Fi)" already chosen (from the main menu).
  final bool lan;

  @override
  ConsumerState<PlaySetupScreen> createState() => _PlaySetupScreenState();
}

class _PlaySetupScreenState extends ConsumerState<PlaySetupScreen> {
  GameMode _mode = GameMode.seven;
  bool _passPlay = false;
  late bool _lan = widget.lan;
  SevenLevel _seven = SevenLevel.normal;
  final math.Random _rng = math.Random();
  Difficulty _difficulty = Difficulty.medium;
  int _length = 1;
  bool _cube = false;

  String _diffLabel(Difficulty d) {
    final l = context.l10n;
    return switch (d) {
      Difficulty.beginner => l.diffBeginner,
      Difficulty.easy => l.diffEasy,
      Difficulty.medium => l.diffMedium,
      Difficulty.hard => l.diffHard,
      Difficulty.master => l.diffMaster,
    };
  }

  MatchConfig _config(int seed) => MatchConfig(
    mode: _mode,
    p7: _seven.base,
    length: _length,
    cubeEnabled: _cube,
    seed: seed,
    cardPool: ref.read(metaProvider).profile.unlockedCards,
  );

  void _lanGo({required bool host}) {
    final seed = DateTime.now().microsecondsSinceEpoch & 0x7FFFFFFF;
    unawaited(
      Navigator.of(context).push(
        fadeRoute<void>(
          host ? LanScreen.host(config: _config(seed)) : const LanScreen.join(),
        ),
      ),
    );
  }

  void _start() {
    final l = context.l10n;
    final seed = DateTime.now().microsecondsSinceEpoch & 0x7FFFFFFF;
    // The computer opponent is a surprise: a random personality each game.
    final p = kPersonalities[_rng.nextInt(kPersonalities.length)];
    final session = MatchSession(
      match: MatchState(_config(seed)),
      white: SeatConfig.human(_passPlay ? l.player1 : l.you),
      black: _passPlay
          ? SeatConfig.human(l.player2)
          : SeatConfig.ai(
              personalityId: p.id,
              difficulty: _difficulty,
              name: p.name(context.lang),
            ),
      origin: _passPlay ? 'passplay' : 'quick',
    );
    unawaited(
      Navigator.of(context)
          .pushReplacement(fadeRoute<void>(GameScreen(session: session))),
    );
  }

  Widget _chip(
    String label, {
    required bool selected,
    required VoidCallback onTap,
    Key? key,
  }) => Padding(
    key: key,
    padding: const EdgeInsets.all(4),
    child: ChoiceChip(
      label: Text(
        label,
        style: TextStyle(
          color: selected ? AppColors.night : AppColors.ivory,
          fontWeight: FontWeight.w700,
        ),
      ),
      selected: selected,
      onSelected: (_) => onTap(),
      selectedColor: AppColors.goldLight,
      backgroundColor: AppColors.inkLight,
      side: BorderSide(color: AppColors.gold.withValues(alpha: 0.5)),
      showCheckmark: false,
      materialTapTargetSize: MaterialTapTargetSize.padded,
    ),
  );

  Widget _section(String title, Widget child) => Padding(
    padding: const EdgeInsets.only(bottom: 14),
    child: Panel(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontFamily: AppFonts.display,
              fontSize: 20,
              color: AppColors.goldLight,
            ),
          ),
          const SizedBox(height: 6),
          child,
        ],
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Scaffold(
      body: MenuBackground(
        child: SafeArea(
          child: Column(
            children: [
              ScreenHeader(title: l.play),
              Expanded(
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 560),
                    child: ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        _section(
                          l.chooseMode,
                          Row(
                            children: [
                              Expanded(
                                child: _ModeTile(
                                  title: l.modeSeven,
                                  desc: l.modeSevenDesc,
                                  selected: _mode == GameMode.seven,
                                  seven: true,
                                  onTap: () =>
                                      setState(() => _mode = GameMode.seven),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: _ModeTile(
                                  title: l.modeClassic,
                                  desc: l.modeClassicDesc,
                                  selected: _mode == GameMode.classic,
                                  onTap: () =>
                                      setState(() => _mode = GameMode.classic),
                                ),
                              ),
                            ],
                          ),
                        ),
                        _section(
                          l.chooseOpponent,
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              SizedBox(
                                height: 128,
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: _OpponentTile(
                                        key: const ValueKey('ai-tile'),
                                        name: l.computerOpponent,
                                        tagline: l.computerOpponentDesc,
                                        avatar: const Icon(
                                          Icons.casino,
                                          size: 52,
                                          color: AppColors.goldLight,
                                        ),
                                        selected: !_passPlay && !_lan,
                                        onTap: () => setState(() {
                                          _passPlay = false;
                                          _lan = false;
                                        }),
                                      ),
                                    ),
                                    Expanded(
                                      child: _OpponentTile(
                                        name: l.modePassPlay,
                                        tagline: l.modePassPlayDesc,
                                        avatar: const Icon(
                                          Icons.people,
                                          size: 52,
                                          color: AppColors.goldLight,
                                        ),
                                        selected: _passPlay,
                                        onTap: () => setState(() {
                                          _passPlay = true;
                                          _lan = false;
                                        }),
                                      ),
                                    ),
                                    Expanded(
                                      child: _OpponentTile(
                                        key: const ValueKey('lan-tile'),
                                        name: l.lanPlay,
                                        tagline: l.lanPlayDesc,
                                        avatar: const Icon(
                                          Icons.wifi,
                                          size: 52,
                                          color: AppColors.goldLight,
                                        ),
                                        selected: _lan,
                                        onTap: () => setState(() {
                                          _lan = true;
                                          _passPlay = false;
                                        }),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (!_passPlay && !_lan) ...[
                                const SizedBox(height: 8),
                                Text(
                                  l.difficulty,
                                  style: const TextStyle(
                                    color: AppColors.muted,
                                  ),
                                ),
                                Wrap(
                                  children: [
                                    for (final d in Difficulty.values)
                                      _chip(
                                        _diffLabel(d),
                                        selected: _difficulty == d,
                                        onTap: () =>
                                            setState(() => _difficulty = d),
                                      ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),
                        if (_mode == GameMode.seven)
                          _section(
                            l.sevenOdds,
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Wrap(
                                  children: [
                                    for (final lv in SevenLevel.values)
                                      _chip(
                                        switch (lv) {
                                          SevenLevel.low => l.sevenLow,
                                          SevenLevel.normal => l.sevenNormal,
                                          SevenLevel.high => l.sevenHigh,
                                          SevenLevel.veryHigh =>
                                            l.sevenVeryHigh,
                                        },
                                        key: ValueKey('seven-${lv.name}'),
                                        selected: _seven == lv,
                                        onTap: () =>
                                            setState(() => _seven = lv),
                                      ),
                                  ],
                                ),
                                Text(
                                  l.sevenOddsDesc,
                                  style: const TextStyle(
                                    color: AppColors.muted,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        _section(
                          l.matchLength,
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Wrap(
                                children: [
                                  for (final n in [1, 3, 5, 7])
                                    _chip(
                                      l.pointsN(n),
                                      selected: _length == n,
                                      onTap: () => setState(() => _length = n),
                                    ),
                                ],
                              ),
                              SwitchListTile(
                                contentPadding: EdgeInsets.zero,
                                value: _cube,
                                onChanged: _length > 1
                                    ? (v) => setState(() => _cube = v)
                                    : null,
                                title: Text(l.doublingCube),
                                subtitle: Text(
                                  l.doublingCubeDesc,
                                  style: const TextStyle(
                                    color: AppColors.muted,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (_lan) ...[
                          JewelButton(
                            key: const ValueKey('lan-host-button'),
                            label: l.lanHost,
                            icon: Icons.wifi_tethering,
                            color: AppColors.emerald,
                            onPressed: () => _lanGo(host: true),
                          ),
                          const SizedBox(height: 10),
                          JewelButton(
                            key: const ValueKey('lan-join-button'),
                            label: l.lanJoin,
                            icon: Icons.login,
                            onPressed: () => _lanGo(host: false),
                          ),
                        ] else
                          JewelButton(
                            key: const ValueKey('start-button'),
                            label: l.start,
                            icon: Icons.play_arrow,
                            color: AppColors.emerald,
                            height: 70,
                            fontSize: 28,
                            onPressed: _start,
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

class _ModeTile extends StatelessWidget {
  const _ModeTile({
    required this.title,
    required this.desc,
    required this.selected,
    required this.onTap,
    this.seven = false,
  });
  final String title;
  final String desc;
  final bool selected;
  final bool seven;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      selected: selected,
      button: true,
      label: title,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(12),
          constraints: const BoxConstraints(minHeight: 110),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            gradient: LinearGradient(
              colors: seven
                  ? [const Color(0xFF3B1C6E), const Color(0xFF1B2A6B)]
                  : [const Color(0xFF3A2416), const Color(0xFF1E140C)],
            ),
            border: Border.all(
              color: selected ? AppColors.goldLight : Colors.white12,
              width: selected ? 2.5 : 1,
            ),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: AppColors.goldLight.withValues(alpha: 0.3),
                      blurRadius: 14,
                    ),
                  ]
                : null,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.fade,
                      softWrap: false,
                      style: const TextStyle(
                        fontFamily: AppFonts.display,
                        fontSize: 22,
                        color: AppColors.goldLight,
                      ),
                    ),
                  ),
                  if (selected)
                    const Icon(
                      Icons.check_circle,
                      color: AppColors.goldLight,
                      size: 20,
                    ),
                ],
              ),
              const SizedBox(height: 4),
              Text(desc, style: const TextStyle(fontSize: 12.5, height: 1.4)),
            ],
          ),
        ),
      ),
    );
  }
}

class _OpponentTile extends StatelessWidget {
  const _OpponentTile({
    required this.name,
    required this.tagline,
    required this.avatar,
    required this.selected,
    required this.onTap,
    super.key,
  });
  final String name;
  final String tagline;
  final Widget avatar;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: name,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 112,
          margin: const EdgeInsetsDirectional.only(end: 8),
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: selected ? AppColors.lapis : AppColors.ink,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected ? AppColors.goldLight : Colors.white12,
              width: selected ? 2 : 1,
            ),
          ),
          child: Column(
            children: [
              SizedBox(height: 58, child: Center(child: avatar)),
              const SizedBox(height: 4),
              Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 12.5,
                ),
              ),
              Text(
                tagline,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 10,
                  color: AppColors.muted,
                  height: 1.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
