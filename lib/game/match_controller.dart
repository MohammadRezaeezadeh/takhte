import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:haftnard/core/ai/ai.dart';
import 'package:haftnard/core/ai/personality.dart';
import 'package:haftnard/core/opponent.dart';
import 'package:haftnard/core/rules/actions.dart';
import 'package:haftnard/core/rules/engine.dart';
import 'package:haftnard/core/rules/events.dart';
import 'package:haftnard/core/rules/match.dart';
import 'package:haftnard/core/rules/move_gen.dart';
import 'package:haftnard/core/rules/record.dart';
import 'package:haftnard/core/rules/state.dart';
import 'package:haftnard/core/rules/types.dart';

/// Serializable description of who sits on a side.
class SeatConfig {
  const SeatConfig.human(this.name)
    : ai = false,
      personalityId = null,
      difficulty = null;

  const SeatConfig.ai({
    required this.personalityId,
    required this.difficulty,
    this.name = '',
  }) : ai = true;

  factory SeatConfig.fromJson(Map<String, Object?> j) => j['ai'] == true
      ? SeatConfig.ai(
          personalityId: j['p']! as String,
          difficulty: Difficulty.values.byName(j['d']! as String),
          name: j['n'] as String? ?? '',
        )
      : SeatConfig.human(j['n'] as String? ?? '');

  final bool ai;
  final String name;
  final String? personalityId;
  final Difficulty? difficulty;

  AiPersonality? get personality =>
      personalityId == null ? null : personalityById(personalityId!);

  Map<String, Object?> toJson() => {
    'ai': ai,
    'n': name,
    if (personalityId != null) 'p': personalityId,
    if (difficulty != null) 'd': difficulty!.name,
  };
}

/// A match plus who plays it and where it came from (quick play / journey).
class MatchSession {
  MatchSession({
    required this.match,
    required this.white,
    required this.black,
    this.origin = 'quick',
  });

  factory MatchSession.fromJson(Map<String, Object?> j) => MatchSession(
    match: MatchState.fromJson((j['match']! as Map).cast()),
    white: SeatConfig.fromJson((j['white']! as Map).cast()),
    black: SeatConfig.fromJson((j['black']! as Map).cast()),
    origin: j['origin'] as String? ?? 'quick',
  );

  final MatchState match;
  final SeatConfig white;
  final SeatConfig black;

  /// 'quick', 'passplay', 'journey', 'tutorial'.
  final String origin;

  SeatConfig seat(Side s) => s == Side.white ? white : black;

  bool get isPassAndPlay => !white.ai && !black.ai;

  Map<String, Object?> toJson() => {
    'match': match.toJson(),
    'white': white.toJson(),
    'black': black.toJson(),
    'origin': origin,
  };
}

/// Presentation hook implemented by the board scene.
abstract interface class MatchPresenter {
  /// Animates the transition; completes when the animation is done.
  Future<void> present(GameState before, GameState after, List<GameEvent> e);

  /// Snaps (or quickly glides) to [state] without event animations.
  void resync(GameState state);
}

/// Drives a match: applies actions, runs AI turns, supports undo for the
/// current roll, auto-passes and auto-plays forced moves.
class MatchController extends ChangeNotifier {
  MatchController(
    this.session, {
    this.autoMove = true,
    this.pacing = const Duration(milliseconds: 420),
    this.useIsolates = true,
    this.onPersist,
    this.onGameFinished,
  }) : state = session.match.current.replay() {
    for (final side in Side.values) {
      final seat = session.seat(side);
      _opponents[side] = seat.ai
          ? AiOpponent(
              AiConfig(
                difficulty: seat.difficulty!,
                personalityId: seat.personalityId!,
                seed: session.match.config.seed ^ (side.index + 1) * 7777,
              ),
              useIsolate: useIsolates,
            )
          : const LocalHumanOpponent();
    }
  }

  final MatchSession session;
  bool autoMove;
  final Duration pacing;
  final bool useIsolates;

  /// Called after every state change that should be saved.
  final void Function(MatchController c)? onPersist;

  /// Called once per finished game with the finished record.
  final void Function(MatchController c, GameRecord finished, GameState end)?
  onGameFinished;

  final Map<Side, Opponent> _opponents = {};
  GameState state;
  MatchPresenter? presenter;
  final List<GameState> _undo = [];
  final StreamController<List<GameEvent>> _events =
      StreamController.broadcast();
  bool _busy = false;
  bool _pumping = false;
  bool _disposed = false;
  bool aiThinking = false;
  GameRecord? lastFinished;

  /// Events of every applied action (for HUD toasts, sounds, haptics).
  Stream<List<GameEvent>> get events => _events.stream;

  MatchState get match => session.match;

  bool isHuman(Side s) => _opponents[s]!.isLocalHuman;

  /// The side the local player is on in vs-AI games (White by convention).
  Side get localSide =>
      isHuman(Side.white) || !isHuman(Side.black) ? Side.white : Side.black;

  bool get busy => _busy;

  /// The UI may accept input from the acting side now.
  bool get waitingForHuman =>
      !_busy &&
      !_disposed &&
      !state.isOver &&
      isHuman(Engine.actor(state)) &&
      !_autoRunning;

  bool _autoRunning = false;

  bool get canUndo =>
      waitingForHuman && _undo.isNotEmpty && state.phase == Phase.moving;

  /// Starts (or resumes) the match loop.
  Future<void> begin() async {
    presenter?.resync(state);
    notifyListeners();
    await _pump();
  }

  /// Applies a human action. Returns false if it was not legal now.
  Future<bool> act(GameAction a) async {
    if (!waitingForHuman) return false;
    final before = state;
    try {
      Engine.apply(state, a);
    } on IllegalActionException {
      return false;
    }
    if (a is PlayMove) {
      _undo.add(before);
    } else {
      _undo.clear();
    }
    await _apply(a);
    unawaited(_pump());
    return true;
  }

  /// Takes back the last move of the current roll.
  void undo() {
    if (!canUndo) return;
    state = _undo.removeLast();
    match.current.actions.removeLast();
    presenter?.resync(state);
    onPersist?.call(this);
    notifyListeners();
  }

  /// Resign the current game for [side].
  Future<void> resign(Side side) async {
    if (state.isOver) return;
    _undo.clear();
    await _apply(Resign(side));
  }

  /// After a finished (non-final) game, start the next one.
  Future<void> nextGame() async {
    if (!state.isOver || match.isOver) return;
    state = match.current.initial;
    _undo.clear();
    presenter?.resync(state);
    onPersist?.call(this);
    notifyListeners();
    await _pump();
  }

  Future<void> _apply(GameAction a) async {
    final before = state;
    final r = Engine.apply(state, a);
    match.current.actions.add(a);
    state = r.state;
    _busy = true;
    notifyListeners();
    if (!_events.isClosed) _events.add(r.events);
    try {
      await presenter?.present(before, state, r.events);
    } finally {
      _busy = false;
    }
    if (state.isOver) _finishGame();
    onPersist?.call(this);
    if (!_disposed) notifyListeners();
  }

  void _finishGame() {
    final finished = match.current;
    lastFinished = finished;
    match.recordResult(state.result!);
    onGameFinished?.call(this, finished, state);
  }

  bool _hasAlterOptions(GameState s) {
    if (!Engine.canAlterRoll(s)) return false;
    final inv = s.inv(s.current);
    return inv.rerolls > 0 || inv.lucky > 0 || Engine.canSetFate(s);
  }

  Future<void> _delay(double factor) => Future<void>.delayed(pacing * factor);

  Future<void> _pump() async {
    if (_pumping || _disposed) return;
    _pumping = true;
    try {
      while (!state.isOver && !_disposed) {
        final actor = Engine.actor(state);
        if (isHuman(actor)) {
          if (!await _humanAutomation()) break;
          continue;
        }
        aiThinking = true;
        notifyListeners();
        final snapshot = state;
        final wait = _delay(1);
        final actions = await _opponents[actor]!.decide(snapshot);
        await wait;
        aiThinking = false;
        if (_disposed || !identical(snapshot, state)) break;
        var applied = 0;
        for (final a in actions) {
          if (state.isOver || _disposed) break;
          if (a is PlayMove && !Engine.legalMoves(state).contains(a.move)) {
            break;
          }
          if (a is EndTurn && !Engine.canEndTurn(state)) break;
          await _apply(a);
          applied++;
          if (a is PlayMove) await _delay(0.35);
        }
        if (applied == 0) {
          // Defensive: never stall. Play the first legal action.
          final legal = Engine.legalActions(state);
          if (legal.isEmpty) break;
          await _apply(legal.first);
        }
      }
    } finally {
      _pumping = false;
      aiThinking = false;
      if (!_disposed) notifyListeners();
    }
  }

  /// Automatic steps on a human's behalf. Returns true if it acted.
  Future<bool> _humanAutomation() async {
    if (state.phase != Phase.moving) return false;
    final legal = Engine.legalMoves(state);
    if (legal.isEmpty) {
      if (_hasAlterOptions(state)) return false;
      if (state.movesThisRoll.isNotEmpty) return false; // wait for Done
      _autoRunning = true;
      notifyListeners();
      await _delay(2.6);
      _autoRunning = false;
      if (_disposed || state.phase != Phase.moving) return false;
      _undo.clear();
      await _apply(const EndTurn());
      return true;
    }
    if (!autoMove ||
        state.movesThisRoll.isNotEmpty ||
        _hasAlterOptions(state)) {
      return false;
    }
    final sim = TurnSim.fromBoard(
      state.board,
      state.current,
      Engine.moveContext(state, state.current),
    );
    final plays = MoveGen.allPlays(sim, state.dice);
    if (plays.length != 1 || plays.first.moves.isEmpty) return false;
    _autoRunning = true;
    notifyListeners();
    await _delay(0.8);
    for (final m in plays.first.moves) {
      if (_disposed || !Engine.legalMoves(state).contains(m)) break;
      _undo.add(state);
      await _apply(PlayMove(m));
      await _delay(0.3);
    }
    _autoRunning = false;
    notifyListeners();
    return false;
  }

  @override
  void dispose() {
    _disposed = true;
    unawaited(_events.close());
    super.dispose();
  }
}
