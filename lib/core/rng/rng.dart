/// Deterministic, seedable pseudo random number generator.
///
/// Implements xoshiro128** using only 32-bit arithmetic so that results are
/// identical on every platform (VM, AOT, isolates, a future server). All game
/// randomness (dice, card offers, AI tie-breaks) must flow through this class.
library;

const int _mask32 = 0xFFFFFFFF;

int _rotl(int x, int k) => ((x << k) | (x >> (32 - k))) & _mask32;

/// A mutable RNG. Copy its [state] into immutable game state between steps.
class Rng {
  /// Creates an RNG from a 32-bit or larger integer seed via SplitMix32.
  factory Rng.seeded(int seed) {
    var s = seed & _mask32;
    int next() {
      s = (s + 0x9E3779B9) & _mask32;
      var z = s;
      z = ((z ^ (z >> 16)) * 0x85EBCA6B) & _mask32;
      z = ((z ^ (z >> 13)) * 0xC2B2AE35) & _mask32;
      return (z ^ (z >> 16)) & _mask32;
    }

    final st = [next(), next(), next(), next()];
    if (st.every((v) => v == 0)) st[0] = 1;
    return Rng.fromState(st);
  }

  /// Restores an RNG from a previously captured [state].
  Rng.fromState(List<int> state)
    : assert(state.length == 4, 'xoshiro128 needs 4 words'),
      _s0 = state[0] & _mask32,
      _s1 = state[1] & _mask32,
      _s2 = state[2] & _mask32,
      _s3 = state[3] & _mask32;

  int _s0;
  int _s1;
  int _s2;
  int _s3;

  /// Snapshot of the internal state (4 x 32-bit words).
  List<int> get state => List<int>.unmodifiable([_s0, _s1, _s2, _s3]);

  /// Next raw 32-bit unsigned value.
  int nextUint32() {
    final result = (_rotl((_s1 * 5) & _mask32, 7) * 9) & _mask32;
    final t = (_s1 << 9) & _mask32;
    _s2 ^= _s0;
    _s3 ^= _s1;
    _s1 ^= _s2;
    _s0 ^= _s3;
    _s2 ^= t;
    _s3 = _rotl(_s3, 11);
    return result;
  }

  /// Uniform integer in `[0, max)` using rejection sampling (no modulo bias).
  int nextInt(int max) {
    assert(max > 0 && max <= 0x100000000, 'max out of range');
    if (max == 1) return 0;
    final limit = 0x100000000 - (0x100000000 % max);
    while (true) {
      final v = nextUint32();
      if (v < limit) return v % max;
    }
  }

  /// Uniform double in `[0, 1)` with 32 bits of precision.
  double nextDouble() => nextUint32() / 4294967296.0;

  /// Returns true with probability [p].
  bool chance(double p) => nextDouble() < p;

  /// A fair six-sided die.
  int die() => nextInt(6) + 1;

  /// Picks an index according to integer/double [weights].
  int weighted(List<double> weights) {
    final total = weights.fold<double>(0, (a, b) => a + b);
    if (total <= 0) return 0;
    var r = nextDouble() * total;
    for (var i = 0; i < weights.length; i++) {
      r -= weights[i];
      if (r < 0) return i;
    }
    return weights.length - 1;
  }

  /// Fisher–Yates shuffle in place.
  void shuffle<T>(List<T> list) {
    for (var i = list.length - 1; i > 0; i--) {
      final j = nextInt(i + 1);
      final tmp = list[i];
      list[i] = list[j];
      list[j] = tmp;
    }
  }
}

/// Derives a child seed (e.g. for game N of a match) deterministically.
int deriveSeed(int seed, int salt) {
  final r = Rng.seeded(seed ^ ((salt * 0x27D4EB2D) & _mask32));
  return r.nextUint32();
}
