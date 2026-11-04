import 'dart:async';
import 'dart:math' as math;

import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:haftnard/core/ai/personality.dart';
import 'package:haftnard/core/effects/card_logic.dart';
import 'package:haftnard/core/effects/cards.dart';
import 'package:haftnard/core/rules/actions.dart';
import 'package:haftnard/core/rules/engine.dart';
import 'package:haftnard/core/rules/events.dart';
import 'package:haftnard/core/rules/match.dart';
import 'package:haftnard/core/rules/record.dart';
import 'package:haftnard/core/rules/state.dart';
import 'package:haftnard/core/rules/types.dart';
import 'package:haftnard/game/audio.dart';
import 'package:haftnard/game/match_controller.dart';
import 'package:haftnard/game/scene/board_game.dart';
import 'package:haftnard/meta/cosmetics.dart';
import 'package:haftnard/meta/meta_state.dart';
import 'package:haftnard/ui/app.dart';
import 'package:haftnard/ui/game/hud.dart';
import 'package:haftnard/ui/game/overlays.dart';
import 'package:haftnard/ui/game/seven_overlay.dart';
import 'package:haftnard/ui/screens/replay_screen.dart';
import 'package:haftnard/ui/theme.dart';
import 'package:haftnard/ui/tips.dart';
import 'package:haftnard/ui/tutorial.dart';
import 'package:haftnard/ui/widgets/jewel.dart';
import 'package:haftnard/ui/widgets/previews.dart';

class GameScreen extends ConsumerStatefulWidget {
  const GameScreen({
    required this.session,
    super.key,
    this.persistOverride,
    this.sceneOverride,
    this.tutorial,
  });

  final MatchSession session;

  /// Journey mode stores the session inside the run instead of `activeMatch`.
  final void Function(MatchSession s)? persistOverride;

  /// Locker previews / tests.
  final SceneConfig? sceneOverride;

  /// Interactive lessons played on this board.
  final List<TutorialStep>? tutorial;

  @override
  ConsumerState<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends ConsumerState<GameScreen> {
  late final MatchController ctrl;
  late final BoardGame game;
  late final StreamSubscription<List<GameEvent>> _sub;
  Rewards? _rewards;
  bool _showGameOver = false;
  final List<ToastData> _toasts = [];
  (String, String)? _reveal;
  Timer? _revealTimer;
  final List<int> _chosen = [];
  int _step = 0;
  bool _stepDone = false;
  String? _tipText;
  String get _tip => _tipText ??= randomTip(context.lang);
  final Map<Side, String> _emotes = {};
  final Map<Side, Timer> _emoteTimers = {};
  final math.Random _emoteRng = math.Random();

  MetaNotifier get _meta => ref.read(metaProvider.notifier);
  MatchSession get session => widget.session;

  @override
  void initState() {
    super.initState();
    final m = ref.read(metaProvider);
    final st = m.settings;
    final eq = m.profile.equipped;
    ctrl = MatchController(
      session,
      initialState: widget.tutorial?.first.build(),
      autoMove: widget.tutorial == null && st.autoMove,
      pacing: Duration(milliseconds: (440 / st.animSpeed).round()),
      onPersist: _persist,
      onGameFinished: _onGameFinished,
    );
    game = BoardGame(
      controller: ctrl,
      config:
          widget.sceneOverride ??
          SceneConfig(
            boardId: eq[ItemType.board]!,
            envId: eq[ItemType.environment]!,
            checkerId: eq[ItemType.checker]!,
            diceId: eq[ItemType.dice]!,
            victoryId: eq[ItemType.victory]!,
            homeOnRight: st.homeOnRight,
            animSpeed: st.animSpeed,
            reducedMotion: st.reducedMotion,
            colorblind: st.colorblind,
            highContrast: st.highContrast,
            persianDigits:
                st.language == 'fa' ||
                (st.language == 'system' &&
                    WidgetsBinding
                            .instance
                            .platformDispatcher
                            .locale
                            .languageCode ==
                        'fa'),
          ),
      onTargetTap: _onTargetTap,
    );
    ctrl
      ..presenter = game
      ..addListener(_onCtrl);
    _sub = ctrl.events.listen(_onEvents);
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => unawaited(ctrl.begin()),
    );
    unawaited(Sfx.instance.setAmbient(on: true, track: 'ambient_game'));
    if (ctrl.state.isOver) _showGameOver = true;
  }

  void _emote(Side side, String itemId) {
    final item = itemById(itemId);
    if (item == null) return;
    _emoteTimers[side]?.cancel();
    setState(() => _emotes[side] = item.name(context.lang));
    Sfx.instance.play('pop', volume: 0.6);
    _emoteTimers[side] = Timer(const Duration(milliseconds: 2200), () {
      if (mounted) setState(() => _emotes.remove(side));
    });
  }

  /// AI personalities occasionally react to big moments.
  void _aiReact(Side ai, String itemId, {double chance = 0.55}) {
    if (ctrl.isHuman(ai) || session.origin == 'tutorial') return;
    if (_emoteRng.nextDouble() > chance) return;
    Timer(Duration(milliseconds: 500 + _emoteRng.nextInt(500)), () {
      if (mounted) _emote(ai, itemId);
    });
  }

  Future<void> _pickEmote() async {
    final p = ref.read(metaProvider).profile;
    final owned = itemsOfType(ItemType.emote)
        .where((i) => p.owned.contains(i.id))
        .toList();
    final side = session.isPassAndPlay ? ctrl.state.current : ctrl.localSide;
    final id = await showPanelDialog<String>(
      context,
      (ctx) => Wrap(
        alignment: WrapAlignment.center,
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final e in owned)
            GestureDetector(
              onTap: () => Navigator.pop(ctx, e.id),
              child: EmoteBubble(text: e.name(context.lang)),
            ),
        ],
      ),
    );
    if (id != null && mounted) _emote(side, id);
  }

  @override
  void dispose() {
    for (final t in _emoteTimers.values) {
      t.cancel();
    }
    _revealTimer?.cancel();
    unawaited(Sfx.instance.setAmbient(on: true, track: 'ambient'));
    unawaited(_sub.cancel());
    ctrl
      ..removeListener(_onCtrl)
      ..dispose();
    super.dispose();
  }

  void _persist(MatchController c) {
    if (session.origin == 'tutorial') return;
    if (widget.persistOverride != null) {
      widget.persistOverride!(session);
      return;
    }
    _meta.saveActiveMatch(c.match.isOver ? null : session.toJson());
  }

  void _onGameFinished(MatchController c, GameRecord finished, GameState end) {
    _meta.saveLastRecord(finished.toJson());
    final humans = {
      for (final s in Side.values)
        if (c.isHuman(s)) s,
    };
    final aiSeat = session.white.ai
        ? session.white
        : (session.black.ai ? session.black : null);
    final winner = c.match.winner;
    final rewards = _meta.recordGame(
      GameOutcome(
        end: end,
        humanSides: humans,
        difficulty: aiSeat?.difficulty?.name ?? 'human',
        passAndPlay: session.isPassAndPlay,
        matchOver: c.match.isOver,
        matchWon: winner != null && humans.contains(winner),
        matchLength: c.match.config.length,
        journey: session.origin == 'journey',
      ),
    );
    setState(() => _rewards = rewards);
    Timer(const Duration(milliseconds: 1300), () {
      if (mounted) setState(() => _showGameOver = true);
    });
  }

  String _name(Side s) {
    final seat = session.seat(s);
    if (seat.name.isNotEmpty) return seat.name;
    return seat.personality?.name(context.lang) ?? context.l10n.you;
  }

  void _toast(
    String text, {
    IconData icon = Icons.info_outline,
    Color color = AppColors.goldLight,
    int ms = 2200,
  }) {
    final t = ToastData(text, icon: icon, color: color);
    setState(() => _toasts.add(t));
    Timer(Duration(milliseconds: ms), () {
      if (mounted) setState(() => _toasts.remove(t));
    });
  }

  String _itemName(String item) {
    final l = context.l10n;
    return switch (item) {
      'phoenix' => l.itemPhoenix,
      'ghost' => l.itemGhost,
      'lucky' => l.itemLucky,
      _ => l.itemReroll,
    };
  }

  void _onEvents(List<GameEvent> events) {
    if (!mounted) return;
    final l = context.l10n;
    final lang = context.lang;
    for (final e in events) {
      switch (e) {
        case OpeningRolled(:final tie):
          if (tie) {
            _toast(l.openingTie, icon: Icons.casino);
          }
        case TurnStarted(:final side, :final extra):
          if (extra) {
            _toast(l.extraTurn, icon: Icons.hourglass_bottom);
          }
          if (ctrl.state.turnNumber == 1) {
            _toast(l.startsFirst(_name(side)), icon: Icons.flag);
          }
        case NoLegalMoves(:final side):
          if (ctrl.isHuman(side)) {
            _toast(
              l.noMoves,
              icon: Icons.block,
              color: AppColors.ruby,
              ms: 2600,
            );
          }
        case TurnSkipped(:final side):
          _toast(
            l.turnSkipped(_name(side)),
            icon: Icons.skip_next,
            color: AppColors.ruby,
          );
        case CoinFlipped(:final owner, :final ownerWins):
          final mine = ctrl.isHuman(owner);
          _toast(
            ownerWins == mine ? l.coinHeads : l.coinTails,
            icon: Icons.monetization_on,
          );
          if (mine && ownerWins && !session.isPassAndPlay) {
            _meta.noteEvent(coinWin: true);
          }
        case MineTriggered(:final victim):
          _toast(
            l.mineBoom,
            icon: Icons.local_fire_department,
            color: AppColors.ruby,
          );
          if (ctrl.isHuman(victim.opponent) && !session.isPassAndPlay) {
            _meta.noteEvent(mine: true);
          }
        case PhoenixRose(:final side):
          _toast(
            l.phoenixRises,
            icon: Icons.whatshot,
            color: const Color(0xFFFF9E3D),
          );
          if (ctrl.isHuman(side)) _meta.noteEvent(phoenix: true);
        case ItemStolen(:final item):
          _toast(
            l.stolen(_itemName(item)),
            icon: Icons.back_hand,
            color: AppColors.violet,
          );
        case CardFizzled(:final cardId):
          _toast(l.fizzled(cardById(cardId).name(lang)), icon: Icons.blur_off);
        case DiceRolled(:final bonus):
          if (bonus) {
            _toast(
              l.bonusRoll,
              icon: Icons.casino,
              color: AppColors.turquoiseLight,
            );
          }
        case QuicksandGripped():
          _toast(l.gripped, icon: Icons.waves, color: const Color(0xFF8C6A48));
        case SevenRolled(:final side):
          _aiReact(side, 'emo_seven', chance: 0.7);
          _aiReact(side.opponent, 'emo_wow', chance: 0.4);
        case CheckerHit(:final victim):
          _aiReact(victim, 'emo_oops', chance: 0.35);
          _aiReact(victim.opponent, 'emo_bravo', chance: 0.25);
        case GameEnded(:final winner):
          _aiReact(winner.opponent, 'emo_wellplayed', chance: 0.8);
        case CardPicked(:final side, :final cardId):
          if (!ctrl.isHuman(side) || session.isPassAndPlay) {
            if (!ctrl.isHuman(side)) {
              _revealTimer?.cancel();
              setState(() => _reveal = (_name(side), cardId));
              _revealTimer = Timer(const Duration(milliseconds: 2800), () {
                if (mounted) setState(() => _reveal = null);
              });
            }
          }
        default:
          break;
      }
    }
  }

  void _onCtrl() {
    if (!mounted) return;
    final tut = widget.tutorial;
    if (tut != null &&
        !_stepDone &&
        (tut[_step].done?.call(ctrl.state) ?? false)) {
      _stepDone = true;
      Sfx.instance.play('card_pick');
    }
    _updateTargeting();
    setState(() {});
  }

  // --- Targeting --------------------------------------------------------------

  List<List<int>> _allTargets() {
    final s = ctrl.state;
    return CardLogic.allTargets(Tx(s), s.current, s.pendingCard!);
  }

  bool _unordered() =>
      isUnorderedTarget(cardById(ctrl.state.pendingCard!).target);

  bool _matches(List<int> combo, List<int> chosen, {required bool prefixOnly}) {
    if (_unordered()) {
      final rest = List<int>.of(combo);
      for (final c in chosen) {
        if (!rest.remove(c)) return false;
      }
      return prefixOnly || rest.isEmpty;
    }
    if (chosen.length > combo.length) return false;
    for (var i = 0; i < chosen.length; i++) {
      if (combo[i] != chosen[i]) return false;
    }
    return prefixOnly || chosen.length == combo.length;
  }

  void _updateTargeting() {
    final s = ctrl.state;
    if (s.phase != Phase.cardTarget || !ctrl.waitingForHuman) {
      _chosen.clear();
      game
        ..targetable = {}
        ..targetChosen = [];
      return;
    }
    final all = _allTargets();
    final next = <int>{};
    for (final combo in all) {
      if (!_matches(combo, _chosen, prefixOnly: true)) continue;
      if (_unordered()) {
        final rest = List<int>.of(combo);
        _chosen.forEach(rest.remove);
        next.addAll(rest);
      } else if (combo.length > _chosen.length) {
        next.add(combo[_chosen.length]);
      }
    }
    game
      ..targetable = next
      ..targetChosen = List.of(_chosen);
  }

  void _onTargetTap(int abs) {
    _chosen.add(abs);
    final all = _allTargets();
    final complete = all.any(
      (c) =>
          c.length == _chosen.length && _matches(c, _chosen, prefixOnly: false),
    );
    if (complete) {
      final pts = List<int>.of(_chosen);
      _chosen.clear();
      game
        ..targetable = {}
        ..targetChosen = [];
      unawaited(ctrl.act(ChooseTargets(pts)));
    } else {
      _updateTargeting();
      setState(() {});
    }
  }

  String _targetPrompt() {
    final l = context.l10n;
    final card = cardById(ctrl.state.pendingCard!);
    return switch (card.target) {
      TargetKind.enemyCheckers2 => l.targetEnemy2,
      TargetKind.ownChecker => l.targetOwn,
      TargetKind.ownBlot => l.targetOwnBlot,
      TargetKind.emptyPoint => l.targetEmpty,
      TargetKind.enemyOrEmpty => l.targetPoint,
      TargetKind.teleport =>
        _chosen.isEmpty ? l.targetTeleportFrom : l.targetTeleportTo,
      TargetKind.ownBlot2 => l.targetOwnBlot2,
      TargetKind.emptyPoint2 => l.targetEmpty2,
      TargetKind.enemyOrEmpty2 => l.targetPoint2,
      TargetKind.enemyChecker => l.targetEnemy1,
      TargetKind.enemyBlot => l.targetEnemyBlot,
      TargetKind.ownPoint2 => l.targetOwn2,
      TargetKind.sprint => l.targetOwn,
      TargetKind.none => '',
    };
  }

  // --- Menus --------------------------------------------------------------------

  Future<void> _pause() async {
    final l = context.l10n;
    final res = await showPanelDialog<String>(
      context,
      (ctx) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          OrnateTitle(l.paused),
          const SizedBox(height: 12),
          JewelButton(
            label: l.resume,
            icon: Icons.play_arrow,
            color: AppColors.emerald,
            onPressed: () => Navigator.pop(ctx),
          ),
          const SizedBox(height: 10),
          if (!ctrl.state.isOver)
            JewelButton(
              label: l.resign,
              icon: Icons.flag,
              color: AppColors.ruby,
              onPressed: () => Navigator.pop(ctx, 'resign'),
            ),
          const SizedBox(height: 10),
          JewelButton(
            label: l.mainMenu,
            icon: Icons.home,
            onPressed: () => Navigator.pop(ctx, 'menu'),
          ),
        ],
      ),
    );
    if (!mounted) return;
    if (res == 'menu') {
      Navigator.of(context).pop();
    } else if (res == 'resign') {
      final side = session.isPassAndPlay ? ctrl.state.current : ctrl.localSide;
      await ctrl.resign(side);
    }
  }

  Future<void> _lucky() async {
    final s = ctrl.state;
    final i = await pickLuckyDie(
      context,
      s.dice,
      ref.read(metaProvider).profile.equipped[ItemType.dice]!,
    );
    if (i != null) await ctrl.act(UseLucky(i));
  }

  Future<void> _fate() async {
    final s = ctrl.state;
    final r = await pickFate(
      context,
      s.rolled,
      ref.read(metaProvider).profile.equipped[ItemType.dice]!,
    );
    if (r != null) await ctrl.act(SetFate(r.$1, r.$2));
  }

  void _rematch() {
    final cfg = session.match.config;
    final next = MatchSession(
      match: MatchState(
        MatchConfig(
          mode: cfg.mode,
          length: cfg.length,
          cubeEnabled: cfg.cubeEnabled,
          seed: DateTime.now().microsecondsSinceEpoch & 0x7FFFFFFF,
          p7: cfg.p7,
          cardPool: cfg.cardPool,
          white: cfg.white,
          black: cfg.black,
        ),
      ),
      white: session.white,
      black: session.black,
      origin: session.origin,
    );
    unawaited(
      Navigator.of(context)
          .pushReplacement(fadeRoute<void>(GameScreen(session: next))),
    );
  }

  Widget _gameOver() {
    final l = context.l10n;
    final s = ctrl.state;
    final res = s.result!;
    final pp = session.isPassAndPlay;
    final humanWon = ctrl.isHuman(res.winner);
    final match = ctrl.match;
    final matchOver = match.isOver;
    final title = pp
        ? l.winsGame(_name(res.winner))
        : matchOver && match.config.length > 1
        ? (humanWon ? l.matchWon : l.matchLost)
        : (humanWon ? l.victory : l.defeat);
    final sub =
        '${switch (res.type) {
          WinType.normal => l.winNormal,
          WinType.gammon => l.winGammon,
          WinType.backgammon => l.winBackgammon,
          WinType.dropped => l.winDropped,
          WinType.resigned => l.winResigned,
        }} · ${l.pointsWon(res.points)}';
    final lang = context.lang;
    final scoreLine = match.config.length > 1
        ? '${_name(Side.white)} ${formatNumber(match.score(Side.white), lang)} – ${formatNumber(match.score(Side.black), lang)} ${_name(Side.black)}'
        : null;
    final journey = session.origin == 'journey';
    return GameOverPanel(
      title: title,
      subtitle: sub,
      won: humanWon || pp,
      scoreLine: scoreLine,
      rewards: _rewards,
      actions: [
        if (!matchOver)
          JewelButton(
            label: l.nextGame,
            icon: Icons.arrow_forward,
            color: AppColors.emerald,
            onPressed: () {
              setState(() {
                _showGameOver = false;
                _rewards = null;
              });
              unawaited(ctrl.nextGame());
            },
          )
        else if (journey)
          JewelButton(
            label: l.leaveShop,
            icon: Icons.arrow_forward,
            color: AppColors.emerald,
            onPressed: () =>
                Navigator.of(context)
                    .pop(match.winner != null && ctrl.isHuman(match.winner!)),
          )
        else
          JewelButton(
            label: l.rematch,
            icon: Icons.replay,
            color: AppColors.emerald,
            onPressed: _rematch,
          ),
        if (ctrl.lastFinished != null)
          JewelButton(
            label: l.replay,
            icon: Icons.slow_motion_video,
            color: AppColors.violet,
            onPressed: () => unawaited(
              Navigator.of(
                context,
              ).push(fadeRoute<void>(ReplayScreen(record: ctrl.lastFinished!))),
            ),
          ),
        if (!journey || !matchOver)
          JewelButton(
            label: l.mainMenu,
            icon: Icons.home,
            onPressed: () => Navigator.of(context).pop(),
          ),
      ],
    );
  }

  // --- Tutorial -----------------------------------------------------------------

  Widget _tutorialBanner() {
    final l = context.l10n;
    final lang = context.lang;
    final tut = widget.tutorial!;
    final step = tut[_step];
    final canNext = step.done == null || _stepDone;
    final last = _step == tut.length - 1;
    return Panel(
      glow: canNext ? AppColors.emerald : AppColors.goldLight,
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Text(
                '${formatNumber(_step + 1, lang)}/${formatNumber(tut.length, lang)}',
                style: const TextStyle(color: AppColors.muted),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  step.title(lang),
                  style: const TextStyle(
                    fontFamily: AppFonts.display,
                    fontSize: 20,
                    color: AppColors.goldLight,
                  ),
                ),
              ),
              if (_stepDone)
                const Icon(Icons.check_circle, color: AppColors.emerald),
            ],
          ),
          Text(
            step.body(lang),
            style: const TextStyle(fontSize: 13.5, height: 1.45),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(l.skip),
              ),
              const SizedBox(width: 8),
              JewelButton(
                label: last ? l.finish : l.next,
                expand: false,
                height: 46,
                fontSize: 16,
                color: AppColors.emerald,
                onPressed: canNext
                    ? () {
                        if (last) {
                          Navigator.of(context).pop();
                          return;
                        }
                        setState(() {
                          _step++;
                          _stepDone = false;
                        });
                        unawaited(ctrl.reset(tut[_step].build()));
                      }
                    : null,
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Invisible semantics nodes over each point so screen readers can read and
  /// activate the Flame board.
  Widget _boardSemantics() {
    if (!game.isLoaded) return const SizedBox.shrink();
    final s = ctrl.state;
    final l = context.l10n;
    final lang = context.lang;
    final local = session.isPassAndPlay ? s.current : ctrl.localSide;
    String owner(Side side) => side == local ? l.you : _name(side);
    final nodes = <Widget>[];
    for (var abs = 1; abs <= 24; abs++) {
      final r = game.layout.pointHitRect(abs);
      final (side, n) = s.board.atAbsolute(abs);
      final rel = toRelative(local, abs);
      final label = side == null
          ? formatNumber(rel, lang)
          : '${formatNumber(rel, lang)}: ${formatNumber(n, lang)} × ${owner(side)}';
      nodes.add(
        Positioned.fromRect(
          rect: r,
          child: Semantics(
            container: true,
            button: true,
            label: label,
            onTap: () => game.handleTap(r.center),
            child: const SizedBox.expand(),
          ),
        ),
      );
    }
    for (final side in Side.values) {
      final bar = s.board.onBar(side);
      if (bar == 0) continue;
      nodes.add(
        Positioned.fromRect(
          rect: game.layout.bar,
          child: Semantics(
            container: true,
            button: true,
            label: '${l.bar}: ${formatNumber(bar, lang)} × ${owner(side)}',
            onTap: () => game.handleTap(game.layout.bar.center),
            child: const SizedBox.expand(),
          ),
        ),
      );
    }
    return Stack(children: nodes);
  }

  // --- Build --------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final meta = ref.watch(metaProvider);
    final st = meta.settings;
    final s = ctrl.state;
    final waiting = ctrl.waitingForHuman;
    final local = session.isPassAndPlay ? Side.white : ctrl.localSide;
    final top = PlayerPanel(
      controller: ctrl,
      side: local.opponent,
      showPips: st.showPips,
    );
    final bottom = PlayerPanel(
      controller: ctrl,
      side: local,
      showPips: st.showPips,
    );
    final bar = ActionBar(
      controller: ctrl,
      onLucky: () => unawaited(_lucky()),
      onFate: () => unawaited(_fate()),
      leftHanded: st.leftHanded,
    );
    final eq = meta.profile.equipped;

    final board = Stack(
      children: [
        Positioned.fill(child: GameWidget(game: game)),
        Positioned.fill(child: IgnorePointer(child: _boardSemantics())),
        PositionedDirectional(
          top: 6,
          end: 6,
          child: JewelIconButton(
            icon: Icons.pause,
            tooltip: context.l10n.paused,
            onPressed: () => unawaited(_pause()),
          ),
        ),
        if (widget.tutorial == null)
          PositionedDirectional(
            bottom: 6,
            end: 6,
            child: JewelIconButton(
              icon: Icons.chat_bubble_outline,
              tooltip: context.l10n.emoteTitle,
              onPressed: () => unawaited(_pickEmote()),
            ),
          ),
        for (final e in _emotes.entries)
          PositionedDirectional(
            top: e.key == local ? null : 8,
            bottom: e.key == local ? 60 : null,
            start: 16,
            child: TweenAnimationBuilder<double>(
              key: ValueKey('${e.key}${e.value}'),
              tween: Tween(begin: 0.6, end: 1),
              duration: const Duration(milliseconds: 260),
              curve: Curves.easeOutBack,
              builder: (_, v, child) => Transform.scale(scale: v, child: child),
              child: EmoteBubble(text: e.value),
            ),
          ),
        Positioned(
          top: 8,
          left: 60,
          right: 60,
          child: Center(child: ToastStack(toasts: _toasts)),
        ),
        if (s.phase == Phase.opening && widget.tutorial == null)
          Positioned(
            bottom: 12,
            left: 60,
            right: 60,
            child: IgnorePointer(
              child: Text(
                '${context.l10n.tip}: $_tip',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 12.5,
                  color: AppColors.muted,
                  height: 1.4,
                ),
              ),
            ),
          ),
        if (s.phase == Phase.cardTarget && waiting)
          Positioned(
            top: 8,
            left: 60,
            right: 60,
            child: Center(
              child: Panel(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                glow: AppColors.goldLight,
                child: Text(
                  _targetPrompt(),
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ),
        if (_reveal != null)
          Positioned(
            top: 60,
            left: 12,
            right: 12,
            child: Center(
              child: TweenAnimationBuilder<double>(
                key: ValueKey(_reveal),
                tween: Tween(begin: 0, end: 1),
                duration: const Duration(milliseconds: 280),
                curve: Curves.easeOutBack,
                builder: (_, v, child) => Opacity(
                  opacity: v.clamp(0, 1),
                  child: Transform.translate(
                    offset: Offset(0, (1 - v) * -30),
                    child: child,
                  ),
                ),
                child: CardReveal(
                  who: _reveal!.$1,
                  cardId: _reveal!.$2,
                  frameId: eq[ItemType.cardFrame]!,
                ),
              ),
            ),
          ),
      ],
    );

    final wide =
        MediaQuery.sizeOf(context).width >
        MediaQuery.sizeOf(context).height * 1.15;
    if (widget.tutorial != null) {
      return Scaffold(
        backgroundColor: AppColors.night,
        body: SafeArea(
          child: Stack(
            children: [
              Positioned.fill(
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(8),
                      child: _tutorialBanner(),
                    ),
                    Expanded(child: board),
                    bar,
                  ],
                ),
              ),
              if (s.phase == Phase.sevenPick && waiting)
                Positioned.fill(
                  child: SevenOverlay(
                    key: ValueKey('t$_step-${s.offer.join()}'),
                    offer: s.offer,
                    picksLeft: s.picksLeft,
                    backId: eq[ItemType.cardBack]!,
                    frameId: eq[ItemType.cardFrame]!,
                    onPick: (i) => unawaited(ctrl.act(PickCard(i))),
                  ),
                ),
            ],
          ),
        ),
      );
    }
    final body = wide
        ? Row(
            children: [
              SizedBox(
                width: 320,
                child: Column(
                  children: [
                    top,
                    const Spacer(),
                    bottom,
                    bar,
                    const SizedBox(height: 8),
                  ],
                ),
              ),
              Expanded(child: board),
            ],
          )
        : Column(
            children: [
              top,
              Expanded(child: board),
              bottom,
              bar,
            ],
          );

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) unawaited(_pause());
      },
      child: Scaffold(
        backgroundColor: AppColors.night,
        body: SafeArea(
          child: Stack(
            children: [
              Positioned.fill(child: body),
              if (s.phase == Phase.sevenPick && waiting)
                Positioned.fill(
                  child: SevenOverlay(
                    key: ValueKey('${s.turnNumber}-${s.offer.join()}'),
                    offer: s.offer,
                    picksLeft: s.picksLeft,
                    backId: eq[ItemType.cardBack]!,
                    frameId: eq[ItemType.cardFrame]!,
                    onPick: (i) => unawaited(ctrl.act(PickCard(i))),
                  ),
                ),
              if (s.phase == Phase.chooseDice && waiting)
                Positioned.fill(
                  child: ColoredBox(
                    color: Colors.black54,
                    child: ChooseDiceOverlay(
                      values: s.choiceDice,
                      diceId: eq[ItemType.dice]!,
                      onChoose: (a, b) => unawaited(ctrl.act(ChooseDice(a, b))),
                    ),
                  ),
                ),
              if (s.phase == Phase.cubeOffered && waiting)
                Positioned.fill(
                  child: ColoredBox(
                    color: Colors.black54,
                    child: CubeOfferPanel(
                      name: _name(s.current),
                      value: s.cubeValue * 2,
                      onTake: () => unawaited(ctrl.act(const TakeDouble())),
                      onDrop: () => unawaited(ctrl.act(const DropDouble())),
                    ),
                  ),
                ),
              if (s.isOver && _showGameOver)
                Positioned.fill(
                  child: ColoredBox(color: Colors.black45, child: _gameOver()),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Difficulty display helper shared by screens.
String difficultyName(BuildContext context, Difficulty d) {
  final l = context.l10n;
  return switch (d) {
    Difficulty.beginner => l.diffBeginner,
    Difficulty.easy => l.diffEasy,
    Difficulty.medium => l.diffMedium,
    Difficulty.hard => l.diffHard,
    Difficulty.master => l.diffMaster,
  };
}
