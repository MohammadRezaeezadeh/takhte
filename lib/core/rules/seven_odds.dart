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

  /// Dry own turns after which a 7–7 is guaranteed, for a [base] chance.
  /// Scales with the chance so every level keeps the same shape; the
  /// default base gives exactly [guaranteeTurn].
  static int guaranteeFor(double base) => (0.6 / base).round().clamp(4, 24);

  /// Chance of a 7–7 on an own turn after [dry] own turns without one.
  static double chance(int dry, {double base = SevenOdds.base}) {
    if (base <= 0) return 0;
    final guarantee = guaranteeFor(base);
    final last = guarantee - 1;
    final ramp = guarantee - (guaranteeTurn - rampStart);
    if (dry >= last) return 1;
    if (dry < ramp) return base.clamp(0.0, 1.0);
    final t = (dry - ramp + 1) / (last - ramp + 1);
    return (base + (1 - base) * math.pow(t, 2)).clamp(0.0, 1.0);
  }
}

/// How often 7–7 comes up, chosen when setting up a game.
enum SevenLevel {
  low(0.025),
  normal(SevenOdds.base),
  high(0.10),
  veryHigh(0.18);

  SevenLevel(this.base);

  /// Base chance per own turn (the drought guarantee scales with it).
  final double base;
}
