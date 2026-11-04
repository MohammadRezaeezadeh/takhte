import 'package:flutter_test/flutter_test.dart';
import 'package:haftnard/core/ai/ai.dart';
import 'package:haftnard/core/ai/nn_eval.dart';
import 'package:haftnard/core/ai/opening_book.dart';
import 'package:haftnard/core/ai/personality.dart';
import 'package:haftnard/core/rules/board.dart';
import 'package:haftnard/core/rules/types.dart';

import 'helpers.dart';

List<int> rel(Map<int, int> m, {int off = 0}) {
  final a = List<int>.filled(26, 0);
  m.forEach((p, n) => a[p] = n);
  a[0] = off;
  return a;
}

void main() {
  group('opening book', () {
    for (final side in Side.values) {
      test('3-1 makes the 5-point (${side.name})', () {
        final s = movingState(Board.initial(), [3, 1], side: side);
        final play = OpeningBook.lookup(s);
        expect(play, isNotNull);
        expect(play, hasLength(2));
      });
    }

    test('doubles play four moves', () {
      final s = movingState(Board.initial(), [6, 6, 6, 6]);
      expect(OpeningBook.lookup(s), hasLength(4));
    });

    test('no book once the position has changed', () {
      final b = Board.fromMaps(white: const {6: 5, 8: 3, 13: 5, 24: 1, 23: 1});
      expect(OpeningBook.lookup(movingState(b, [3, 1])), isNull);
    });

    test('Hard plays the book move', () {
      final s = movingState(Board.initial(), [6, 5]);
      final book = OpeningBook.lookup(s)!;
      final hard = AiBrain(const AiConfig(difficulty: Difficulty.hard));
      expect(hard.bestPlay(s), book);
    });
  });

  group('value network', () {
    final net = AiBrain.network;

    test('outputs a probability', () {
      final start = Board.initial();
      final p = net.winProb(start.of(Side.white), start.of(Side.black));
      expect(p, inInclusiveRange(0.0, 1.0));
    });

    test('a near-finished race is close to won', () {
      final me = rel(const {1: 1}, off: 14);
      final them = rel(const {24: 2, 13: 13});
      expect(net.winProb(me, them), greaterThan(0.85));
      expect(net.winProb(them, me), lessThan(0.15));
    });

    test('flat round trip', () {
      final a = NnEval.random(8, 1);
      final b = NnEval.fromFlat(a.toFlat(), 8);
      final me = rel(const {6: 5, 8: 3, 13: 5, 24: 2});
      expect(b.winProb(me, me), a.winProb(me, me));
    });

    test('a TD step moves the estimate toward the target', () {
      final n = NnEval.random(8, 2);
      final me = rel(const {6: 5, 8: 3, 13: 5, 24: 2});
      final them = rel(const {6: 5, 8: 3, 13: 5, 24: 2});
      final before = n.winProb(me, them);
      for (var i = 0; i < 20; i++) {
        n.train(me, them, 1, 0.5);
      }
      expect(n.winProb(me, them), greaterThan(before));
    });
  });
}
