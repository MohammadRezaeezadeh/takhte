import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:haftnard/core/ai/personality.dart';
import 'package:haftnard/core/effects/cards.dart';
import 'package:haftnard/core/rng/rng.dart';
import 'package:haftnard/core/rules/match.dart';
import 'package:haftnard/core/rules/types.dart';
import 'package:haftnard/game/audio.dart';
import 'package:haftnard/game/match_controller.dart';
import 'package:haftnard/meta/journey.dart';
import 'package:haftnard/meta/meta_state.dart';
import 'package:haftnard/ui/app.dart';
import 'package:haftnard/ui/game/overlays.dart';
import 'package:haftnard/ui/screens/game_screen.dart';
import 'package:haftnard/ui/theme.dart';
import 'package:haftnard/ui/widgets/avatar.dart';
import 'package:haftnard/ui/widgets/card_art.dart';
import 'package:haftnard/ui/widgets/jewel.dart';
import 'package:haftnard/ui/widgets/menu_background.dart';
import 'package:haftnard/ui/widgets/top_bar.dart';

class JourneyScreen extends ConsumerStatefulWidget {
  const JourneyScreen({super.key});

  @override
  ConsumerState<JourneyScreen> createState() => _JourneyScreenState();
}

class _JourneyScreenState extends ConsumerState<JourneyScreen> {
  JourneyRun? _run;
  int _retry = 0;

  MetaNotifier get _meta => ref.read(metaProvider.notifier);

  @override
  void initState() {
    super.initState();
    final j = _meta.data.journey;
    if (j != null) {
      try {
        _run = JourneyRun.fromJson(j);
      } on Object {
        _run = null;
      }
    }
  }

  void _save() => _meta.saveJourney(_run?.toJson());

  void _start({required bool daily}) {
    final seed = daily
        ? JourneyRun.dailySeed(DateTime.now())
        : (DateTime.now().microsecondsSinceEpoch & 0x7FFFFFFF);
    setState(() => _run = JourneyRun(seed: seed, daily: daily));
    _save();
    Sfx.instance.play('magic');
  }

  String _actName(int act) {
    final l = context.l10n;
    return switch (act) {
      0 => l.actBazaar,
      1 => l.actCaravanserai,
      _ => l.actPalace,
    };
  }

  Future<void> _fight() async {
    final run = _run!;
    final stage = run.current;
    final lang = context.lang;
    final unlocked = ref.read(metaProvider).profile.unlockedCards;
    MatchSession session;
    if (run.activeSession != null) {
      session = MatchSession.fromJson(run.activeSession!);
    } else {
      final p = personalityById(stage.personality);
      session = MatchSession(
        match: MatchState(
          MatchConfig(
            seed: deriveSeed(run.seed, run.stage * 31 + _retry),
            cardPool: run.cardPool(unlocked),
            white: run.playerMods(stage.boss),
            black: stage.boss?.boss ?? const MatchConfig().black,
          ),
        ),
        white: SeatConfig.human(context.l10n.you),
        black: SeatConfig.ai(
          personalityId: p.id,
          difficulty: stage.difficulty,
          name: stage.boss?.name(lang) ?? p.name(lang),
        ),
        origin: 'journey',
      );
      run.activeSession = session.toJson();
      _save();
    }
    final won = await Navigator.of(context).push<bool>(
      fadeRoute(
        GameScreen(
          session: session,
          persistOverride: (s) {
            run.activeSession = s.match.isOver ? null : s.toJson();
            _save();
          },
        ),
      ),
    );
    if (!mounted || won == null) {
      setState(() {});
      return;
    }
    final end = session.match.current.replay();
    final res = end.result;
    final inv = end.inv(Side.white);
    final coins = won
        ? run.winCoins(
            points: res?.points ?? 1,
            hits: inv.hits,
            sevens: inv.sevens,
            mars:
                res?.type == WinType.gammon || res?.type == WinType.backgammon,
          )
        : 0;
    final before = run.stage;
    run.recordMatch(won: won, coinsEarned: coins);
    if (!won && !run.over) _retry++;
    if (run.over) {
      _meta.recordJourney(
        stage: run.stage,
        won: run.won,
        keptCoins: run.keptCoins,
      );
    } else if (run.stage > before) {
      _meta.recordJourney(stage: run.stage, won: false, keptCoins: 0);
    }
    _save();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final run = _run;
    return Scaffold(
      body: MenuBackground(
        child: SafeArea(
          child: Column(
            children: [
              ScreenHeader(title: l.journey),
              const ProfileBar(),
              Expanded(
                child: run == null
                    ? _intro()
                    : run.over
                    ? _summary(run)
                    : run.inShop
                    ? _shop(run)
                    : _map(run),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _intro() {
    final l = context.l10n;
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 460),
          child: Panel(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.route, size: 56, color: AppColors.goldLight),
                OrnateTitle(l.journey),
                const SizedBox(height: 8),
                Text(
                  '${l.act(1)}: ${l.actBazaar} · ${l.act(2)}: ${l.actCaravanserai} · ${l.act(3)}: ${l.actPalace}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.muted),
                ),
                const SizedBox(height: 16),
                JewelButton(
                  label: l.newRun,
                  icon: Icons.play_arrow,
                  color: AppColors.emerald,
                  onPressed: () => _start(daily: false),
                ),
                const SizedBox(height: 10),
                JewelButton(
                  label: l.dailyRun,
                  icon: Icons.today,
                  color: AppColors.violet,
                  onPressed: () => _start(daily: true),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _summary(JourneyRun run) {
    final l = context.l10n;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Panel(
          glow: run.won ? AppColors.goldLight : AppColors.ruby,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              OrnateTitle(run.won ? l.runWon : l.runOver),
              const SizedBox(height: 8),
              Text(l.opponentN(run.stage, JourneyRun.stages)),
              const SizedBox(height: 8),
              Text(
                l.runKept(run.keptCoins),
                style: const TextStyle(
                  color: AppColors.goldLight,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 16),
              JewelButton(
                label: l.newRun,
                color: AppColors.emerald,
                onPressed: () {
                  setState(() => _run = null);
                  _save();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _talismanRow(JourneyRun run) {
    final lang = context.lang;
    if (run.talismans.isEmpty) return const SizedBox.shrink();
    return SizedBox(
      height: 48,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        children: [
          for (final id in run.talismans)
            Tooltip(
              triggerMode: TooltipTriggerMode.tap,
              message:
                  '${talismanById(id).name(lang)}\n${talismanById(id).desc(lang)}',
              child: Container(
                width: 44,
                height: 44,
                margin: const EdgeInsets.only(right: 6),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.ink,
                  border: Border.all(color: AppColors.goldLight),
                ),
                child: CustomPaint(
                  painter: CardGlyphPainter(
                    talismanById(id).glyph,
                    AppColors.goldLight,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _map(JourneyRun run) {
    final l = context.l10n;
    final lang = context.lang;
    final stages = run.map;
    final cur = run.current;
    final p = personalityById(cur.personality);
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Text(
                '${l.runCoins}: ',
                style: const TextStyle(color: AppColors.muted),
              ),
              CurrencyChip(amount: run.coins, gem: false),
              const Spacer(),
              if (run.daily)
                Chip(
                  label: Text(l.dailyRun),
                  backgroundColor: AppColors.violet,
                ),
            ],
          ),
        ),
        _talismanRow(run),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(12),
            children: [
              for (var act = 0; act < 3; act++) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: OrnateTitle(
                    '${l.act(act + 1)} · ${_actName(act)}',
                    size: 20,
                  ),
                ),
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    for (final s in stages.where((s) => s.act == act))
                      _StageNode(
                        stage: s,
                        done: s.index < run.stage,
                        current: s.index == run.stage,
                        lang: lang,
                      ),
                  ],
                ),
              ],
            ],
          ),
        ),
        Panel(
          glow: cur.boss != null ? AppColors.ruby : AppColors.goldLight,
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Avatar(
                style: cur.boss != null ? 'boss' : p.id,
                hue: p.hue,
                seed: p.avatarSeed,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      cur.boss?.name(lang) ?? p.name(lang),
                      style: const TextStyle(
                        fontFamily: AppFonts.display,
                        fontSize: 20,
                        color: AppColors.goldLight,
                      ),
                    ),
                    Text(
                      '${l.opponentN(cur.index + 1, JourneyRun.stages)} · ${difficultyName(context, cur.difficulty)}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.muted,
                      ),
                    ),
                    if (cur.boss != null)
                      Text(
                        l.bossRule(cur.boss!.rule(lang)),
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFFFF8A8A),
                        ),
                      ),
                  ],
                ),
              ),
              JewelButton(
                label: run.activeSession != null ? l.resume : l.fight,
                expand: false,
                color: AppColors.ruby,
                onPressed: () => unawaited(_fight()),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _shop(JourneyRun run) {
    final l = context.l10n;
    final lang = context.lang;
    String title(ShopOffer o) => switch (o.kind) {
      'talisman' => talismanById(o.talisman!).name(lang),
      'banish' => l.removeCard,
      'offer' => l.upgradeOffer,
      _ => l.luckUp,
    };
    String desc(ShopOffer o) => switch (o.kind) {
      'talisman' => talismanById(o.talisman!).desc(lang),
      'banish' => l.removeCardDesc,
      'offer' => l.upgradeOfferDesc,
      _ => l.luckUpDesc,
    };
    int glyph(ShopOffer o) => switch (o.kind) {
      'talisman' => talismanById(o.talisman!).glyph,
      'banish' => 21,
      'offer' => 0,
      _ => 5,
    };
    return Column(
      children: [
        OrnateTitle(l.runShop, size: 26),
        Padding(
          padding: const EdgeInsets.all(8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('${l.runCoins}: '),
              CurrencyChip(amount: run.coins, gem: false),
            ],
          ),
        ),
        _talismanRow(run),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(12),
            children: [
              for (final o in run.shop)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Panel(
                    padding: const EdgeInsets.all(10),
                    child: Row(
                      children: [
                        Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.black38,
                            border: Border.all(color: AppColors.goldLight),
                          ),
                          child: CustomPaint(
                            painter: CardGlyphPainter(
                              glyph(o),
                              AppColors.goldLight,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                title(o),
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 16,
                                ),
                              ),
                              Text(
                                desc(o),
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.muted,
                                ),
                              ),
                            ],
                          ),
                        ),
                        JewelButton(
                          label: formatNumber(o.price, lang),
                          expand: false,
                          height: 48,
                          fontSize: 16,
                          color: run.coins >= o.price
                              ? AppColors.emerald
                              : AppColors.inkLight,
                          onPressed: run.coins < o.price
                              ? null
                              : () => unawaited(_buy(run, o)),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(12),
          child: JewelButton(
            label: l.leaveShop,
            icon: Icons.arrow_forward,
            onPressed: () {
              setState(() => run.inShop = false);
              _save();
            },
          ),
        ),
      ],
    );
  }

  Future<void> _buy(JourneyRun run, ShopOffer o) async {
    String? banish;
    if (o.kind == 'banish') {
      final pool = run.cardPool(ref.read(metaProvider).profile.unlockedCards);
      banish = await showPanelDialog<String>(
        context,
        (ctx) => SizedBox(
          width: 360,
          height: 420,
          child: Column(
            children: [
              Text(
                context.l10n.removeCard,
                style: const TextStyle(
                  fontFamily: AppFonts.display,
                  fontSize: 22,
                  color: AppColors.goldLight,
                ),
              ),
              Expanded(
                child: ListView(
                  children: [
                    for (final id in pool)
                      ListTile(
                        leading: SizedBox(
                          width: 36,
                          height: 36,
                          child: CustomPaint(
                            painter: CardGlyphPainter(
                              cardById(id).glyph,
                              AppColors.rarity(cardById(id).rarity.index),
                            ),
                          ),
                        ),
                        title: Text(cardById(id).name(context.lang)),
                        subtitle: Text(
                          cardById(id).desc(context.lang),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 11),
                        ),
                        onTap: () => Navigator.pop(ctx, id),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
      if (banish == null) return;
    }
    if (run.buy(o, banishCard: banish)) {
      Sfx.instance.play('coin');
      _save();
      setState(() {});
    }
  }
}

class _StageNode extends StatelessWidget {
  const _StageNode({
    required this.stage,
    required this.done,
    required this.current,
    required this.lang,
  });
  final JourneyStage stage;
  final bool done;
  final bool current;
  final String lang;

  @override
  Widget build(BuildContext context) {
    final p = personalityById(stage.personality);
    final boss = stage.boss != null;
    return Opacity(
      opacity: done || current ? 1 : 0.55,
      child: Container(
        width: 96,
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          color: current ? AppColors.lapis : AppColors.ink,
          border: Border.all(
            color: current
                ? AppColors.goldLight
                : (boss ? AppColors.ruby : Colors.white12),
            width: current ? 2.5 : 1,
          ),
          boxShadow: current
              ? [
                  BoxShadow(
                    color: AppColors.goldLight.withValues(alpha: 0.4),
                    blurRadius: 14,
                  ),
                ]
              : null,
        ),
        child: Column(
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                Avatar(
                  style: boss ? 'boss' : p.id,
                  hue: p.hue,
                  seed: p.avatarSeed,
                  size: boss ? 58 : 50,
                ),
                if (done)
                  const Icon(
                    Icons.check_circle,
                    color: AppColors.emerald,
                    size: 30,
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              stage.boss?.name(lang) ?? p.name(lang),
              maxLines: 2,
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11,
                color: boss ? const Color(0xFFFF8A8A) : AppColors.ivory,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
