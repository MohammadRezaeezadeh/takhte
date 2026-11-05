import 'dart:async';
import 'dart:math' as math;

import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:haftnard/core/ai/personality.dart';
import 'package:haftnard/core/effects/card_logic.dart';
import 'package:haftnard/core/effects/card_meta.dart';
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
import 'package:haftnard/meta/debug_memory.dart';
import 'package:haftnard/meta/meta_state.dart';
import 'package:haftnard/net/lan/lan_link.dart';
import 'package:haftnard/net/lan/lan_lobby.dart';
import 'package:haftnard/ui/app.dart';
import 'package:haftnard/ui/game/board_help.dart';
import 'package:haftnard/ui/game/card_flow.dart';
import 'package:haftnard/ui/game/card_tags.dart';
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
    this.lan,
    this.onLanReady,
  });

  final MatchSession session;

  /// A LAN game: the connection to the other phone.
  final LanSession? lan;

  /// Called once the controller is bound to [lan] (attaches the channel).
  final VoidCallback? onLanReady;

  /// Journey mode stores the session inside the run instead of `activeMatch`.
  final void Function(MatchSession s)? persistOverride;

  /// Locker previews / tests.
  final SceneConfig? sceneOverride;

  /// Interactive lessons played on this board.
  final List<TutorialStep>? tutorial;

  /// Test hook: pending chips that flew to their target when they fired.
  @visibleForTesting
  static int debugChipFlights = 0;

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

  /// The opponent's 7–7 pick, held until acknowledged.
  String? _aiPick;
  Completer<void>? _aiAck;
  Timer? _aiAckTimer;

  /// Cards flying to their targets (game coordinates).
  final List<({String cardId, Offset from, Offset to, bool chip, int id})>
  _flights = [];
  int _flightSeq = 0;

  /// Last cards used by both players (newest first).
  final List<({String who, String cardId})> _history = [];

  /// Effects that were waiting for their turn (to fly their chip in).
  Set<int> _pendingIds = {};

  /// Card the human just played, for the result banner.
  String? _result;
  Timer? _resultTimer;

  /// All targets picked; waiting for Confirm (Undo still possible).
  bool _targetsReady = false;
  final List<int> _chosen = [];
  int _step = 0;
  bool _stepDone = false;
  String? _tipText;
  String get _tip => _tipText ??= randomTip(context.lang);
  final Map<Side, String> _emotes = {};
  StreamSubscription<String>? _lanEmotes;
  LanStatus _lanStatus = LanStatus.connected;

  void _onLanStatus() {
    if (!mounted) return;
    setState(() => _lanStatus = widget.lan!.link.status.value);
  }

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
      lan: widget.lan?.link,
    );
    final lan = widget.lan;
    if (lan != null) {
      lan.link.status.addListener(_onLanStatus);
      _lanEmotes = lan.link.emotes.listen(
        (id) => _emote(lan.link.remoteSide, id),
      );
      widget.onLanReady?.call();
    }
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
    game.eventGate = _gate;
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => unawaited(ctrl.begin()),
    );
    unawaited(
      Sfx.instance.setAmbient(on: true, track: Sfx.instance.nextGameTrack()),
    );
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
    if (ctrl.isHuman(ai) || session.origin == 'tutorial' || session.isLan) {
      return;
    }
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
    if (id != null && mounted) {
      _emote(side, id);
      widget.lan?.link.sendEmote(id);
    }
  }

  @override
  void dispose() {
    // Flame's debug DevToolsService keeps the last game; don't let it keep
    // this screen too.
    game.eventGate = null;
    final lan = widget.lan;
    if (lan != null) {
      lan.link.status.removeListener(_onLanStatus);
      unawaited(_lanEmotes?.cancel());
      // Leaving mid-match counts as resigning on the other phone.
      if (!ctrl.match.isOver) lan.link.leave();
      unawaited(lan.close());
    }
    for (final t in _emoteTimers.values) {
      t.cancel();
    }
    _resultTimer?.cancel();
    _aiAckTimer?.cancel();
    trimRiverpodDevtools();
    unawaited(Sfx.instance.setTension(on: false));
    unawaited(Sfx.instance.setAmbient(on: true, track: 'music_menu'));
    unawaited(_sub.cancel());
    ctrl
      ..removeListener(_onCtrl)
      ..dispose();
    super.dispose();
  }

  void _persist(MatchController c) {
    if (!mounted) return;
    if (session.origin == 'tutorial' || session.isLan) return;
    if (widget.persistOverride != null) {
      widget.persistOverride!(session);
      return;
    }
    _meta.saveActiveMatch(c.match.isOver ? null : session.toJson());
  }

  void _onGameFinished(MatchController c, GameRecord finished, GameState end) {
    if (!mounted) return;
    trimRiverpodDevtools();
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
        // LAN games reward like pass-and-play (no coin farming).
        passAndPlay: session.isPassAndPlay || session.isLan,
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
          Sfx.instance.duckForSeven();
          _aiReact(side, 'emo_seven', chance: 0.7);
          _aiReact(side.opponent, 'emo_wow', chance: 0.4);
        case CheckerHit(:final victim):
          _aiReact(victim, 'emo_oops', chance: 0.35);
          _aiReact(victim.opponent, 'emo_bravo', chance: 0.25);
        case GameEnded(:final winner):
          _aiReact(winner.opponent, 'emo_wellplayed', chance: 0.8);
        case CardPicked(:final side, :final cardId):
          if (ctrl.isHuman(side)) {
            _resultTimer?.cancel();
            setState(() => _result = cardId);
            _resultTimer = Timer(const Duration(milliseconds: 2600), () {
              if (mounted) setState(() => _result = null);
            });
          }
        default:
          break;
      }
    }
  }

  /// Holds the presented step: the opponent's 7–7 pick (after its dice have
  /// landed) until the player taps «فهمیدم» (8 s fallback); every card then
  /// flies to its target. The opponent's three offered cards aren't shown.
  Future<void> _gate(GameEvent e) async {
    if (!mounted) return;
    final pass = session.isPassAndPlay;
    final tutorial = widget.tutorial != null;
    // Only pause for a human playing against this AI (not for spectating).
    bool aiVsHuman(Side s) => !ctrl.isHuman(s) && ctrl.isHuman(s.opponent);
    if (e is CardPicked) {
      _history.insert(0, (who: _name(e.side), cardId: e.cardId));
      if (_history.length > 10) _history.removeLast();
      if (aiVsHuman(e.side) && !pass && !tutorial) {
        final ack = _aiAck = Completer<void>();
        setState(() => _aiPick = e.cardId);
        // Auto-continue after 8 s; a cancellable timer so nothing lingers
        // once the player taps (or the screen closes).
        _aiAckTimer = Timer(const Duration(seconds: 8), () {
          if (!ack.isCompleted) ack.complete();
        });
        await ack.future;
        _aiAckTimer?.cancel();
        if (!mounted) return;
        setState(() {
          _aiPick = null;
          _aiAck = null;
        });
      }
      await _fly(e.side, e.cardId);
    }
  }

  /// Where a card acts: a board point it marked, else the affected dice.
  Offset _cardTarget(Side side, String cardId) {
    final s = ctrl.state;
    final meta = cardMeta(cardId);
    var newest = -1;
    var point = 0;
    for (final ef in s.effects) {
      if (ef.owner == side && ef.point > 0 && ef.id > newest) {
        newest = ef.id;
        point = ef.point;
      }
    }
    if (cardById(cardId).target != TargetKind.none && point > 0) {
      return game.anchorFor(point: point);
    }
    final target = meta.who == CardWho.opponent ? side.opponent : side;
    return game.anchorFor(side: target);
  }

  Future<void> _fly(
    Side side,
    String cardId, {
    bool chip = false,
    Offset? from,
  }) async {
    if (!mounted || !game.isLoaded) return;
    final to = _cardTarget(side, cardId);
    final start = from ?? game.layout.field.center;
    final id = ++_flightSeq;
    setState(
      () => _flights.add((
        cardId: cardId,
        from: start,
        to: to,
        chip: chip,
        id: id,
      )),
    );
    await Future<void>.delayed(Duration(milliseconds: chip ? 540 : 640));
    if (!mounted) return;
    setState(() => _flights.removeWhere((f) => f.id == id));
    if (!game.isLoaded) return;
    game.fx
      ..burst(to, count: chip ? 16 : 30)
      ..ring(to, const Color(0xFFFFD36B), size: game.layout.checkerR * 3);
    Sfx.instance.play('card_pick', rate: chip ? 1.2 : 0.8);
  }

  /// A delayed card that just started acting: its HUD chip flies from the
  /// affected player's panel to its dice.
  void _flyActivatedChips() {
    final s = ctrl.state;
    final pending = <int>{
      for (final e in s.effects)
        if (!e.isActive(s.turnNumber)) e.id,
    };
    for (final e in s.effects) {
      if (_pendingIds.contains(e.id) && e.isActive(s.turnNumber)) {
        GameScreen.debugChipFlights++;
        final top = !ctrl.isHuman(e.affected);
        final f = game.layout.field;
        unawaited(
          _fly(
            e.owner,
            cardForEffect(e.kind),
            chip: true,
            from: Offset(f.center.dx, top ? f.top : f.bottom),
          ),
        );
      }
    }
    _pendingIds = pending;
  }

  /// Tension: someone trails by 40+ pips, or the race to bear off is on.
  static bool _tense(GameState s) {
    if (s.isOver) return false;
    final w = s.board.pips(Side.white);
    final b = s.board.pips(Side.black);
    final racing = s.board.allHome(Side.white) || s.board.allHome(Side.black);
    return (w - b).abs() >= 40 || racing;
  }

  void _onCtrl() {
    if (!mounted) return;
    if (game.isLoaded) _flyActivatedChips();
    unawaited(Sfx.instance.setTension(on: _tense(ctrl.state)));
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
      _targetsReady = false;
      game
        ..targetable = {}
        ..targetChosen = [];
      return;
    }
    if (_targetsReady) return;
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
    if (_targetsReady) return;
    _chosen.add(abs);
    final all = _allTargets();
    final complete = all.any(
      (c) =>
          c.length == _chosen.length && _matches(c, _chosen, prefixOnly: false),
    );
    if (complete) {
      // Wait for Confirm so the player can still undo a mis-tap.
      _targetsReady = true;
      game
        ..targetable = {}
        ..targetChosen = List.of(_chosen);
    } else {
      _updateTargeting();
    }
    setState(() {});
  }

  void _undoTarget() {
    if (_chosen.isEmpty) return;
    _chosen.removeLast();
    _targetsReady = false;
    _updateTargeting();
    setState(() {});
  }

  void _confirmTargets() {
    if (!_targetsReady) return;
    final pts = List<int>.of(_chosen);
    _chosen.clear();
    _targetsReady = false;
    game
      ..targetable = {}
      ..targetChosen = [];
    unawaited(ctrl.act(ChooseTargets(pts)));
  }

  int _targetTotal() {
    var n = 0;
    for (final c in _allTargets()) {
      if (c.length > n) n = c.length;
    }
    return n;
  }

  /// Live board preview of a card while choosing (null clears it).
  void _preview(String? id) {
    if (id == null) {
      game
        ..previewPoints = {}
        ..previewDice = null;
      return;
    }
    final s = ctrl.state;
    final def = cardById(id);
    final meta = cardMeta(id);
    final points = <int>{};
    if (def.target != TargetKind.none) {
      CardLogic.allTargets(Tx(s), s.current, id).forEach(points.addAll);
    }
    final side = meta.who == CardWho.opponent ? s.current.opponent : s.current;
    final l = context.l10n;
    game
      ..previewPoints = points
      ..previewDice = (
        side: side,
        label:
            '${def.name(context.lang)} · '
            '${durationLabel(l, context.lang, id)}',
        color: meta.who == CardWho.opponent
            ? const Color(0xFFFF8A8A)
            : const Color(0xFF7FE3F0),
      );
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
        for (final f in _flights)
          Positioned.fill(
            child: CardFlight(
              key: ValueKey('flight-${f.id}'),
              cardId: f.cardId,
              from: f.from,
              to: f.to,
              chip: f.chip,
              onDone: () {},
            ),
          ),
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
        PositionedDirectional(
          top: 6,
          end: 58,
          child: JewelIconButton(
            key: const ValueKey('board-help'),
            icon: Icons.question_mark,
            tooltip: context.l10n.help,
            onPressed: () => unawaited(
              showBoardHelp(context, cube: ctrl.state.config.cubeEnabled),
            ),
          ),
        ),
        PositionedDirectional(
          top: 6,
          end: 110,
          child: JewelIconButton(
            key: const ValueKey('card-history-button'),
            icon: Icons.history,
            tooltip: context.l10n.cardHistory,
            onPressed: () => unawaited(showCardHistory(context, _history)),
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
            left: 12,
            right: 12,
            child: Center(
              child: Panel(
                key: const ValueKey('target-banner'),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                glow: AppColors.goldLight,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${_targetPrompt()} '
                      '(${context.l10n.targetProgress(formatNumber(_chosen.length, context.lang), formatNumber(_targetTotal(), context.lang))})',
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    if (_chosen.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            JewelButton(
                              key: const ValueKey('target-undo'),
                              label: context.l10n.undoTarget,
                              icon: Icons.undo,
                              expand: false,
                              height: 38,
                              fontSize: 14,
                              onPressed: _undoTarget,
                            ),
                            if (_targetsReady) ...[
                              const SizedBox(width: 8),
                              JewelButton(
                                key: const ValueKey('target-confirm'),
                                label: context.l10n.confirmTargets,
                                icon: Icons.check,
                                color: AppColors.emerald,
                                expand: false,
                                height: 38,
                                fontSize: 14,
                                onPressed: _confirmTargets,
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        if (_aiPick != null)
          Positioned.fill(
            child: AiPickOverlay(
              picked: _aiPick!,
              frameId: eq[ItemType.cardFrame]!,
              onAck: () {
                final a = _aiAck;
                if (a != null && !a.isCompleted) a.complete();
              },
            ),
          ),
        if (_result != null)
          Positioned(
            top: 8,
            left: 40,
            right: 40,
            child: IgnorePointer(
              child: Center(
                child: TweenAnimationBuilder<double>(
                  key: ValueKey('result-$_result'),
                  tween: Tween(begin: 0, end: 1),
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOutBack,
                  builder: (_, v, child) =>
                      Transform.scale(scale: 0.6 + 0.4 * v, child: child),
                  child: Panel(
                    key: const ValueKey('result-banner'),
                    glow: AppColors.emerald,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    child: Text(
                      context.l10n.resultDone(
                        cardById(_result!).name(context.lang),
                        cardById(_result!).desc(context.lang),
                      ),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        height: 1.4,
                      ),
                    ),
                  ),
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
                    onPreview: _preview,
                    showGuide:
                        widget.tutorial == null &&
                        !ref.read(metaProvider).settings.sevenGuideDone,
                    onGuideDone: () => _meta.updateSettings(
                      ref
                          .read(metaProvider)
                          .settings
                          .copyWith(sevenGuideDone: true),
                    ),
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
                    onPreview: _preview,
                    showGuide:
                        widget.tutorial == null &&
                        !ref.read(metaProvider).settings.sevenGuideDone,
                    onGuideDone: () => _meta.updateSettings(
                      ref
                          .read(metaProvider)
                          .settings
                          .copyWith(sevenGuideDone: true),
                    ),
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
              if (widget.lan != null && _lanStatus != LanStatus.connected)
                Positioned(
                  top: 8,
                  left: 16,
                  right: 16,
                  child: _LanBanner(status: _lanStatus),
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

class _LanBanner extends StatelessWidget {
  const _LanBanner({required this.status});
  final LanStatus status;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final (text, color) = switch (status) {
      LanStatus.left => (l.lanLeft, AppColors.ruby),
      LanStatus.desync => (l.lanSyncing, AppColors.lapis),
      _ => (l.lanLost, AppColors.ruby),
    };
    return Material(
      key: const ValueKey('lan-banner'),
      color: color.withValues(alpha: 0.92),
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(
          children: [
            Icon(
              status == LanStatus.left ? Icons.person_off : Icons.wifi_off,
              color: Colors.white,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                text,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
