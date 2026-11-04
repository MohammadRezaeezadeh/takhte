import 'dart:math' as math;

/// Tunable evaluation weights. Personalities tweak these.
class EvalWeights {
  const EvalWeights({
    this.pip = 1.0,
    this.blot = 1.0,
    this.homePoint = 0.55,
    this.point = 0.25,
    this.prime = 0.35,
    this.anchor = 0.45,
    this.oppBar = 0.9,
    this.myBar = 0.7,
    this.borneOff = 0.12,
    this.stack = 0.08,
    this.hitBonus = 0.0,
  });

  final double pip;
  final double blot;
  final double homePoint;
  final double point;
  final double prime;
  final double anchor;
  final double oppBar;
  final double myBar;
  final double borneOff;
  final double stack;

  /// Extra reward for each opponent checker on the bar (aggressive styles).
  final double hitBonus;

  static const EvalWeights standard = EvalWeights();
}

/// The 21 distinct rolls with their weights out of 36.
final List<(int, int, int)> kRolls = List.unmodifiable([
  for (var a = 1; a <= 6; a++)
    for (var b = a; b <= 6; b++) (a, b, a == b ? 1 : 2),
]);

/// Static position evaluator. Arrays are 26-slot relative arrays (0 = off,
/// 25 = bar). `mine` has just moved; the opponent rolls next. Returns an
/// equity-like score in (-1, 1) from `mine`'s point of view (±1.5 for a
/// finished game with gammons ignored for simplicity of averaging).
abstract final class Evaluator {
  static double evaluate(
    List<int> mine,
    List<int> theirs, [
    EvalWeights w = EvalWeights.standard,
  ]) {
    if (mine[0] == 15) return theirs[0] == 0 ? 1.5 : 1.0;
    if (theirs[0] == 15) return mine[0] == 0 ? -1.5 : -1.0;

    var myPips = 0;
    var oppPips = 0;
    for (var i = 1; i <= 25; i++) {
      myPips += mine[i] * i;
      oppPips += theirs[i] * i;
    }

    // Contact: my rearmost checker vs their rearmost (in my frame).
    var myBack = 0;
    for (var i = 25; i >= 1; i--) {
      if (mine[i] > 0) {
        myBack = i;
        break;
      }
    }
    var theirBack = 0;
    for (var i = 25; i >= 1; i--) {
      if (theirs[i] > 0) {
        theirBack = i;
        break;
      }
    }
    final contact = myBack > 25 - theirBack;

    if (!contact) {
      return _race(mine, theirs, myPips, oppPips);
    }

    var score = w.pip * (oppPips - myPips - 4) / 12.0;

    // Made points, primes and anchors.
    var run = 0;
    var bestRun = 0;
    for (var p = 1; p <= 24; p++) {
      final n = mine[p];
      if (n >= 2) {
        run++;
        if (run > bestRun) bestRun = run;
        if (p <= 6) {
          score += w.homePoint * (p == 1 ? 0.4 : 1.0);
        } else if (p >= 19) {
          score += w.anchor;
        } else {
          score += w.point * (p <= 9 ? 1.4 : 1.0);
        }
        if (n > 3) score -= w.stack * (n - 3);
      } else {
        run = 0;
      }
    }
    if (bestRun >= 3) score += w.prime * (bestRun - 2) * (bestRun - 1) / 2;

    // Bar.
    score +=
        theirs[25] * (w.oppBar + w.hitBonus) * (0.5 + _homeClosed(mine) / 6);
    score -= mine[25] * w.myBar * (0.5 + _homeClosed(theirs) / 6);
    score += w.borneOff * (mine[0] - theirs[0]);

    // Blot exposure.
    final oppPos = <int>[];
    for (var q = 1; q <= 25; q++) {
      if (theirs[q] > 0) oppPos.add(25 - q); // their q in my frame
    }
    var blotRisk = 0.0;
    for (var b = 1; b <= 24; b++) {
      if (mine[b] != 1) continue;
      final shots = Evaluator.shots(b, oppPos, mine, theirs[25] > 0);
      if (shots == 0) continue;
      final loss = (25 - b) / 25.0; // advanced blots cost more pips
      final danger = b <= 6
          ? 1.2
          : 1.0; // blots in my home invite re-entry hits
      blotRisk += shots / 36.0 * (0.35 + loss) * danger;
    }
    score -= w.blot * blotRisk * 1.6;

    return 2 / (1 + math.exp(-score * 0.55)) - 1;
  }

  static int _homeClosed(List<int> arr) {
    var n = 0;
    for (var p = 1; p <= 6; p++) {
      if (arr[p] >= 2) n++;
    }
    return n;
  }

  /// Number of the 36 rolls with which an opponent hits my blot at [b].
  /// [oppPos] are opponent checker positions in my frame (0 = their bar).
  static int shots(int b, List<int> oppPos, List<int> mine, bool oppOnBar) {
    var count = 0;
    bool blocked(int pos) => pos >= 1 && pos <= 24 && mine[pos] >= 2;
    for (final (d1, d2, wgt) in kRolls) {
      var hit = false;
      for (final x in oppPos) {
        if (oppOnBar && x != 0) continue;
        final dist = b - x;
        if (dist <= 0 || dist > 24) continue;
        if (d1 == d2) {
          for (var k = 1; k <= 4; k++) {
            if (blocked(x + d1 * k) && d1 * k != dist) break;
            if (d1 * k == dist) {
              hit = true;
              break;
            }
          }
        } else {
          if (dist == d1 || dist == d2) {
            hit = true;
          } else if (dist == d1 + d2 &&
              (!blocked(x + d1) || !blocked(x + d2))) {
            hit = true;
          }
        }
        if (hit) break;
      }
      if (hit) count += wgt;
    }
    return count;
  }

  static double _race(
    List<int> mine,
    List<int> theirs,
    int myPips,
    int oppPips,
  ) {
    // Effective pip counts with a wastage estimate; opponent is on roll.
    double eff(List<int> arr, int pips) {
      var gaps = 0;
      for (var p = 1; p <= 6; p++) {
        if (arr[p] == 0) gaps++;
      }
      var heavy = 0;
      for (var p = 1; p <= 3; p++) {
        heavy += arr[p];
      }
      return pips + 1.5 * gaps * (pips < 40 ? 0.3 : 1) + 0.6 * heavy;
    }

    final me = eff(mine, myPips);
    final them = eff(theirs, oppPips) - 4.1; // they roll first: ~ half a roll
    final denom = math.sqrt(math.max(me + them, 8)) * 0.85;
    final z = (them - me) / denom;
    return 2 / (1 + math.exp(-z * 1.7)) - 1;
  }
}
