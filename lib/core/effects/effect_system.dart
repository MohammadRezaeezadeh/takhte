import 'package:haftnard/core/rules/engine.dart';
import 'package:haftnard/core/rules/events.dart';
import 'package:haftnard/core/rules/move_gen.dart';
import 'package:haftnard/core/rules/state.dart';
import 'package:haftnard/core/rules/types.dart';

/// Hook-based behaviour for an [EffectKind]. Every hook is optional.
///
/// Hooks are invoked by the engine in [priority] order (lower first, then by
/// effect id):
/// - [onTurnStart]: start of the affected side's turn (active effects only).
/// - [onBeforeRoll]: adjust the [RollPlan] (dice count, cap, doubles, p7).
/// - [onRoll]: observe/modify a fresh roll.
/// - [onGenerateMoves]: contribute move-rule modifiers for a mover.
/// - [onMoveApplied]: after any checker movement.
/// - [onHit]: after a checker is hit.
/// Ticking (`onTurnEnd`) is uniform: the engine decrements `turnsLeft` at the
/// end of each of the affected side's turns once active.
abstract class EffectHandler {
  const EffectHandler({this.priority = 0});
  final int priority;

  void onTurnStart(Tx tx, ActiveEffect e) {}
  void onBeforeRoll(Tx tx, ActiveEffect e, RollPlan plan) {}
  void onRoll(Tx tx, ActiveEffect e, List<int> raw) {}
  void onGenerateMoves(Tx tx, ActiveEffect e, Side mover, ContextBuilder b) {}
  void onMoveApplied(
    Tx tx,
    ActiveEffect e,
    Side mover,
    int fromAbs,
    int toAbs, {
    required bool mined,
  }) {}
  void onHit(Tx tx, ActiveEffect e, Side victim, int pointAbs) {}
}

/// Mutable accumulator for a [MoveContext].
class ContextBuilder {
  final Map<int, int> frozen = {};
  int protectedMask = 0;
  int tollMask = 0;
  int mineMask = 0;
}

class _Noop extends EffectHandler {
  const _Noop();
}

class _BrokenDie extends EffectHandler {
  const _BrokenDie() : super(priority: 10);
  @override
  void onBeforeRoll(Tx tx, ActiveEffect e, RollPlan plan) => plan.count = 1;
}

class _LoadedHand extends EffectHandler {
  const _LoadedHand();
  @override
  void onBeforeRoll(Tx tx, ActiveEffect e, RollPlan plan) {
    if (plan.count == 2) plan.count = 3;
  }
}

class _Fog extends EffectHandler {
  const _Fog();
  @override
  void onBeforeRoll(Tx tx, ActiveEffect e, RollPlan plan) =>
      plan.doublesCount = false;
}

class _Curse extends EffectHandler {
  const _Curse();
  @override
  void onBeforeRoll(Tx tx, ActiveEffect e, RollPlan plan) {
    if (plan.cap > 4) plan.cap = 4;
  }
}

class _SevenMagnet extends EffectHandler {
  const _SevenMagnet();
  @override
  void onBeforeRoll(Tx tx, ActiveEffect e, RollPlan plan) =>
      plan.p7Multiplier *= 2;
}

/// Freezes [ActiveEffect.count] of the affected side's checkers on a point.
class _Freeze extends EffectHandler {
  const _Freeze();
  @override
  void onGenerateMoves(Tx tx, ActiveEffect e, Side mover, ContextBuilder b) {
    if (e.affected != mover) return;
    final rel = toRelative(mover, e.point);
    b.frozen[rel] = (b.frozen[rel] ?? 0) + e.count;
  }
}

/// Shield and Iron Gate: the owner's lone checker cannot be hit.
class _Protect extends EffectHandler {
  const _Protect({required this.follows});

  /// Shield follows its checker when it moves; Iron Gate is anchored.
  final bool follows;

  @override
  void onGenerateMoves(Tx tx, ActiveEffect e, Side mover, ContextBuilder b) {
    if (e.owner == mover) return;
    b.protectedMask |= 1 << toRelative(mover, e.point);
  }

  @override
  void onMoveApplied(
    Tx tx,
    ActiveEffect e,
    Side mover,
    int fromAbs,
    int toAbs, {
    required bool mined,
  }) {
    if (e.owner != mover || e.point != fromAbs || fromAbs == 0) return;
    if (tx.board.count(mover, toRelative(mover, fromAbs)) > 0) return;
    if (follows && toAbs != 0 && !mined) {
      tx.replaceEffect(e.copyWith(point: toAbs));
    } else {
      tx.removeEffect(e.id);
    }
  }
}

class _Toll extends EffectHandler {
  const _Toll();
  @override
  void onGenerateMoves(Tx tx, ActiveEffect e, Side mover, ContextBuilder b) {
    if (e.owner == mover) return;
    b.tollMask |= 1 << toRelative(mover, e.point);
  }
}

class _Landmine extends EffectHandler {
  const _Landmine();
  @override
  void onGenerateMoves(Tx tx, ActiveEffect e, Side mover, ContextBuilder b) {
    if (e.owner == mover) return;
    b.mineMask |= 1 << toRelative(mover, e.point);
  }
}

class _Quicksand extends EffectHandler {
  const _Quicksand();
  @override
  void onTurnStart(Tx tx, ActiveEffect e) {
    final side = e.affected;
    final n = tx.board.count(side, toRelative(side, e.point));
    if (n == 0) return;
    tx.removeEffect(e.id);
    tx.addEffect(
      EffectKind.quicksandFreeze,
      owner: e.owner,
      affected: side,
      turns: 1,
      point: e.point,
      count: n,
    );
    tx.events.add(QuicksandGripped(side, e.point));
  }
}

class _SkipTurn extends EffectHandler {
  const _SkipTurn();
  @override
  void onTurnStart(Tx tx, ActiveEffect e) {
    tx.removeEffect(e.id);
    tx.skipping = true;
  }
}

class _MirrorWatch extends EffectHandler {
  const _MirrorWatch();
  @override
  void onRoll(Tx tx, ActiveEffect e, List<int> raw) {
    tx.removeEffect(e.id);
    tx.addEffect(
      EffectKind.mirrorBonus,
      owner: e.owner,
      affected: e.owner,
      turns: 99,
      immediate: false,
      values: List.of(raw),
    );
  }
}

class _MirrorBonus extends EffectHandler {
  const _MirrorBonus();
  @override
  void onTurnStart(Tx tx, ActiveEffect e) {
    tx.removeEffect(e.id);
    tx.rollQueue.add(List.of(e.values));
  }
}

/// Registry and helpers for the effect system.
abstract final class EffectSystem {
  static const Map<EffectKind, EffectHandler> _handlers = {
    EffectKind.brokenDie: _BrokenDie(),
    EffectKind.fog: _Fog(),
    EffectKind.curse: _Curse(),
    EffectKind.chains: _Freeze(),
    EffectKind.quicksandFreeze: _Freeze(),
    EffectKind.shield: _Protect(follows: true),
    EffectKind.ironGate: _Protect(follows: false),
    EffectKind.quicksand: _Quicksand(),
    EffectKind.toll: _Toll(),
    EffectKind.landmine: _Landmine(),
    EffectKind.sevenMagnet: _SevenMagnet(),
    EffectKind.loadedHand: _LoadedHand(),
    EffectKind.fateEdit: _Noop(),
    EffectKind.mirrorWatch: _MirrorWatch(),
    EffectKind.mirrorBonus: _MirrorBonus(),
    EffectKind.skipTurn: _SkipTurn(),
    EffectKind.bonusPick: _Noop(),
    EffectKind.bonusOffer: _Noop(),
  };

  static EffectHandler handler(EffectKind k) => _handlers[k]!;

  static int compare(ActiveEffect a, ActiveEffect b) {
    final p = handler(a.kind).priority.compareTo(handler(b.kind).priority);
    return p != 0 ? p : a.id.compareTo(b.id);
  }

  /// Builds the move-rule context for [mover] from all active effects.
  static MoveContext moveContext(Tx tx, Side mover, {bool hideMines = false}) {
    final b = ContextBuilder();
    final sorted = [
      for (final e in tx.effects)
        if (e.isActive(tx.turnNumber)) e,
    ]..sort(compare);
    for (final e in sorted) {
      handler(e.kind).onGenerateMoves(tx, e, mover, b);
    }
    // Frozen counts can never exceed the checkers actually there.
    final mine = tx.board.of(mover);
    final frozen = <int, int>{};
    b.frozen.forEach((p, n) {
      final c = n > mine[p] ? mine[p] : n;
      if (c > 0) frozen[p] = c;
    });
    return MoveContext(
      frozen: frozen,
      protectedMask: b.protectedMask,
      tollMask: b.tollMask,
      mineMask: hideMines ? 0 : b.mineMask,
      ghostCharges: tx.inv(mover).ghost,
      opponentPhoenix: tx.inv(mover.opponent).phoenix > 0,
    );
  }

  /// Removes board effects that no longer have a subject.
  static void cleanup(Tx tx) {
    final kept = <ActiveEffect>[];
    for (final e in tx.effects) {
      switch (e.kind) {
        case EffectKind.chains:
        case EffectKind.quicksandFreeze:
          final n = tx.board.count(e.affected, toRelative(e.affected, e.point));
          if (n == 0) continue;
          kept.add(n < e.count ? e.copyWith(count: n) : e);
        case EffectKind.shield:
        case EffectKind.ironGate:
          final n = tx.board.count(e.owner, toRelative(e.owner, e.point));
          if (n == 0) continue;
          kept.add(e);
        default:
          kept.add(e);
      }
    }
    tx.effects = kept;
  }
}
