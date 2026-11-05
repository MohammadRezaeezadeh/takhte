import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:haftnard/core/effects/cards.dart';
import 'package:haftnard/core/rules/actions.dart';
import 'package:haftnard/core/rules/engine.dart';
import 'package:haftnard/core/rules/events.dart';
import 'package:haftnard/core/rules/state.dart';
import 'package:haftnard/core/rules/types.dart';
import 'package:haftnard/game/audio.dart';
import 'package:haftnard/game/layout.dart';
import 'package:haftnard/game/match_controller.dart';
import 'package:haftnard/game/scene/environment.dart';
import 'package:haftnard/game/scene/fx.dart';
import 'package:haftnard/game/scene/paragraph_cache.dart';
import 'package:haftnard/game/scene/power_layer.dart';
import 'package:haftnard/game/scene/power_visuals.dart';
import 'package:haftnard/game/themes/board_themes.dart';
import 'package:haftnard/game/themes/pieces.dart';
import 'package:meta/meta.dart';

/// Visual configuration for the scene.
class SceneConfig {
  const SceneConfig({
    this.boardId = 'board_khatam',
    this.envId = 'env_lantern_hall',
    this.checkerId = 'chk_wood',
    this.diceId = 'dice_bone',
    this.victoryId = 'vic_fireworks',
    this.homeOnRight = true,
    this.animSpeed = 1,
    this.reducedMotion = false,
    this.colorblind = false,
    this.highContrast = false,
    this.persianDigits = false,
  });

  final String boardId;
  final String envId;
  final String checkerId;
  final String diceId;
  final String victoryId;
  final bool homeOnRight;
  final double animSpeed;
  final bool reducedMotion;
  final bool colorblind;
  final bool highContrast;
  final bool persianDigits;
}

double _ease(double t) =>
    t < 0.5 ? 4 * t * t * t : 1 - math.pow(-2 * t + 2, 3) / 2;

/// One animated checker.
class _Chk {
  _Chk(this.side, this.slot, this.pos);
  final Side side;
  Slot slot;
  Offset pos;
  Offset _from = Offset.zero;
  Offset _to = Offset.zero;
  double _t = 1;
  double _dur = 0;
  double _arc = 0;
  double lift = 0;
  double squash = 1;
  double _squashT = 1;
  bool dragging = false;
  Completer<void>? _done;
  final List<Offset> trail = [];

  /// True while travelling between slots (a move, hit, bar entry or a drag
  /// returning home) — as opposed to a small re-layout nudge inside a stack.
  bool travelling = false;

  /// Order in which travels started; later travels paint above earlier ones.
  int travelStamp = 0;

  bool get moving => _t < 1 || dragging;

  /// Painted above every resting checker.
  bool get onTop => dragging || (travelling && _t < 1);

  Future<void> glide(
    Offset to,
    double dur, {
    double arc = 0,
    bool travel = false,
  }) {
    _done?.complete();
    travelling = travel;
    _from = pos;
    _to = to;
    _t = 0;
    _dur = math.max(dur, 0.001);
    _arc = arc;
    final c = Completer<void>();
    _done = c;
    return c.future;
  }

  void update(double dt, {required bool trailOn}) {
    if (_t < 1) {
      _t = math.min(1, _t + dt / _dur);
      final e = _ease(_t);
      final base = Offset.lerp(_from, _to, e)!;
      final h = math.sin(math.pi * _t) * _arc;
      pos = base.translate(0, -h);
      lift = h;
      if (trailOn) {
        trail.add(pos);
        if (trail.length > 10) trail.removeAt(0);
      }
      if (_t >= 1) {
        pos = _to;
        lift = 0;
        travelling = false;
        if (_arc > 0) _squashT = 0;
        final d = _done;
        _done = null;
        d?.complete();
      }
    } else if (trail.isNotEmpty) {
      trail.removeAt(0);
    }
    if (_squashT < 1) {
      _squashT = math.min(1, _squashT + dt / 0.18);
      squash = 1 - 0.22 * math.sin(math.pi * _squashT) * (1 - _squashT * 0.5);
    } else {
      squash = 1;
    }
  }
}

class _Die {
  _Die(this.value, this.pos);

  /// Decided before the throw; never changes once landed (only a Lucky
  /// Charm / Fate's Edit / reroll edits it on purpose).
  int value;
  Offset pos;
  Offset target = Offset.zero;
  Offset start = Offset.zero;
  double angle = 0;

  /// Resting tilt the tumble settles on.
  double tilt = 0;
  double spin = 0;
  bool used = false;
  double t = 1;

  /// 1 = spinning too fast to read, 0 = landed.
  double blur = 0;

  /// Grows from small when a double clones its twins.
  double scale = 1;
}

/// The board scene. Implements [MatchPresenter] so the controller can await
/// animations.
class BoardGame extends FlameGame implements MatchPresenter {
  BoardGame({
    required this.controller,
    required SceneConfig config,
    this.onTargetTap,
    this.onSceneEvent,
  }) : _cfg = config;

  final MatchController controller;
  SceneConfig _cfg;

  /// Called with an absolute point (0 = bar) while targeting a card.
  void Function(int abs)? onTargetTap;

  /// UI hook for toasts (e.g. 'mine', 'phoenix').
  void Function(GameEvent e)? onSceneEvent;

  late BoardLayout layout;
  late BoardThemeData theme;
  late CheckerStyle chkStyle;
  late DiceStyle dieStyle;
  ui.Picture? _basePic;
  ui.Picture? _feltPic;
  ui.Picture? _topPic;
  final Map<String, ui.Image> _chkCache = {};
  final ParagraphCache _text = ParagraphCache();

  /// The live scene, for the debug overlay and tests.
  static BoardGame? current;

  @override
  void onRemove() {
    if (current == this) current = null;
    _releaseArt();
    fx.clear();
    super.onRemove();
  }

  /// Live object counts for the debug overlay and the soak test.
  Map<String, int> debugStats() => {
    'components': descendants().length,
    'particles': fx.particleCount,
    'popups': fx.popupCount,
    'pooled': fx.pooledCount,
    'checkers': _checkers.length,
    'dice': _dice.length,
    'images': _chkCache.length,
    'texts': _text.length,
  };

  late final FxLayer fx;
  late final EnvironmentLayer env;
  final List<_Chk> _checkers = [];
  final Map<Slot, List<_Chk>> _stacks = {};
  int _travelSeq = 0;
  final List<_Die> _dice = [];
  double _time = 0;
  double _shake = 0;
  final _rng = math.Random(11);
  GameState? _shown;

  // Interaction.
  int? selectedFrom; // mover-relative source (25 = bar)
  _Chk? _dragChk;
  Offset _dragOffset = Offset.zero;
  int? _dragFrom;

  GameState? _legalFor;
  List<Move> _legalCache = const [];

  /// Legal moves for [s], memoised per state instance (rendering asks every
  /// frame; move generation is a DFS).
  List<Move> _legal(GameState s) {
    if (!identical(s, _legalFor)) {
      _legalFor = s;
      _legalCache = Engine.legalMoves(s);
    }
    return _legalCache;
  }

  /// Valid targets while a card is being targeted (absolute; 0 = bar).
  Set<int> targetable = {};
  List<int> targetChosen = [];

  /// Card preview while choosing a 7–7 card: points it could affect and a
  /// ghost badge on the affected side's dice area.
  Set<int> previewPoints = {};
  ({Side side, String label, Color color})? previewDice;

  /// For the power layer: what is on screen, and where a point's checkers
  /// are drawn (bottom to top).
  GameState? get shownState => _shown;
  bool get persianDigits => _cfg.persianDigits;
  bool get reducedMotion => _cfg.reducedMotion;
  double get time => _time;
  List<Offset> checkerPositionsAt(int abs) => [
    for (final c in _stacks[PointSlot(abs)] ?? const <_Chk>[]) c.pos,
  ];

  late final PowerLayer power;

  /// Test hook: is a card preview currently drawn?
  bool get debugPreviewing => previewPoints.isNotEmpty || previewDice != null;

  SceneConfig get config => _cfg;
  double get _speed => _cfg.animSpeed.clamp(0.5, 2.0);

  @override
  Color backgroundColor() => const Color(0xFF0B0F1F);

  @override
  Future<void> onLoad() async {
    current = this;
    await Shaders.load();
    fx = FxLayer(reducedMotion: _cfg.reducedMotion)..priority = 50;
    env = EnvironmentLayer(
      envId: _cfg.envId,
      fx: fx,
      boardRect: () => layout.outer,
      reducedMotion: _cfg.reducedMotion,
    )..priority = 0;
    _applyConfig(_cfg);
    layout = BoardLayout(size.toSize(), homeOnRight: _cfg.homeOnRight);
    await add(env);
    await add(_SceneLayer(this)..priority = 10);
    power = PowerLayer(this)..priority = 20;
    await add(power);
    await add(fx);
    await add(_InputLayer(this)..priority = 100);
    _rebuild();
    _createCheckers();
    resync(controller.state);
  }

  void _applyConfig(SceneConfig c) {
    theme = boardTheme(c.boardId);
    chkStyle = checkerStyle(c.checkerId);
    dieStyle = diceStyle(c.diceId);
  }

  /// Hot-swap cosmetics (locker preview, settings change).
  void updateConfig(SceneConfig c) {
    _cfg = c;
    _applyConfig(c);
    env
      ..envId = c.envId
      ..reducedMotion = c.reducedMotion;
    fx.reducedMotion = c.reducedMotion;
    if (isLoaded) {
      layout = BoardLayout(size.toSize(), homeOnRight: c.homeOnRight);
      _rebuild();
      resync(controller.state, animate: false);
    }
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    if (!isLoaded) return;
    layout = BoardLayout(size.toSize(), homeOnRight: _cfg.homeOnRight);
    env.size = size.toSize();
    _rebuild();
    final s = _shown;
    if (s != null) resync(s, animate: false);
  }

  void _rebuild() {
    env.size = size.toSize();
    final art = BoardArt(theme, layout, persianDigits: _cfg.persianDigits);
    ui.Picture rec(void Function(Canvas) f) {
      final r = ui.PictureRecorder();
      f(Canvas(r));
      return r.endRecording();
    }

    _releaseArt();
    _basePic = rec(art.paintBase);
    _feltPic = theme.pattern == BoardPattern.cosmic ? null : rec(art.paintFelt);
    _topPic = rec(art.paintTop);
  }

  /// Frees the cached board pictures and checker images (GPU memory).
  void _releaseArt() {
    _basePic?.dispose();
    _feltPic?.dispose();
    _topPic?.dispose();
    _basePic = _feltPic = _topPic = null;
    for (final img in _chkCache.values) {
      img.dispose();
    }
    _chkCache.clear();
    _text.clear();
  }

  ui.Image _checkerImage(Side side) {
    final key =
        '${chkStyle.id}|${side.name}|${layout.checkerR.toStringAsFixed(1)}';
    return _chkCache.putIfAbsent(key, () {
      final r = layout.checkerR;
      final sz = (r * 2.8).ceil();
      final rec = ui.PictureRecorder();
      final c = Canvas(rec);
      paintChecker(c, Offset(sz / 2, sz / 2), r, side, chkStyle);
      return rec.endRecording().toImageSync(sz, sz);
    });
  }

  void _createCheckers() {
    _checkers.clear();
    for (final side in Side.values) {
      for (var i = 0; i < Pos.checkers; i++) {
        _checkers.add(_Chk(side, OffSlot(side), Offset.zero));
      }
    }
  }

  // ---------------------------------------------------------------------------
  // Layout of checkers.

  Map<Slot, int> _targetCounts(GameState s) {
    final m = <Slot, int>{};
    for (final side in Side.values) {
      final arr = s.board.of(side);
      for (var rel = 1; rel <= 24; rel++) {
        if (arr[rel] > 0) m[PointSlot(toAbsolute(side, rel))] = arr[rel];
      }
      if (arr[Pos.bar] > 0) m[BarSlot(side)] = arr[Pos.bar];
      if (arr[Pos.off] > 0) m[OffSlot(side)] = arr[Pos.off];
    }
    return m;
  }

  Side _slotSide(Slot slot, GameState s) => switch (slot) {
    PointSlot(:final abs) => s.board.atAbsolute(abs).$1 ?? Side.white,
    BarSlot(:final side) => side,
    OffSlot(:final side) => side,
  };

  /// Reassigns checkers to match [s]; animates if [animate].
  ///
  /// Stack identity is preserved: checkers already on a slot keep their
  /// order, surplus checkers leave from the TOP, and newcomers are added on
  /// top. Only checkers that change slot travel; the others never move
  /// (a stack that compresses past its visible height snaps instantly).
  @override
  void resync(GameState s, {bool animate = true}) {
    _shown = s;
    if (!isLoaded) return;
    final targets = _targetCounts(s);
    final previous = {for (final e in _stacks.entries) e.key: e.value};
    _stacks.clear();
    final assigned = <_Chk>{};
    final kept = <_Chk>{};
    // 1. Keep each slot's existing checkers, bottom-up, in their order.
    for (final e in targets.entries) {
      final side = _slotSide(e.key, s);
      final list = <_Chk>[];
      for (final c in previous[e.key] ?? const <_Chk>[]) {
        if (list.length >= e.value) break;
        if (c.side != side || assigned.contains(c)) continue;
        list.add(c);
        assigned.add(c);
        kept.add(c);
      }
      _stacks[e.key] = list;
    }
    // 2. Fill the rest with checkers that are not placed yet; prefer ones
    //    that were already flying to this slot.
    final pool = {
      for (final side in Side.values)
        side: [
          for (final c in _checkers)
            if (c.side == side && !assigned.contains(c)) c,
        ],
    };
    for (final e in targets.entries) {
      final side = _slotSide(e.key, s);
      final list = _stacks[e.key]!;
      final candidates = pool[side]!
        ..sort((a, b) {
          final am = a.slot == e.key ? 0 : 1;
          final bm = b.slot == e.key ? 0 : 1;
          return am.compareTo(bm);
        });
      for (final c in List<_Chk>.of(candidates)) {
        if (list.length >= e.value) break;
        if (assigned.contains(c)) continue;
        list.add(c);
        assigned.add(c);
        candidates.remove(c);
        c.slot = e.key;
      }
    }
    for (final e in _stacks.entries) {
      _relayout(e.key, animate: animate, kept: kept);
    }
    _syncDice(s);
  }

  void _relayout(Slot slot, {bool animate = true, Set<_Chk>? kept}) {
    final list = _stacks[slot] ?? const [];
    for (var i = 0; i < list.length; i++) {
      final c = list[i];
      if (c.dragging) continue;
      final p = layout.checkerCenter(slot, i, list.length);
      if ((c.pos - p).distance <= 0.5) continue;
      // Checkers that stay on their stack never animate; they only snap if
      // the stack compresses. Travelling ones keep their own animation.
      final stays = kept == null || kept.contains(c);
      if (!animate || c.pos == Offset.zero || (stays && !c.travelling)) {
        if (!c.travelling) c.pos = p;
      } else if (!c.moving) {
        unawaited(c.glide(p, 0.16 / _speed, travel: true));
      }
    }
  }

  Slot _slotFor(Side side, int rel) {
    if (rel == Pos.bar) return BarSlot(side);
    if (rel == Pos.off) return OffSlot(side);
    return PointSlot(toAbsolute(side, rel));
  }

  _Chk? _takeTop(Slot slot, {Side? side}) {
    final list = _stacks[slot];
    if (list == null || list.isEmpty) return null;
    for (var i = list.length - 1; i >= 0; i--) {
      if (side == null || list[i].side == side) return list.removeAt(i);
    }
    return null;
  }

  Future<void> _moveChecker(
    _Chk c,
    Slot to, {
    double dur = 0.34,
    double arc = 1,
  }) async {
    final list = _stacks.putIfAbsent(to, () => []);
    list.add(c);
    c
      ..slot = to
      ..travelStamp = ++_travelSeq;
    final target = layout.checkerCenter(to, list.length - 1, list.length);
    // A tall stack compresses instantly before the arrival; nothing on it
    // moves while the newcomer flies in.
    _relayout(to, kept: {...list}..remove(c));
    final dist = (c.pos - target).distance;
    final arcH = _cfg.reducedMotion ? 0.0 : math.min(60, dist * 0.25) * arc;
    await c.glide(
      target,
      (dur * (0.7 + math.min(dist, 400) / 900)) / _speed,
      arc: arcH,
      travel: true,
    );
    _relayout(to);
  }

  // ---------------------------------------------------------------------------
  // Presenter.

  @override
  Future<void> present(
    GameState before,
    GameState after,
    List<GameEvent> events,
  ) async {
    if (!isLoaded) {
      _shown = after;
      return;
    }
    selectedFrom = null;
    var lastMoveOff = false;
    for (final e in events) {
      onSceneEvent?.call(e);
      debugBeforeEvent?.call(e);
      // The screen may hold the step (e.g. until the player has read the
      // opponent's 7–7 pick).
      final gate = eventGate;
      if (gate != null) await gate(e);
      if (!isMounted) return;
      switch (e) {
        case OpeningRolled():
          await _rollOpening(e.white, e.black);
          lastMoveOff = false;
        case DiceRolled():
          if (_keepOpeningDice) {
            _keepOpeningDice = false;
          } else {
            await _rollDice(e.side, e.dice);
          }
        case SevenRolled():
          await _rollSeven(e.side);
        case MovePlayed(:final side, :final move):
          final from = _slotFor(side, move.from);
          final to = _slotFor(side, move.to);
          final c = _takeTop(from, side: side);
          lastMoveOff = move.to == Pos.off;
          if (c == null) break;
          _relayout(from);
          if (move.die == 0) {
            fx.burst(
              c.pos,
              color: const Color(0xFF9D7BFF),
              count: 20,
              gravity: 0,
            );
            Sfx.instance.play('magic');
          }
          Sfx.instance.play('slide', volume: 0.5);
          await _moveChecker(c, to, arc: move.to == Pos.off ? 0.6 : 1);
          if (move.to == Pos.off) {
            Sfx.instance.play('bear_off', rate: theme.pitch);
            fx
              ..burst(
                c.pos,
                color: theme.glow,
                count: 18,
                kind: ParticleKind.star,
                gravity: -40,
              )
              ..popup('+1', c.pos.translate(0, -20));
            Sfx.instance.haptic(HapticKind.light);
          } else {
            Sfx.instance.clack(rate: theme.pitch);
            Sfx.instance.haptic(HapticKind.light);
            if (chkStyle.glowOnHit || move.ghost) {
              fx.ring(c.pos, theme.glow);
            }
          }
        case CheckerHit(:final victim, :final point):
          final c = _takeTop(PointSlot(point), side: victim);
          if (c == null) break;
          final at = c.pos;
          _impact(at, strong: true);
          await _moveChecker(c, BarSlot(victim), dur: 0.42, arc: 1.4);
        case PhoenixRose(:final side, :final point):
          final c = _takeTop(BarSlot(side), side: side);
          if (c == null) break;
          fx.burst(
            c.pos,
            color: const Color(0xFFFF7A1A),
            count: 30,
            kind: ParticleKind.ember,
            gravity: -120,
          );
          Sfx.instance.play('magic');
          await _moveChecker(c, PointSlot(point), dur: 0.5, arc: 1.6);
          fx.burst(c.pos, gravity: -60);
        case MineTriggered(:final victim, :final point):
          final c = _takeTop(PointSlot(point), side: victim);
          Sfx.instance.play('mine');
          _shake = _cfg.reducedMotion ? 0 : 12;
          fx
            ..burst(
              layout.pointRect(point).center,
              color: const Color(0xFFFF5A1A),
              count: 50,
              speed: 300,
              kind: ParticleKind.ember,
            )
            ..burst(
              layout.pointRect(point).center,
              color: const Color(0xFF555555),
              count: 20,
              kind: ParticleKind.smoke,
              gravity: -30,
              size: 8,
              life: 1.2,
            )
            ..flashScreen(const Color(0xFFFF7A1A));
          Sfx.instance.haptic(HapticKind.heavy);
          if (c != null) {
            await _moveChecker(c, BarSlot(victim), dur: 0.45, arc: 2);
          }
        case CheckerBorneOff(:final side, :final fromAbsolute):
          if (lastMoveOff) {
            lastMoveOff = false;
            break;
          }
          final c = _takeTop(PointSlot(fromAbsolute), side: side);
          if (c == null) break;
          Sfx.instance.play('bear_off', rate: theme.pitch);
          await _moveChecker(c, OffSlot(side), arc: 0.8);
        case Teleported():
          break;
        case CardPicked():
          Sfx.instance.play('card_pick');
        case TurnSkipped():
          Sfx.instance.play('ui_back');
        case CoinFlipped():
          Sfx.instance.play('coin');
        case QuicksandGripped(:final point):
          fx.burst(
            layout.pointRect(point).center,
            color: const Color(0xFF8C6A48),
            count: 14,
            kind: ParticleKind.smoke,
            gravity: 0,
            size: 6,
          );
        case TurnStarted():
          // The opening dice stay on the board as the starter's roll.
          if (!_keepOpeningDice) _dice.clear();
          _ghosts.clear();
        case GameEnded(:final winner):
          await Future<void>.delayed(
            Duration(milliseconds: (300 / _speed).round()),
          );
          final humanWon =
              controller.isHuman(winner) && !controller.session.isPassAndPlay;
          final passPlay = controller.session.isPassAndPlay;
          if (humanWon || passPlay) {
            fx.celebrate(layout.outer, _cfg.victoryId);
            Sfx.instance.play('win');
          } else {
            Sfx.instance.play('lose');
          }
        default:
          break;
      }
      debugAfterEvent?.call(e);
    }
    // Reconcile anything not explicitly animated (Blood Pact, resyncs).
    resync(after);
    env.mood = _mood(after);
    // Show, don't tell: every power that appeared, fired or ended this step.
    power.play(
      PowerVisuals.moments(before, after, events, viewer: controller.localSide),
    );
  }

  double _mood(GameState s) {
    if (controller.session.isPassAndPlay) return 0;
    final me = controller.localSide;
    final diff = s.board.pips(me.opponent) - s.board.pips(me);
    return (diff / 60).clamp(-1.0, 1.0);
  }

  void _impact(Offset at, {bool strong = false}) {
    Sfx.instance.play('hit', rate: theme.pitch);
    Sfx.instance.haptic(strong ? HapticKind.heavy : HapticKind.medium);
    if (!_cfg.reducedMotion) _shake = strong ? 9 : 5;
    fx
      ..flashScreen(const Color(0xFFFFFFFF), strength: 0.35)
      ..burst(at, color: theme.glow, count: 34, speed: 280)
      ..ring(at, const Color(0xFFFFFFFF), size: layout.checkerR * 3)
      ..popup(
        '!',
        at.translate(0, -layout.checkerR * 1.6),
        color: const Color(0xFFFF6B6B),
        size: 30,
      );
  }

  /// True while dice are in the air or cloning: state syncs must not touch
  /// them until they have landed.
  bool _diceAnimating = false;

  /// Set after the opening throw: the next DiceRolled (the same two values,
  /// now the starter's roll) must not throw them again.
  bool _keepOpeningDice = false;

  /// Throws [live] towards their targets. Each die's face is already final:
  /// the tumble is a spin blur that settles exactly on it, so no random face
  /// is ever readable and nothing changes after landing.
  Future<void> _tumble(List<_Die> live, double dur) async {
    // Work on a snapshot: a resync may replace the live list mid-animation.
    final dice = List<_Die>.of(live);
    for (final d in dice) {
      d
        ..start = d.pos
        ..t = 0
        ..blur = 1
        ..tilt = (_rng.nextDouble() - 0.5) * 0.3
        ..spin = (_rng.nextBool() ? 1 : -1) * (5 + _rng.nextDouble() * 3);
    }
    Sfx.instance.play('dice_roll');
    final steps = math.max(1, (dur * 60).round());
    for (var i = 0; i < steps; i++) {
      await Future<void>.delayed(const Duration(milliseconds: 16));
      if (!isMounted) return;
      final t = (i + 1) / steps;
      for (final d in dice) {
        d.t = t;
        final e = 1 - math.pow(1 - t, 3).toDouble();
        final bounce =
            (math.sin(t * math.pi * 3) * (1 - t)).abs() * layout.dieSize * 0.6;
        d
          ..pos = Offset.lerp(d.start, d.target, e)!.translate(0, -bounce)
          // Decelerating spin that ends exactly on the resting tilt.
          ..angle = d.tilt + d.spin * math.pi * (1 - e)
          ..blur = t < 0.7 ? 1 : (1 - (t - 0.7) / 0.25).clamp(0.0, 1.0);
      }
    }
    for (final d in dice) {
      d
        ..pos = d.target
        ..angle = d.tilt
        ..blur = 0
        ..t = 1;
    }
    Sfx.instance.play('dice_land');
    Sfx.instance.haptic(HapticKind.light);
  }

  /// Dice positions. One spacing for every count, so a double's two landed
  /// dice already sit on the middle two of the four slots and never move.
  List<Offset> _diceSlots(Side side, int n) {
    final c = layout.diceCenter(side);
    final s = layout.dieSize * 1.12;
    return [for (var i = 0; i < n; i++) c.translate((i - (n - 1) / 2) * s, 0)];
  }

  Offset _diceStart(Side side) {
    final c = layout.diceCenter(side);
    final towardsBottom = side == controller.localSide;
    return c.translate(
      (_rng.nextDouble() - 0.5) * layout.pointW * 3,
      (towardsBottom ? 1 : -1) * layout.field.height * 0.35,
    );
  }

  Future<void> _rollOpening(int w, int b) async {
    _dice
      ..clear()
      ..add(
        _Die(w, _diceStart(Side.white))..target = layout.diceCenter(Side.white),
      )
      ..add(
        _Die(b, _diceStart(Side.black))..target = layout.diceCenter(Side.black),
      );
    await _tumble(_dice, (_cfg.reducedMotion ? 0.3 : 0.72) / _speed);
    _keepOpeningDice = true;
    await Future<void>.delayed(Duration(milliseconds: (500 / _speed).round()));
  }

  Future<void> _rollDice(Side side, List<int> raw) async {
    // Always exactly the thrown dice (two, or one/three for some cards); a
    // double only becomes four after both have landed.
    final st = controller.state;
    final isDouble = raw.length == 2 && raw[0] == raw[1];
    final four = isDouble && st.dice.length + st.movesThisRoll.length == 4;
    final active = {
      for (final e in st.effects)
        if (e.affected == side && e.isActive(st.turnNumber)) e.kind,
    };
    // Broken Die: a second die is thrown too, and shatters on landing.
    final doomed = raw.length == 1 && active.contains(EffectKind.brokenDie);
    final slots = _diceSlots(side, doomed ? 2 : raw.length);
    final shownFirst = _unmodifiedFaces(st, side, raw);
    _ghosts.clear();
    _diceAnimating = true;
    try {
      _dice
        ..clear()
        ..addAll([
          for (var i = 0; i < raw.length; i++)
            _Die(shownFirst[i], _diceStart(side))..target = slots[i],
          if (doomed)
            _Die(_rng.nextInt(6) + 1, _diceStart(side))..target = slots[1],
        ]);
      await _tumble(_dice, (_cfg.reducedMotion ? 0.3 : 0.72) / _speed);
      if (doomed && isMounted) await _shatterLast();
      if (isMounted) await _applyModifiers(raw, shownFirst);
      if (four && isMounted) await _cloneDouble(side);
      if (isDouble && !four && isMounted) _cancelledDouble(side, raw[0]);
    } finally {
      _diceAnimating = false;
    }
    final shown = _shown;
    if (shown != null) _syncDice(shown);
    if (dieStyle.effect == DiceEffect.sparks) {
      for (final d in _dice) {
        fx.burst(d.pos, color: const Color(0xFFFF9E3D), count: 12, speed: 160);
      }
    } else if (dieStyle.effect == DiceEffect.smoke) {
      for (final d in _dice) {
        fx.burst(
          d.pos,
          color: const Color(0xFFB79CFF),
          count: 8,
          kind: ParticleKind.smoke,
          gravity: -20,
          size: 7,
          life: 1.4,
        );
      }
    }
  }

  /// Translucent, crossed-out twins of a double that did not count.
  final List<({int value, Offset pos})> _ghosts = [];

  /// Faces to land on before visible dice modifiers act: a halved 3 lands
  /// as a 6 and drains, a capped die lands higher and is pressed down, wind
  /// shifts by one. The engine only reports final values; these faces show
  /// what the power did.
  List<int> _unmodifiedFaces(GameState st, Side side, List<int> raw) {
    final active = [
      for (final e in st.effects)
        if (e.affected == side && e.isActive(st.turnNumber)) e,
    ];
    bool has(EffectKind k) => active.any((e) => e.kind == k);
    final cap = active
        .where((e) => e.kind == EffectKind.curse)
        .map((e) => e.count > 0 ? e.count : 4)
        .fold<int>(7, math.min);
    final head = has(EffectKind.headwind) && !has(EffectKind.tailwind);
    final tail = has(EffectKind.tailwind) && !has(EffectKind.headwind);
    return [
      for (final v in raw)
        if (has(EffectKind.halveDice) && v <= 3)
          math.min(6, v * 2)
        else if (cap < 6 && v == cap)
          cap + 1 + _rng.nextInt(6 - cap)
        else if (head && v < 6)
          v + 1
        else if (tail && v > 1)
          v - 1
        else
          v,
    ];
  }

  Future<void> _applyModifiers(List<int> raw, List<int> first) async {
    var changed = false;
    for (var i = 0; i < raw.length && i < _dice.length; i++) {
      if (first[i] != raw[i]) changed = true;
    }
    if (!changed) return;
    await Future<void>.delayed(Duration(milliseconds: (280 / _speed).round()));
    if (!isMounted) return;
    for (var i = 0; i < raw.length && i < _dice.length; i++) {
      final from = first[i];
      final to = raw[i];
      if (from == to) continue;
      final d = _dice[i]..value = to;
      final down = to < from;
      fx
        ..burst(
          d.pos,
          color: down ? const Color(0xFF7A3FB8) : const Color(0xFF7CF29A),
          count: 16,
          kind: ParticleKind.smoke,
          gravity: down ? 60 : -60,
          size: 5,
          life: 0.8,
        )
        ..popup(
          '${down ? '' : '+'}${to - from}',
          d.pos.translate(0, -layout.dieSize),
          color: down ? const Color(0xFFFF8A8A) : const Color(0xFF7CF29A),
          size: 20,
        );
    }
    Sfx.instance.play('magic', rate: 0.6);
  }

  Future<void> _shatterLast() async {
    await Future<void>.delayed(Duration(milliseconds: (220 / _speed).round()));
    if (!isMounted || _dice.length < 2) return;
    final d = _dice.removeLast();
    fx
      ..burst(d.pos, color: dieStyle.face, count: 28, speed: 260, size: 3.5)
      ..ring(d.pos, const Color(0xFFFF8A8A), size: layout.dieSize * 1.6);
    Sfx.instance
      ..play('hit', rate: 1.6)
      ..haptic(HapticKind.medium);
    debugShattered++;
  }

  void _cancelledDouble(Side side, int value) {
    final slots = _diceSlots(side, 4);
    _ghosts
      ..clear()
      ..add((value: value, pos: slots[0]))
      ..add((value: value, pos: slots[3]));
    for (final p in [slots[0], slots[3]]) {
      fx.burst(
        p,
        color: const Color(0xFFCFD8DC),
        count: 10,
        kind: ParticleKind.smoke,
        gravity: -10,
        size: 9,
        life: 1.4,
      );
    }
    fx.popup(
      _cfg.persianDigits ? 'جفت حساب نشد' : 'No doubles!',
      layout.diceCenter(side).translate(0, -layout.dieSize * 1.3),
      color: const Color(0xFFCFD8DC),
      size: 20,
    );
    Sfx.instance.play('card_whoosh', rate: 0.5);
  }

  /// Test hooks: ghost dice of a cancelled double; Broken Die shatters.
  @visibleForTesting
  int get debugGhostDice => _ghosts.length;
  @visibleForTesting
  int debugShattered = 0;

  /// A beat after a double lands, two twins split out of the landed dice.
  Future<void> _cloneDouble(Side side) async {
    await Future<void>.delayed(
      Duration(
        milliseconds: ((_cfg.reducedMotion ? 120 : 260) / _speed).round(),
      ),
    );
    if (!isMounted || _dice.length != 2) return;
    final slots = _diceSlots(side, 4);
    final a = _dice[0];
    final b = _dice[1];
    final twinA = _Die(a.value, a.pos)
      ..start = a.pos
      ..target = slots[0]
      ..tilt = -a.tilt
      ..angle = a.tilt
      ..scale = 0.4;
    final twinB = _Die(b.value, b.pos)
      ..start = b.pos
      ..target = slots[3]
      ..tilt = -b.tilt
      ..angle = b.tilt
      ..scale = 0.4;
    _dice
      ..clear()
      ..addAll([twinA, a, b, twinB]);
    Sfx.instance
      ..play('pop')
      ..play('magic', volume: 0.6)
      ..haptic(HapticKind.medium);
    final mid = Offset.lerp(a.pos, b.pos, 0.5)!;
    fx
      ..ring(mid, const Color(0xFFFFE9A8), size: layout.dieSize * 2.4)
      ..popup(
        _cfg.persianDigits ? 'جفت!' : 'Doubles!',
        mid.translate(0, -layout.dieSize * 1.3),
        size: 26,
      );
    for (final d in [a, b]) {
      fx.burst(d.pos, count: 14, speed: 150, size: 2.4, life: 0.45);
    }
    const dur = 0.24;
    final steps = math.max(1, (dur / _speed * 60).round());
    for (var i = 0; i < steps; i++) {
      await Future<void>.delayed(const Duration(milliseconds: 16));
      if (!isMounted) return;
      final t = (i + 1) / steps;
      final e = 1 - math.pow(1 - t, 3).toDouble();
      for (final d in [twinA, twinB]) {
        d
          ..pos = Offset.lerp(d.start, d.target, e)!
          ..scale = 0.4 + 0.6 * e
          ..angle = d.tilt + (1 - e) * 1.2;
      }
    }
    for (final d in [twinA, twinB]) {
      d
        ..pos = d.target
        ..scale = 1
        ..angle = d.tilt;
    }
  }

  /// 7–7s seen this session: after the first few the build-up is shorter.
  static int _sevensSeen = 0;

  /// Set by a tap during the 7–7 build-up to skip the rest of it.
  bool _skipSeven = false;
  bool _inSeven = false;

  /// Test hook: is the 7–7 cinematic running?
  @visibleForTesting
  bool get debugSevenCinematic => _inSeven;

  Future<void> _wait(double seconds) async {
    final ms = (seconds * 1000 / _speed).round();
    for (var t = 0; t < ms && !_skipSeven; t += 16) {
      await Future<void>.delayed(const Duration(milliseconds: 16));
      if (!isMounted) return;
    }
  }

  /// The Double Seven moment: a slow-motion throw, the dice hover, wobble
  /// and glow, then slam down with a burst of light, the fanfare, the
  /// environment flaring, a screen shake and a haptic pattern. ~2.7 s the
  /// first time; shorter later; a tap skips to the end.
  Future<void> _rollSeven(Side side) async {
    final fast = _sevensSeen >= 3 || _cfg.reducedMotion;
    _sevensSeen++;
    _skipSeven = false;
    _inSeven = true;
    try {
      final k = fast ? 0.6 : 1.0;
      final slots = _diceSlots(side, 2);
      _dice
        ..clear()
        ..addAll([
          for (final s in slots) _Die(7, _diceStart(side))..target = s,
        ]);
      await _tumble(_dice, 0.9 * k / _speed);
      if (!isMounted) return;
      // Hover: the dice rise, wobble and glow before the final landing.
      Sfx.instance.play('card_whoosh', rate: 1.5);
      Sfx.instance.haptic(HapticKind.light);
      final hoverMs = (700 * k / _speed).round();
      for (var t = 0; t < hoverMs && !_skipSeven; t += 16) {
        await Future<void>.delayed(const Duration(milliseconds: 16));
        if (!isMounted) return;
        final f = t / hoverMs;
        for (var i = 0; i < _dice.length; i++) {
          final d = _dice[i];
          d
            ..pos = d.target.translate(
              0,
              -layout.dieSize * 0.5 * math.sin(f * math.pi),
            )
            ..angle = d.tilt + math.sin(f * 30 + i) * 0.18 * (1 - f)
            ..t = 0.99;
        }
        if (t % 160 < 16) {
          for (final d in _dice) {
            fx.burst(d.pos, count: 4, speed: 60, gravity: -30, life: 0.5);
          }
        }
      }
      for (final d in _dice) {
        d
          ..pos = d.target
          ..angle = d.tilt
          ..t = 1;
      }
      // Slam.
      Sfx.instance
        ..play('seven_fanfare')
        ..play('hit', rate: 0.7, volume: 0.6)
        ..haptic(HapticKind.heavy);
      env.flare = 1;
      if (!_cfg.reducedMotion) _shake = 8;
      for (final d in _dice) {
        fx
          ..burst(d.pos, count: 50, speed: 360, gravity: 40)
          ..burst(d.pos, count: 16, kind: ParticleKind.star, gravity: -40)
          ..ring(d.pos, const Color(0xFFFFD36B), size: layout.dieSize * 2.4);
      }
      fx.flashScreen(const Color(0xFFFFD36B), strength: 0.55);
      unawaited(() async {
        await Future<void>.delayed(const Duration(milliseconds: 140));
        Sfx.instance.haptic(HapticKind.medium);
        await Future<void>.delayed(const Duration(milliseconds: 140));
        Sfx.instance.haptic(HapticKind.heavy);
      }());
      await _wait(0.9 * k);
    } finally {
      _inSeven = false;
      _skipSeven = false;
    }
  }

  void _syncDice(GameState s) {
    if (_diceAnimating) return;
    if (s.phase != Phase.moving) {
      if (s.phase == Phase.chooseDice && _dice.length != s.choiceDice.length) {
        final slots = _diceSlots(s.current, s.choiceDice.length);
        _dice
          ..clear()
          ..addAll([
            for (var i = 0; i < slots.length; i++)
              _Die(s.choiceDice[i], slots[i])..target = slots[i],
          ]);
      }
      return;
    }
    final values = [for (final m in s.movesThisRoll) m.die, ...s.dice];
    if (values.isEmpty) return;
    if (_dice.length != values.length) {
      // A different set of dice (resume, replay, a new roll seen without its
      // animation): lay it out once, in roll order.
      final slots = _diceSlots(s.current, values.length);
      final order = [...s.dice];
      for (final m in s.movesThisRoll) {
        order.insert(0, m.die);
      }
      _dice
        ..clear()
        ..addAll([
          for (var i = 0; i < order.length; i++)
            _Die(order[i], slots[i])..target = slots[i],
        ]);
    } else {
      // Same dice: faces, positions and order stay put. Only a deliberate
      // edit (Lucky Charm, Fate's Edit) changes the edited die's face.
      final remaining = List.of(values);
      final unmatched = <_Die>[];
      for (final d in _dice) {
        if (!remaining.remove(d.value)) unmatched.add(d);
      }
      for (var i = 0; i < unmatched.length && i < remaining.length; i++) {
        unmatched[i].value = remaining[i];
      }
    }
    // Used dice dim in place: match each played move to a die by value.
    for (final d in _dice) {
      d.used = false;
    }
    for (final m in s.movesThisRoll) {
      for (final d in _dice) {
        if (!d.used && d.value == m.die) {
          d.used = true;
          break;
        }
      }
    }
  }

  void _renderDicePreview(
    Canvas c,
    ({Side side, String label, Color color}) pd,
    double pulse,
  ) {
    final center = layout.diceCenter(pd.side);
    final sz = layout.dieSize;
    // Two ghost dice where the affected player's dice will land.
    for (final dx in [-0.56, 0.56]) {
      final r = RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: center.translate(dx * sz * 1.12, 0),
          width: sz,
          height: sz,
        ),
        Radius.circular(sz * 0.2),
      );
      c
        ..drawRRect(
          r,
          Paint()..color = pd.color.withValues(alpha: 0.12 + 0.1 * pulse),
        )
        ..drawRRect(
          r,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2
            ..color = pd.color.withValues(alpha: 0.5 + 0.4 * pulse),
        );
    }
    final para = _text.get('preview|${pd.label}|${sz.round()}', () {
      final pb =
          ui.ParagraphBuilder(
              ui.ParagraphStyle(textAlign: TextAlign.center, maxLines: 2),
            )
            ..pushStyle(
              ui.TextStyle(
                color: const Color(0xFFFFF4D6),
                fontSize: sz * 0.36,
                fontWeight: FontWeight.w700,
                shadows: const [ui.Shadow(blurRadius: 4)],
              ),
            )
            ..addText(pd.label);
      return pb.build()..layout(ui.ParagraphConstraints(width: sz * 5));
    });
    final above = pd.side != controller.localSide;
    c.drawParagraph(
      para,
      center.translate(-sz * 2.5, above ? sz * 0.75 : -sz * 0.75 - para.height),
    );
  }

  /// Test hook: dice as drawn, in order.
  @visibleForTesting
  List<({int value, Offset pos, bool used, bool landed})> debugDice() => [
    for (final d in _dice)
      (
        value: d.value,
        pos: d.pos,
        used: d.used,
        landed: d.t >= 1 && d.scale >= 1,
      ),
  ];

  // ---------------------------------------------------------------------------
  // Frame loop.

  @override
  void update(double dt) {
    super.update(dt);
    _time += dt;
    _shake = math.max(0, _shake - dt * 30);
    for (final c in _checkers) {
      c.update(dt, trailOn: chkStyle.trail);
    }
    if (theme.pattern == BoardPattern.ember &&
        !_cfg.reducedMotion &&
        _rng.nextDouble() < 0.15) {
      final b = layout.bar;
      fx.emit(
        Offset(b.left + _rng.nextDouble() * b.width, b.bottom),
        Offset((_rng.nextDouble() - 0.5) * 10, -30 - _rng.nextDouble() * 40),
        color: const Color(0xFFFF9E3D),
        kind: ParticleKind.ember,
        size: 1.2,
        life: 2.5,
      );
    }
    if (theme.pattern == BoardPattern.frost &&
        !_cfg.reducedMotion &&
        _rng.nextDouble() < 0.06) {
      final f = layout.field;
      fx.emit(
        Offset(
          f.left + _rng.nextDouble() * f.width,
          f.top + _rng.nextDouble() * f.height,
        ),
        Offset((_rng.nextDouble() - 0.5) * 8, -3),
        color: const Color(0x55FFFFFF),
        kind: ParticleKind.smoke,
        size: 10,
      );
    }
  }

  @override
  void render(Canvas canvas) {
    if (_shake > 0) {
      canvas.save();
      canvas.translate(
        (_rng.nextDouble() - 0.5) * _shake,
        (_rng.nextDouble() - 0.5) * _shake,
      );
      super.render(canvas);
      canvas.restore();
    } else {
      super.render(canvas);
    }
    fx.renderFlash(canvas, size.toSize());
  }

  void _renderScene(Canvas c) {
    final base = _basePic;
    if (base == null) return;
    c.drawPicture(base);
    if (_feltPic != null) {
      c.drawPicture(_feltPic!);
    } else {
      for (final half in [
        Rect.fromLTRB(
          layout.field.left,
          layout.field.top,
          layout.bar.left,
          layout.field.bottom,
        ),
        Rect.fromLTRB(
          layout.bar.right,
          layout.field.top,
          layout.field.right,
          layout.field.bottom,
        ),
      ]) {
        c.save();
        c.clipRect(half);
        Shaders.paintNebula(
          c,
          layout.field,
          _time,
          theme.nebulaA,
          theme.nebulaB,
          theme.nebulaC,
        );
        c.restore();
      }
    }
    if (theme.pattern == BoardPattern.caravanserai) _twinkle(c);
    final top = _topPic;
    if (top != null) c.drawPicture(top);
    if (theme.pattern == BoardPattern.neon) _neonPulse(c);
    _renderMarkers(c);
    _renderHighlights(c);
    _renderCheckers(c);
    _renderDice(c);
  }

  void _twinkle(Canvas c) {
    final rng = ArtRng(5);
    final f = layout.field;
    for (var i = 0; i < 24; i++) {
      final p = Offset(
        f.left + rng.next() * f.width,
        f.top + rng.next() * f.height,
      );
      final a = 0.5 + 0.5 * math.sin(_time * 2.5 + i * 1.7);
      c.drawCircle(
        p,
        1.4,
        Paint()..color = Color.fromRGBO(255, 230, 180, 0.7 * a),
      );
    }
  }

  void _neonPulse(Canvas c) {
    final a = 0.06 + 0.05 * math.sin(_time * 2);
    c.drawRect(layout.field, Paint()..color = theme.glow.withValues(alpha: a));
  }

  bool _canSeeMine(ActiveEffect e) {
    final owner = e.owner;
    if (!controller.isHuman(owner)) return false;
    if (controller.session.isPassAndPlay) return _shown?.current == owner;
    return true;
  }

  void _renderMarkers(Canvas c) {
    final s = _shown;
    if (s == null) return;
    for (final e in s.effects) {
      if (e.point == 0) continue;
      final r = layout.pointRect(e.point);
      final top = layout.isTop(e.point);
      final tip = top
          ? Offset(r.center.dx, r.bottom + layout.checkerR * 0.9)
          : Offset(r.center.dx, r.top - layout.checkerR * 0.9);
      final sz = layout.checkerR * 0.75;
      switch (e.kind) {
        case EffectKind.chains:
        case EffectKind.quicksandFreeze:
          final list = _stacks[PointSlot(e.point)] ?? const [];
          for (var i = 0; i < math.min(e.count, list.length); i++) {
            final p = list[i].pos;
            _chain(
              c,
              p,
              layout.checkerR,
              e.kind == EffectKind.chains
                  ? const Color(0xFFB0B8C8)
                  : const Color(0xFF8C6A48),
            );
          }
        case EffectKind.shield:
          final list = _stacks[PointSlot(e.point)] ?? const [];
          if (list.isEmpty) break;
          final p = list.last.pos;
          final pulse = 0.6 + 0.2 * math.sin(_time * 3);
          c.drawCircle(
            p,
            layout.checkerR * 1.25,
            Paint()
              ..color = Color.fromRGBO(120, 200, 255, 0.25 * pulse)
              ..maskFilter = MaskFilter.blur(
                BlurStyle.normal,
                layout.checkerR * 0.2,
              ),
          );
          c.drawCircle(
            p,
            layout.checkerR * 1.2,
            Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = 2
              ..color = Color.fromRGBO(160, 220, 255, pulse),
          );
        case EffectKind.ironGate:
          final list = _stacks[PointSlot(e.point)] ?? const [];
          if (list.isEmpty) break;
          final p = list.last.pos;
          final bars = Paint()
            ..color = const Color(0xFF9AA3AE)
            ..strokeWidth = 2.2;
          for (var k = -2; k <= 2; k++) {
            c.drawLine(
              p.translate(k * layout.checkerR * 0.4, -layout.checkerR * 1.1),
              p.translate(k * layout.checkerR * 0.4, layout.checkerR * 1.1),
              bars,
            );
          }
        case EffectKind.toll:
          _badge(c, tip, sz, const Color(0xFFD4AF37), 'T');
        case EffectKind.quicksand:
          _swirl(c, tip, sz, const Color(0xFF8C6A48));
        case EffectKind.landmine:
          if (_canSeeMine(e)) _mine(c, tip, sz);
        default:
          break;
      }
    }
  }

  void _chain(Canvas c, Offset p, double r, Color col) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = r * 0.16
      ..color = col;
    for (var k = -1; k <= 1; k++) {
      c.drawOval(
        Rect.fromCenter(
          center: p.translate(k * r * 0.55, 0),
          width: r * 0.7,
          height: r * 0.45,
        ),
        paint,
      );
    }
  }

  void _badge(Canvas c, Offset p, double r, Color col, String label) {
    c.drawCircle(p, r, Paint()..color = const Color(0xCC000000));
    c.drawCircle(
      p,
      r,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = col,
    );
    final para = _text.get(
      'badge|$label|${r.toStringAsFixed(1)}|${col.toARGB32()}',
      () {
        final pb =
            ui.ParagraphBuilder(
                ui.ParagraphStyle(textAlign: TextAlign.center, fontSize: r),
              )
              ..pushStyle(
                ui.TextStyle(
                  color: col,
                  fontSize: r * 1.1,
                  fontWeight: FontWeight.w700,
                ),
              )
              ..addText(label);
        return pb.build()..layout(ui.ParagraphConstraints(width: r * 2));
      },
    );
    c.drawParagraph(para, p.translate(-r, -para.height / 2));
  }

  void _swirl(Canvas c, Offset p, double r, Color col) {
    final path = Path();
    for (var i = 0; i <= 40; i++) {
      final a = i / 40 * math.pi * 4 + _time;
      final rr = r * i / 40;
      final pt = p + Offset(math.cos(a), math.sin(a)) * rr;
      if (i == 0) {
        path.moveTo(pt.dx, pt.dy);
      } else {
        path.lineTo(pt.dx, pt.dy);
      }
    }
    c.drawCircle(p, r, Paint()..color = const Color(0x88000000));
    c.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = col,
    );
  }

  void _mine(Canvas c, Offset p, double r) {
    c.drawCircle(p, r * 0.7, Paint()..color = const Color(0xFF2A2A2A));
    final spike = Paint()
      ..color = const Color(0xFF2A2A2A)
      ..strokeWidth = r * 0.18;
    for (var i = 0; i < 8; i++) {
      final a = i * math.pi / 4;
      c.drawLine(p, p + Offset(math.cos(a), math.sin(a)) * r, spike);
    }
    final blink = (math.sin(_time * 5) > 0) ? 1.0 : 0.3;
    c.drawCircle(
      p.translate(-r * 0.2, -r * 0.2),
      r * 0.18,
      Paint()..color = Color.fromRGBO(255, 60, 60, blink),
    );
  }

  Color get _hi => _cfg.colorblind ? const Color(0xFF3DA5FF) : theme.highlight;

  void _renderHighlights(Canvas c) {
    final s = _shown;
    if (s == null) return;
    final pulse = 0.55 + 0.35 * math.sin(_time * 5);
    // Dim the board so only valid targets / previewed points stand out.
    if (targetable.isNotEmpty || previewPoints.isNotEmpty) {
      c.drawRect(layout.field, Paint()..color = const Color(0x66000000));
    }
    if (previewPoints.isNotEmpty) {
      for (final abs in previewPoints) {
        final r = abs == 0 ? layout.bar : layout.pointHitRect(abs);
        c
          ..drawRect(
            r,
            Paint()
              ..color = const Color(0xFF7FE3F0)
                  .withValues(alpha: 0.12 + 0.12 * pulse),
          )
          ..drawRect(
            r.deflate(1),
            Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = 2
              ..color = const Color(0xFF7FE3F0).withValues(alpha: pulse),
          );
      }
    }
    final pd = previewDice;
    if (pd != null) _renderDicePreview(c, pd, pulse);
    // Targeting.
    if (targetable.isNotEmpty) {
      for (final abs in targetable) {
        final r = abs == 0 ? layout.bar : layout.pointHitRect(abs);
        c.drawRect(
          r,
          Paint()
            ..color = const Color(0xFFFFD36B)
                .withValues(alpha: 0.12 + 0.1 * pulse),
        );
        c.drawRect(
          r.deflate(1),
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2
            ..color = const Color(0xFFFFD36B).withValues(alpha: pulse),
        );
      }
      for (final abs in targetChosen) {
        final r = abs == 0 ? layout.bar : layout.pointHitRect(abs);
        c.drawRect(
          r,
          Paint()..color = const Color(0xFFFF6B6B).withValues(alpha: 0.3),
        );
      }
      return;
    }
    if (!controller.waitingForHuman || s.phase != Phase.moving) return;
    final legal = _legal(controller.state);
    if (legal.isEmpty) return;
    final side = s.current;
    if (selectedFrom == null && _dragChk == null) {
      // Hint which checkers can move.
      final sources = {for (final m in legal) m.from};
      for (final from in sources) {
        final slot = _slotFor(side, from);
        final list = _stacks[slot];
        if (list == null || list.isEmpty) continue;
        final p = list.last.pos;
        c.drawCircle(
          p,
          layout.checkerR * 1.12,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.6
            ..color = _hi.withValues(alpha: 0.35 + 0.25 * pulse),
        );
      }
      return;
    }
    final from = selectedFrom ?? _dragFrom;
    for (final m in legal.where((m) => m.from == from)) {
      if (m.to == Pos.off) {
        final tray = side == Side.white ? layout.whiteTray : layout.blackTray;
        c.drawRRect(
          RRect.fromRectAndRadius(tray, const Radius.circular(6)),
          Paint()..color = _hi.withValues(alpha: 0.25 + 0.2 * pulse),
        );
        continue;
      }
      final abs = toAbsolute(side, m.to);
      final r = layout.pointRect(abs);
      final n =
          _stacks[PointSlot(abs)]?.where((x) => x.side == side).length ?? 0;
      final p = layout.checkerCenter(PointSlot(abs), n, n + 1);
      c.drawRect(r, Paint()..color = _hi.withValues(alpha: 0.12 + 0.1 * pulse));
      c.drawCircle(
        p,
        layout.checkerR * 0.95,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5
          ..color = _hi.withValues(alpha: 0.6 + 0.3 * pulse),
      );
      if (_cfg.colorblind || _cfg.highContrast) {
        // Shape cue in addition to colour: a centre dot.
        c.drawCircle(p, layout.checkerR * 0.22, Paint()..color = _hi);
      }
      if (m.hit) {
        c.drawCircle(
          p,
          layout.checkerR * 1.15,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2
            ..color = const Color(0xFFFF6B6B).withValues(alpha: pulse),
        );
      }
    }
  }

  /// Paint order: resting checkers stack by stack in index order (index 0
  /// at the bottom), then every travelling or dragged checker, the most
  /// recently started on top. Recomputed every frame from the stacks, so
  /// moves, hits, bar entries and undo can never leave a stale order.
  List<_Chk> _paintOrder() {
    final rest = <_Chk>[];
    final top = <_Chk>[];
    final seen = <_Chk>{};
    for (final list in _stacks.values) {
      for (final c in list) {
        seen.add(c);
        (c.onTop ? top : rest).add(c);
      }
    }
    for (final c in _checkers) {
      if (!seen.contains(c)) (c.onTop ? top : rest).add(c);
    }
    top.sort((a, b) => a.travelStamp.compareTo(b.travelStamp));
    return rest..addAll(top);
  }

  /// Awaited before each presented event; lets the UI pause the game.
  Future<void> Function(GameEvent e)? eventGate;

  /// Board point (absolute) or a side's dice area, in game coordinates.
  Offset anchorFor({int point = 0, Side? side}) {
    if (point > 0) {
      final ps = checkerPositionsAt(point);
      return ps.isNotEmpty ? ps.last : layout.pointRect(point).center;
    }
    return layout.diceCenter(side ?? Side.white);
  }

  /// Test hooks around every presented event.
  @visibleForTesting
  static void Function(GameEvent e)? debugBeforeEvent;
  @visibleForTesting
  static void Function(GameEvent e)? debugAfterEvent;

  /// Test hook: every checker by identity.
  @visibleForTesting
  List<({int id, Slot slot, int index, Offset pos, bool moving, bool onTop})>
  debugCheckers() => [
    for (var i = 0; i < _checkers.length; i++)
      (
        id: i,
        slot: _checkers[i].slot,
        index: _stacks[_checkers[i].slot]?.indexOf(_checkers[i]) ?? -1,
        pos: _checkers[i].pos,
        moving: _checkers[i].moving,
        onTop: _checkers[i].onTop,
      ),
  ];

  /// Test hook: what is painted, bottom to top.
  @visibleForTesting
  List<({Side side, Slot slot, int index, bool onTop})> debugPaintOrder() => [
    for (final c in _paintOrder())
      (
        side: c.side,
        slot: c.slot,
        index: _stacks[c.slot]?.indexOf(c) ?? -1,
        onTop: c.onTop,
      ),
  ];

  void _renderCheckers(Canvas c) {
    final ordered = _paintOrder();
    final s = _shown;
    final selSlot = s == null || selectedFrom == null
        ? null
        : _slotFor(s.current, selectedFrom!);
    for (final ch in ordered) {
      if (ch.pos == Offset.zero) continue;
      if (ch.slot is OffSlot && !ch.moving) {
        final list = _stacks[ch.slot]!;
        final idx = list.indexOf(ch);
        final slab = layout.offSlab(ch.side);
        final p = layout.checkerCenter(ch.slot, idx < 0 ? 0 : idx, list.length);
        final tray = ch.side == Side.white
            ? layout.whiteTray
            : layout.blackTray;
        paintCheckerSlab(
          c,
          Rect.fromCenter(
            center: p,
            width: tray.width * 0.82,
            height: slab * 0.85,
          ),
          ch.side,
          chkStyle,
        );
        continue;
      }
      if (chkStyle.trail && ch.trail.length > 1) {
        for (var i = 0; i < ch.trail.length; i++) {
          c.drawCircle(
            ch.trail[i],
            layout.checkerR * (0.3 + 0.6 * i / ch.trail.length),
            Paint()
              ..color = chkStyle.lightEdge.withValues(
                alpha: 0.25 * i / ch.trail.length,
              ),
          );
        }
      }
      final img = _checkerImage(ch.side);
      final selected =
          selSlot != null &&
          ch.slot == selSlot &&
          (_stacks[selSlot]?.isNotEmpty ?? false) &&
          _stacks[selSlot]!.last == ch;
      c.save();
      c.translate(ch.pos.dx, ch.pos.dy);
      if (ch.lift > 0) {
        c.drawCircle(
          Offset(ch.lift * 0.2, ch.lift * 0.6 + layout.checkerR * 0.2),
          layout.checkerR * 0.95,
          Paint()
            ..color = const Color(0x55000000)
            ..maskFilter = MaskFilter.blur(
              BlurStyle.normal,
              4 + ch.lift * 0.15,
            ),
        );
        final sc = 1 + ch.lift / 300;
        c.scale(sc, sc);
      }
      if (ch.squash != 1) c.scale(1 / math.sqrt(ch.squash), ch.squash);
      if (selected) {
        c.drawCircle(
          Offset.zero,
          layout.checkerR * 1.3,
          Paint()
            ..color = theme.glow.withValues(alpha: 0.7)
            ..maskFilter = MaskFilter.blur(
              BlurStyle.normal,
              layout.checkerR * 0.4,
            ),
        );
      }
      c.drawImage(
        img,
        Offset(-img.width / 2, -img.height / 2),
        Paint()..filterQuality = FilterQuality.medium,
      );
      if (chkStyle.material == CheckerMaterial.neon) {
        c.drawCircle(
          Offset.zero,
          layout.checkerR * 0.8,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.5
            ..color = chkStyle
                .base(ch.side)
                .withValues(alpha: 0.3 + 0.3 * math.sin(_time * 3)),
        );
      }
      c.restore();
    }
    // Stack counts for tall stacks.
    for (final e in _stacks.entries) {
      final n = e.value.length;
      if (n <= 5 || e.key is OffSlot) continue;
      final p = e.value.last.pos;
      final side = e.value.last.side;
      final para = _text.get(
        'stack|$n|${side.name}|${layout.checkerR.toStringAsFixed(1)}',
        () {
          final pb =
              ui.ParagraphBuilder(
                  ui.ParagraphStyle(
                    textAlign: TextAlign.center,
                    fontSize: layout.checkerR,
                  ),
                )
                ..pushStyle(
                  ui.TextStyle(
                    color: e.value.last.side == Side.white
                        ? const Color(0xFF2A1A12)
                        : const Color(0xFFF3E9D2),
                    fontSize: layout.checkerR * 0.9,
                    fontWeight: FontWeight.w700,
                  ),
                )
                ..addText(boardDigits(n, persian: _cfg.persianDigits));
          return pb.build()
            ..layout(ui.ParagraphConstraints(width: layout.checkerR * 2));
        },
      );
      c.drawParagraph(para, p.translate(-layout.checkerR, -para.height / 2));
    }
  }

  void _renderDice(Canvas c) {
    final s = _shown;
    final sz = layout.dieSize;
    for (final g in _ghosts) {
      c.saveLayer(
        Rect.fromCircle(center: g.pos, radius: sz),
        Paint()..color = const Color(0x66000000),
      );
      paintDie(c, g.pos, sz, g.value, dieStyle);
      c.restore();
      final x = Paint()
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round
        ..color = const Color(0xCCFF6B6B);
      c
        ..drawLine(
          g.pos.translate(-sz * 0.4, -sz * 0.4),
          g.pos.translate(sz * 0.4, sz * 0.4),
          x,
        )
        ..drawLine(
          g.pos.translate(sz * 0.4, -sz * 0.4),
          g.pos.translate(-sz * 0.4, sz * 0.4),
          x,
        );
    }
    for (final d in _dice) {
      paintDie(
        c,
        d.pos,
        sz * d.scale,
        d.value,
        dieStyle,
        angle: d.angle,
        used: d.used,
        time: _time,
        lift: d.t < 1 ? 10 : 0,
        blur: d.blur,
      );
    }
    if (s == null || !controller.waitingForHuman) return;
    if (s.phase == Phase.preRoll || s.phase == Phase.opening) {
      final side = s.phase == Phase.opening ? controller.localSide : s.current;
      final slots = _diceSlots(side, 2);
      final pulse = 0.5 + 0.5 * math.sin(_time * 4);
      for (var i = 0; i < 2; i++) {
        c.drawCircle(
          slots[i],
          sz * (0.85 + 0.08 * pulse),
          Paint()
            ..color = theme.glow.withValues(alpha: 0.18 + 0.12 * pulse)
            ..maskFilter = MaskFilter.blur(BlurStyle.normal, sz * 0.3),
        );
        paintDie(
          c,
          slots[i],
          sz,
          i == 0 ? 5 : 2,
          dieStyle,
          angle: math.sin(_time * 2 + i) * 0.12,
        );
      }
    }
  }

  // ---------------------------------------------------------------------------
  // Input.

  Rect _diceArea(Side side) {
    final c = layout.diceCenter(side);
    return Rect.fromCenter(
      center: c,
      width: layout.dieSize * 4.5,
      height: layout.dieSize * 2.4,
    );
  }

  /// Tapping a frozen checker: it shakes, clinks, and says for how long.
  bool _frozenFeedback(GameState s, Side side, int abs) {
    final ice = s.effects.where(
      (e) =>
          (e.kind == EffectKind.chains ||
              e.kind == EffectKind.quicksandFreeze) &&
          e.affected == side &&
          e.point == abs,
    );
    if (ice.isEmpty) return false;
    final list = _stacks[PointSlot(abs)];
    if (list == null || list.isEmpty) return false;
    final c = list.last;
    final home = c.pos;
    unawaited(() async {
      for (var i = 0; i < 6 && isMounted; i++) {
        c.pos = home.translate(i.isEven ? 4 : -4, 0);
        await Future<void>.delayed(const Duration(milliseconds: 35));
      }
      c.pos = home;
    }());
    final turns = ice.first.turnsLeft;
    final n = _cfg.persianDigits
        ? turns
              .toString()
              .split('')
              .map((d) => '۰۱۲۳۴۵۶۷۸۹'[int.parse(d)])
              .join()
        : '$turns';
    fx.popup(
      _cfg.persianDigits ? 'یخ زده — $n نوبت' : 'Frozen — $n turns',
      home.translate(0, -layout.checkerR * 1.6),
      color: const Color(0xFF9FE8FF),
      size: 18,
    );
    Sfx.instance
      ..play('card_flip', rate: 1.6)
      ..haptic(HapticKind.light);
    debugFrozenTaps++;
    return true;
  }

  @visibleForTesting
  int debugFrozenTaps = 0;

  void handleTap(Offset p) {
    if (_inSeven) {
      _skipSeven = true;
      return;
    }
    final s = controller.state;
    if (targetable.isNotEmpty) {
      final hit = layout.hitTest(p);
      if (hit != null && hit >= 0 && targetable.contains(hit)) {
        Sfx.instance.play('ui_tick');
        onTargetTap?.call(hit);
      }
      return;
    }
    if (!controller.waitingForHuman) return;
    if (s.phase == Phase.preRoll || s.phase == Phase.opening) {
      final side = s.phase == Phase.opening ? controller.localSide : s.current;
      if (_diceArea(side).contains(p) || layout.field.contains(p)) {
        unawaited(
          controller.act(
            s.phase == Phase.opening ? const RollOpening() : const RollDice(),
          ),
        );
      }
      return;
    }
    if (s.phase != Phase.moving) return;
    final legal = _legal(s);
    final side = s.current;
    final hit = layout.hitTest(p);
    if (hit == null) {
      selectedFrom = null;
      return;
    }
    if (selectedFrom == null && hit > 0 && _frozenFeedback(s, side, hit)) {
      return;
    }
    // Destination for the current selection?
    if (selectedFrom != null) {
      final dests = legal.where((m) => m.from == selectedFrom).toList();
      Move? chosen;
      if (hit == -1) {
        chosen = dests.where((m) => m.to == Pos.off).firstOrNull;
      } else if (hit > 0) {
        final rel = toRelative(side, hit);
        if (rel == selectedFrom) {
          // Tapping the source again plays the largest die.
          dests.sort((a, b) => b.die.compareTo(a.die));
          chosen = dests.firstOrNull;
        } else {
          chosen = dests.where((m) => m.to == rel).firstOrNull;
        }
      }
      if (chosen != null) {
        selectedFrom = null;
        unawaited(controller.act(PlayMove(chosen)));
        return;
      }
    }
    // Select a source.
    final rel = hit == 0 ? Pos.bar : (hit > 0 ? toRelative(side, hit) : null);
    if (rel != null && legal.any((m) => m.from == rel)) {
      selectedFrom = rel;
      Sfx.instance.play('ui_tick', volume: 0.6);
      Sfx.instance.haptic(HapticKind.light);
    } else {
      selectedFrom = null;
    }
  }

  void handleDragStart(Offset p) {
    final s = controller.state;
    if (!controller.waitingForHuman ||
        s.phase != Phase.moving ||
        targetable.isNotEmpty) {
      return;
    }
    final hit = layout.hitTest(p);
    if (hit == null || hit < 0) return;
    final side = s.current;
    final rel = hit == 0 ? Pos.bar : toRelative(side, hit);
    if (!_legal(s).any((m) => m.from == rel)) return;
    final list = _stacks[_slotFor(side, rel)];
    if (list == null || list.isEmpty) return;
    final c = list.last;
    _dragChk = c
      ..dragging = true
      ..travelStamp = ++_travelSeq;
    _dragFrom = rel;
    _dragOffset = c.pos - p;
    c.lift = 14;
  }

  void handleDragUpdate(Offset p) {
    final c = _dragChk;
    if (c == null) return;
    c.pos = p + _dragOffset + const Offset(0, -10);
  }

  void handleDragEnd(Offset p) {
    final c = _dragChk;
    final from = _dragFrom;
    _dragChk = null;
    _dragFrom = null;
    if (c == null || from == null) return;
    c
      ..dragging = false
      ..lift = 0;
    final s = controller.state;
    final side = s.current;
    final hit = layout.hitTest(c.pos);
    Move? chosen;
    final legal = _legal(s).where((m) => m.from == from);
    if (hit == -1) {
      chosen = legal.where((m) => m.to == Pos.off).firstOrNull;
    } else if (hit != null && hit > 0) {
      final rel = toRelative(side, hit);
      chosen = legal.where((m) => m.to == rel).firstOrNull;
    }
    if (chosen != null) {
      selectedFrom = null;
      unawaited(controller.act(PlayMove(chosen)));
    } else {
      _relayout(c.slot);
      final list = _stacks[c.slot]!;
      final idx = list.indexOf(c);
      unawaited(
        c.glide(
          layout.checkerCenter(c.slot, idx, list.length),
          0.18,
          travel: true,
        ),
      );
      if (hit != null && hit > 0 && toRelative(side, hit) == from) {
        selectedFrom = from;
      }
    }
  }

  /// Name for a die value used in accessibility labels.
  static String cardName(String id, String lang) => cardById(id).name(lang);
}

class _SceneLayer extends Component {
  _SceneLayer(this.game);
  final BoardGame game;
  @override
  void render(Canvas canvas) => game._renderScene(canvas);
}

class _InputLayer extends PositionComponent with TapCallbacks, DragCallbacks {
  _InputLayer(this.game);
  final BoardGame game;

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    this.size = size;
  }

  @override
  bool containsLocalPoint(Vector2 point) => true;

  @override
  void onTapUp(TapUpEvent event) =>
      game.handleTap(event.localPosition.toOffset());

  @override
  void onDragStart(DragStartEvent event) {
    super.onDragStart(event);
    game.handleDragStart(event.localPosition.toOffset());
  }

  @override
  void onDragUpdate(DragUpdateEvent event) =>
      game.handleDragUpdate(event.localEndPosition.toOffset());

  @override
  void onDragEnd(DragEndEvent event) {
    super.onDragEnd(event);
    final c = game._dragChk;
    game.handleDragEnd(c?.pos ?? Offset.zero);
  }
}
