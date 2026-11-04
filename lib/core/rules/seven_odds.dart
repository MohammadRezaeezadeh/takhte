import 'dart:math' as math;

/// Tuning for how often the Double Seven (7–7) comes up in Seven mode and
/// Journey. Everything about its frequency lives here.
///
/// Each own turn has a flat [base] chance. After [rampStart] own turns in a
/// row without a 7–7 the chance climbs steeply, and the [guaranteeTurn]-th
/// dry turn in a row always rolls one. Multipliers from cards and talismans
/// (Seven Magnet, Lucky Star, Evil Eye…) scale the result; a Seven Block
/// still forces 0.
///
/// Note: a guarantee on the 12th turn caps every drought at 12 turns, so with
/// ~36 own turns per game the average can't fall below ~3 per player; these
/// values keep it as close to the 2–3 target as that allows (see
/// docs/DECISIONS.md and docs/balance/sevens.md).
abstract final class SevenOdds {
  /// Chance on an ordinary own turn.
  static const double base = 0.05;

  /// Dry own turns before the pity ramp starts.
  static const int rampStart = 9;

  /// The n-th consecutive own turn without a 7–7 always rolls one.
  static const int guaranteeTurn = 12;

  /// Chance of a 7–7 on an own turn after [dry] own turns without one.
  static double chance(int dry, {double base = SevenOdds.base}) {
    if (base <= 0) return 0;
    const last = guaranteeTurn - 1;
    if (dry >= last) return 1;
    if (dry < rampStart) return base.clamp(0.0, 1.0);
    final t = (dry - rampStart + 1) / (last - rampStart + 1);
    return (base + (1 - base) * math.pow(t, 2)).clamp(0.0, 1.0);
  }
}
