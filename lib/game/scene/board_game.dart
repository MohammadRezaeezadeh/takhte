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
import 'package:haftnard/game/themes/board_themes.dart';
import 'package:haftnard/game/themes/pieces.dart';

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

  bool get moving => _t < 1 || dragging;

  Future<void> glide(Offset to, double dur, {double arc = 0}) {
    _done?.complete();
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
  int value;
  Offset pos;
  Offset target = Offset.zero;
  Offset start = Offset.zero;
  double angle = 0;
  double spin = 0;
  bool used = false;
  double t = 1;
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
  late ui.Picture _topPic;
  final Map<String, ui.Image> _chkCache = {};

  late final FxLayer fx;
  late final EnvironmentLayer env;
  final List<_Chk> _checkers = [];
  final Map<Slot, List<_Chk>> _stacks = {};
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

  /// The opponent's most recent moves (absolute from/to, 0 = bar, -1 = off),
  /// shown as faint ghosts so the player can follow what happened.
  final List<(int, int)> _lastMoves = [];
  Side? _lastMover;

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

  SceneConfig get config => _cfg;
  double get _speed => _cfg.animSpeed.clamp(0.5, 2.0);

  @override
  Color backgroundColor() => const Color(0xFF0B0F1F);

  @override
  Future<void> onLoad() async {
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

    _basePic = rec(art.paintBase);
    _feltPic = theme.pattern == BoardPattern.cosmic ? null : rec(art.paintFelt);
    _topPic = rec(art.paintTop);
    _chkCache.clear();
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
  @override
  void resync(GameState s, {bool animate = true}) {
    _shown = s;
    if (!isLoaded) return;
    final targets = _targetCounts(s);
    _stacks.clear();
    final pool = {
      for (final side in Side.values)
        side: _checkers.where((c) => c.side == side).toList(),
    };
    // Keep checkers that are already in a correct slot where possible.
    final assigned = <_Chk>{};
    for (final e in targets.entries) {
      final side = _slotSide(e.key, s);
      final list = <_Chk>[];
      for (final c in pool[side]!) {
        if (list.length >= e.value) break;
        if (c.slot == e.key && !assigned.contains(c)) {
          list.add(c);
          assigned.add(c);
        }
      }
      _stacks[e.key] = list;
    }
    for (final e in targets.entries) {
      final side = _slotSide(e.key, s);
      final list = _stacks[e.key]!;
      for (final c in pool[side]!) {
        if (list.length >= e.value) break;
        if (!assigned.contains(c)) {
          list.add(c);
          assigned.add(c);
          c.slot = e.key;
        }
      }
    }
    for (final e in _stacks.entries) {
      _relayout(e.key, animate: animate);
    }
    _syncDice(s);
  }

  void _relayout(Slot slot, {bool animate = true}) {
    final list = _stacks[slot] ?? const [];
    for (var i = 0; i < list.length; i++) {
      final c = list[i];
      if (c.dragging) continue;
      final p = layout.checkerCenter(slot, i, list.length);
      if (!animate || c.pos == Offset.zero) {
        c.pos = p;
      } else if ((c.pos - p).distance > 0.5 && !c.moving) {
        unawaited(c.glide(p, 0.16 / _speed));
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
    c.slot = to;
    final target = layout.checkerCenter(to, list.length - 1, list.length);
    final dist = (c.pos - target).distance;
    final arcH = _cfg.reducedMotion ? 0.0 : math.min(60, dist * 0.25) * arc;
    await c.glide(
      target,
      (dur * (0.7 + math.min(dist, 400) / 900)) / _speed,
      arc: arcH,
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
      switch (e) {
        case OpeningRolled():
          await _rollOpening(e.white, e.black);
          lastMoveOff = false;
        case DiceRolled():
          await _rollDice(e.side, e.dice);
        case SevenRolled():
          await _rollSeven(e.side);
        case MovePlayed(:final side, :final move):
          if (_lastMover != side) {
            _lastMoves.clear();
            _lastMover = side;
          }
          if (!controller.isHuman(side) || controller.session.isPassAndPlay) {
            _lastMoves.add((
              move.from == Pos.bar ? 0 : toAbsolute(side, move.from),
              move.to == Pos.off ? -1 : toAbsolute(side, move.to),
            ));
          }
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
          _dice.clear();
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
    }
    // Reconcile anything not explicitly animated (Blood Pact, resyncs).
    resync(after);
    env.mood = _mood(after);
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

  Future<void> _tumble(List<_Die> live, double dur) async {
    // Work on a snapshot: a resync may replace the live list mid-animation.
    final dice = List<_Die>.of(live);
    for (final d in dice) {
      d.start = d.pos;
      d.t = 0;
      d.spin = (_rng.nextDouble() - 0.5) * 18;
    }
    Sfx.instance.play('dice_roll');
    final steps = (dur * 60).round();
    final finals = [for (final d in dice) d.value];
    for (var i = 0; i < steps; i++) {
      await Future<void>.delayed(const Duration(milliseconds: 16));
      if (!isMounted) return;
      final t = (i + 1) / steps;
      for (var k = 0; k < dice.length; k++) {
        final d = dice[k];
        d.t = t;
        final e = 1 - math.pow(1 - t, 3).toDouble();
        final bounce =
            (math.sin(t * math.pi * 3) * (1 - t)).abs() * layout.dieSize * 0.6;
        d.pos = Offset.lerp(d.start, d.target, e)!.translate(0, -bounce);
        d.angle += d.spin * (1 - t) / 60;
        if (t < 0.8 && i % 4 == 0) d.value = _rng.nextInt(6) + 1;
      }
    }
    for (var k = 0; k < dice.length; k++) {
      dice[k]
        ..value = finals[k]
        ..pos = dice[k].target
        ..t = 1;
    }
    Sfx.instance.play('dice_land');
    Sfx.instance.haptic(HapticKind.light);
  }

  List<Offset> _diceSlots(Side side, int n) {
    final c = layout.diceCenter(side);
    final s = layout.dieSize * (n > 2 ? 1.05 : 1.25);
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
    await _tumble(_dice, (_cfg.reducedMotion ? 0.3 : 0.6) / _speed);
    await Future<void>.delayed(Duration(milliseconds: (500 / _speed).round()));
  }

  Future<void> _rollDice(Side side, List<int> raw) async {
    final shown = raw.length == 2 && raw[0] == raw[1]
        ? [raw[0], raw[0], raw[0], raw[0]]
        : raw;
    final slots = _diceSlots(side, shown.length);
    _dice
      ..clear()
      ..addAll([
        for (var i = 0; i < shown.length; i++)
          _Die(shown[i], _diceStart(side))..target = slots[i],
      ]);
    await _tumble(_dice, (_cfg.reducedMotion ? 0.25 : 0.55) / _speed);
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

  Future<void> _rollSeven(Side side) async {
    final slots = _diceSlots(side, 2);
    _dice
      ..clear()
      ..addAll([for (final s in slots) _Die(7, _diceStart(side))..target = s]);
    await _tumble(_dice, 0.7 / _speed);
    for (final d in _dice) {
      d.value = 7;
    }
    Sfx.instance.play('seven_fanfare');
    Sfx.instance.haptic(HapticKind.heavy);
    env.flare = 1;
    if (!_cfg.reducedMotion) _shake = 6;
    for (final d in _dice) {
      fx
        ..burst(d.pos, count: 40, speed: 320, gravity: 40)
        ..ring(d.pos, const Color(0xFFFFD36B), size: layout.dieSize * 2);
    }
    fx.flashScreen(const Color(0xFFFFD36B), strength: 0.45);
    await Future<void>.delayed(Duration(milliseconds: (900 / _speed).round()));
  }

  void _syncDice(GameState s) {
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
    final usedCount = s.movesThisRoll.length;
    if (values.isEmpty) return;
    final slots = _diceSlots(s.current, values.length);
    if (_dice.length != values.length) {
      _dice
        ..clear()
        ..addAll([
          for (var i = 0; i < values.length; i++)
            _Die(values[i], slots[i])..target = slots[i],
        ]);
    }
    for (var i = 0; i < values.length; i++) {
      _dice[i]
        ..value = values[i]
        ..used = i < usedCount
        ..target = slots[i];
      if (_dice[i].t >= 1) _dice[i].pos = slots[i];
    }
  }

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
    c.drawPicture(_topPic);
    if (theme.pattern == BoardPattern.neon) _neonPulse(c);
    _renderMarkers(c);
    _renderLastMoves(c);
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
    final para = pb.build()..layout(ui.ParagraphConstraints(width: r * 2));
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

  void _renderLastMoves(Canvas c) {
    final s = _shown;
    if (_lastMoves.isEmpty || s == null || _lastMover == null) return;
    // Hide once the mover's opponent starts acting.
    if (s.current != _lastMover && s.movesThisRoll.isNotEmpty) return;
    final r = layout.checkerR;
    final ghost = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..color = const Color(0x88FFFFFF);
    final line = Paint()
      ..strokeWidth = 1.4
      ..color = const Color(0x55FFFFFF);
    for (final (from, to) in _lastMoves) {
      final a = from == 0
          ? layout.bar.center
          : layout.checkerCenter(
              PointSlot(from),
              s.board.atAbsolute(from).$2,
              s.board.atAbsolute(from).$2 + 1,
            );
      final b = to == -1
          ? (_lastMover == Side.white
                ? layout.whiteTray.center
                : layout.blackTray.center)
          : layout.pointRect(to).center;
      c.drawCircle(a, r * 0.8, ghost);
      // Dashed connector.
      final d = b - a;
      final len = d.distance;
      if (len < 1) continue;
      final dir = d / len;
      for (var t = r; t < len - r; t += 10) {
        c.drawLine(a + dir * t, a + dir * math.min(t + 5, len - r), line);
      }
    }
  }

  Color get _hi => _cfg.colorblind ? const Color(0xFF3DA5FF) : theme.highlight;

  void _renderHighlights(Canvas c) {
    final s = _shown;
    if (s == null) return;
    final pulse = 0.55 + 0.35 * math.sin(_time * 5);
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

  void _renderCheckers(Canvas c) {
    final ordered = [..._checkers]
      ..sort((a, b) {
        final am = a.moving ? 1 : 0;
        final bm = b.moving ? 1 : 0;
        return am.compareTo(bm);
      });
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
      final para = pb.build()
        ..layout(ui.ParagraphConstraints(width: layout.checkerR * 2));
      c.drawParagraph(para, p.translate(-layout.checkerR, -para.height / 2));
    }
  }

  void _renderDice(Canvas c) {
    final s = _shown;
    final sz = layout.dieSize;
    for (final d in _dice) {
      paintDie(
        c,
        d.pos,
        sz,
        d.value,
        dieStyle,
        angle: d.angle * (d.t < 1 ? 1 : 0.15),
        used: d.used,
        time: _time,
        lift: d.t < 1 ? 10 : 0,
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

  void handleTap(Offset p) {
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
    _dragChk = c..dragging = true;
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
      unawaited(c.glide(layout.checkerCenter(c.slot, idx, list.length), 0.18));
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
