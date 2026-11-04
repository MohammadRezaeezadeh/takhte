import 'dart:math' as math;
import 'dart:typed_data';

/// A small TD-Gammon-style value network.
///
/// Input: 196 units describing a position from the point of view of the side
/// that has just moved ("me"; the opponent rolls next). Output: probability
/// that "me" wins. 40 sigmoid hidden units.
class NnEval {
  NnEval(this.w1, this.b1, this.w2, this.b2) : hidden = b1.length;

  /// Random initialisation for training.
  factory NnEval.random(int hidden, int seed) {
    final r = math.Random(seed);
    double rnd() => (r.nextDouble() - 0.5) * 0.2;
    return NnEval(
      Float64List.fromList([for (var i = 0; i < inputs * hidden; i++) rnd()]),
      Float64List.fromList([for (var i = 0; i < hidden; i++) rnd()]),
      Float64List.fromList([for (var i = 0; i < hidden; i++) rnd()]),
      0,
    );
  }

  /// Builds a network from a flat weight list `[w1..., b1..., w2..., b2]`.
  factory NnEval.fromFlat(List<double> flat, int hidden) {
    var o = 0;
    Float64List take(int n) {
      final l = Float64List.fromList(flat.sublist(o, o + n));
      o += n;
      return l;
    }

    final w1 = take(inputs * hidden);
    final b1 = take(hidden);
    final w2 = take(hidden);
    return NnEval(w1, b1, w2, flat[o]);
  }

  static const int inputs = 196;

  final int hidden;

  /// Input→hidden weights, row-major by input: `w1[i * hidden + j]`.
  final Float64List w1;
  final Float64List b1;
  final Float64List w2;
  double b2;

  List<double> toFlat() => [...w1, ...b1, ...w2, b2];

  /// Sparse encoding: indices and values of non-zero inputs.
  static int encode(
    List<int> mine,
    List<int> theirs,
    Int32List idx,
    Float64List val,
  ) {
    var n = 0;
    void side(List<int> arr, int base) {
      for (var p = 1; p <= 24; p++) {
        final c = arr[p];
        if (c == 0) continue;
        final o = base + (p - 1) * 4;
        idx[n] = o;
        val[n++] = 1;
        if (c >= 2) {
          idx[n] = o + 1;
          val[n++] = 1;
        }
        if (c >= 3) {
          idx[n] = o + 2;
          val[n++] = 1;
        }
        if (c > 3) {
          idx[n] = o + 3;
          val[n++] = (c - 3) / 2;
        }
      }
    }

    side(mine, 0);
    side(theirs, 96);
    if (mine[25] > 0) {
      idx[n] = 192;
      val[n++] = mine[25] / 2;
    }
    if (theirs[25] > 0) {
      idx[n] = 193;
      val[n++] = theirs[25] / 2;
    }
    if (mine[0] > 0) {
      idx[n] = 194;
      val[n++] = mine[0] / 15;
    }
    if (theirs[0] > 0) {
      idx[n] = 195;
      val[n++] = theirs[0] / 15;
    }
    return n;
  }

  final Int32List _idx = Int32List(inputs);
  final Float64List _val = Float64List(inputs);
  late final Float64List _h = Float64List(hidden);

  static double _sig(double x) => 1 / (1 + math.exp(-x));

  /// P(win) for "mine" (who has just moved).
  double winProb(List<int> mine, List<int> theirs) {
    final n = encode(mine, theirs, _idx, _val);
    return _forward(n);
  }

  double _forward(int n) {
    for (var j = 0; j < hidden; j++) {
      _h[j] = b1[j];
    }
    for (var k = 0; k < n; k++) {
      final row = _idx[k] * hidden;
      final v = _val[k];
      for (var j = 0; j < hidden; j++) {
        _h[j] += w1[row + j] * v;
      }
    }
    var out = b2;
    for (var j = 0; j < hidden; j++) {
      final a = _sig(_h[j]);
      _h[j] = a;
      out += w2[j] * a;
    }
    return _sig(out);
  }

  /// One TD(0) step: move V(position) towards [target] with rate [alpha].
  void train(List<int> mine, List<int> theirs, double target, double alpha) {
    final n = encode(mine, theirs, _idx, _val);
    final y = _forward(n);
    final delta = (target - y) * y * (1 - y) * alpha;
    for (var j = 0; j < hidden; j++) {
      final hj = _h[j];
      final g = delta * w2[j] * hj * (1 - hj);
      w2[j] += delta * hj;
      b1[j] += g;
      for (var k = 0; k < n; k++) {
        w1[_idx[k] * hidden + j] += g * _val[k];
      }
    }
    b2 += delta;
  }
}
