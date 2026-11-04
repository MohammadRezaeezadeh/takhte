import 'package:haftnard/core/rng/rng.dart';
import 'package:test/test.dart';

void main() {
  test('same seed gives same sequence', () {
    final a = Rng.seeded(42);
    final b = Rng.seeded(42);
    for (var i = 0; i < 1000; i++) {
      expect(a.nextUint32(), b.nextUint32());
    }
  });

  test('state round-trips', () {
    final a = Rng.seeded(7);
    for (var i = 0; i < 10; i++) {
      a.die();
    }
    final b = Rng.fromState(a.state);
    for (var i = 0; i < 100; i++) {
      expect(a.die(), b.die());
    }
  });

  test('known first values are stable across platforms', () {
    final r = Rng.seeded(12345);
    final v = [for (var i = 0; i < 5; i++) r.nextUint32()];
    // Golden values guard against accidental algorithm changes, which would
    // break saved games and replays.
    expect(v, [518667457, 440444462, 4232892992, 3757857622, 3939018813]);
    final d = Rng.seeded(1);
    expect(
      [for (var i = 0; i < 10; i++) d.die()],
      [3, 6, 4, 6, 1, 1, 5, 4, 2, 3],
    );
  });

  test('dice are roughly uniform', () {
    final r = Rng.seeded(1);
    final counts = List<int>.filled(7, 0);
    for (var i = 0; i < 60000; i++) {
      counts[r.die()]++;
    }
    for (var f = 1; f <= 6; f++) {
      expect(counts[f], inInclusiveRange(9400, 10600));
    }
  });

  test('weighted picks respect weights', () {
    final r = Rng.seeded(3);
    final c = [0, 0];
    for (var i = 0; i < 10000; i++) {
      c[r.weighted([1, 3])]++;
    }
    expect(c[1] / c[0], closeTo(3, 0.4));
  });

  test('deriveSeed is deterministic and distinct', () {
    expect(deriveSeed(1, 1), deriveSeed(1, 1));
    expect(deriveSeed(1, 1), isNot(deriveSeed(1, 2)));
  });
}
