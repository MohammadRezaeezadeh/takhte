// Validates the optimized move generator against an independent, naive
// brute-force implementation on thousands of random positions.
import 'dart:math';

import 'package:haftnard/core/rules/board.dart';
import 'package:haftnard/core/rules/types.dart';
import 'package:test/test.dart';

import 'helpers.dart';

/// Naive absolute-coordinate position.
class RefPos {
  RefPos(this.pts, this.bar, this.off);
  final List<int> pts; // 0..25 used 1..24, +white / -black
  final List<int> bar; // [white, black]
  final List<int> off;

  RefPos clone() => RefPos(List.of(pts), List.of(bar), List.of(off));

  // Kept static to mirror the production API shape under test.
  // ignore: prefer_constructors_over_static_methods
  static RefPos fromBoard(Board b) {
    final pts = List<int>.filled(26, 0);
    for (var abs = 1; abs <= 24; abs++) {
      final (side, n) = b.atAbsolute(abs);
      if (side == Side.white) pts[abs] = n;
      if (side == Side.black) pts[abs] = -n;
    }
    return RefPos(
      pts,
      [b.onBar(Side.white), b.onBar(Side.black)],
      [b.borneOff(Side.white), b.borneOff(Side.black)],
    );
  }
}

const bar = -1;
const off = -2;

typedef RefMove = (int from, int to, int die);

int own(RefPos p, int abs, bool white) =>
    white ? max(0, p.pts[abs]) : max(0, -p.pts[abs]);
int opp(RefPos p, int abs, bool white) => own(p, abs, !white);

List<RefMove> refSingles(RefPos p, bool white, int d) {
  final si = white ? 0 : 1;
  final out = <RefMove>[];
  bool open(int abs) => opp(p, abs, white) < 2;
  if (p.bar[si] > 0) {
    final dest = white ? 25 - d : d;
    if (open(dest)) out.add((bar, dest, d));
    return out;
  }
  bool allHome() {
    for (var a = 1; a <= 24; a++) {
      final inHome = white ? a <= 6 : a >= 19;
      if (!inHome && own(p, a, white) > 0) return false;
    }
    return true;
  }

  for (var a = 1; a <= 24; a++) {
    if (own(p, a, white) == 0) continue;
    final dest = white ? a - d : a + d;
    if (dest >= 1 && dest <= 24) {
      if (open(dest)) out.add((a, dest, d));
    } else if (allHome()) {
      final exact = white ? dest == 0 : dest == 25;
      if (exact) {
        out.add((a, off, d));
      } else {
        var higher = false;
        if (white) {
          for (var h = a + 1; h <= 6; h++) {
            if (own(p, h, white) > 0) higher = true;
          }
        } else {
          for (var h = 19; h < a; h++) {
            if (own(p, h, white) > 0) higher = true;
          }
        }
        if (!higher) out.add((a, off, d));
      }
    }
  }
  return out;
}

RefPos refApply(RefPos p, bool white, RefMove m) {
  final q = p.clone();
  final si = white ? 0 : 1;
  final sign = white ? 1 : -1;
  if (m.$1 == bar) {
    q.bar[si]--;
  } else {
    q.pts[m.$1] -= sign;
  }
  if (m.$2 == off) {
    q.off[si]++;
  } else {
    if (opp(q, m.$2, white) == 1) {
      q.pts[m.$2] = 0;
      q.bar[1 - si]++;
    }
    q.pts[m.$2] += sign;
  }
  return q;
}

Set<String> refLegalFirst(RefPos p, bool white, List<int> dice) {
  final seqs = <List<RefMove>>[];
  void dfs(RefPos pos, List<int> remaining, List<RefMove> path) {
    var any = false;
    if (remaining.isNotEmpty) {
      final d = remaining.first;
      for (final m in refSingles(pos, white, d)) {
        any = true;
        dfs(refApply(pos, white, m), remaining.sublist(1), [...path, m]);
      }
    }
    if (!any) seqs.add(path);
  }

  final orders = dice.length == 2 && dice[0] != dice[1]
      ? [
          [dice[0], dice[1]],
          [dice[1], dice[0]],
        ]
      : [dice];
  for (final o in orders) {
    dfs(p, o, []);
  }
  final maxLen = seqs.map((s) => s.length).fold(0, max);
  if (maxLen == 0) return {};
  var best = seqs.where((s) => s.length == maxLen).toList();
  if (maxLen == 1 && dice.length == 2 && dice[0] != dice[1]) {
    final hi = max(dice[0], dice[1]);
    final big = best.where((s) => s.first.$3 == hi).toList();
    if (big.isNotEmpty) best = big;
  }
  String rel(int v) {
    if (v == bar) return '25';
    if (v == off) return '0';
    return '${white ? v : 25 - v}';
  }

  return {
    for (final s in best)
      '${rel(s.first.$1)}/${rel(s.first.$2)}(${s.first.$3})',
  };
}

Board randomBoard(Random r) {
  while (true) {
    final w = List<int>.filled(26, 0);
    final b = List<int>.filled(26, 0);
    final homeOnlyW = r.nextInt(4) == 0;
    final homeOnlyB = r.nextInt(4) == 0;
    var ok = true;
    for (final (arr, homeOnly) in [(w, homeOnlyW), (b, homeOnlyB)]) {
      final offN = homeOnly ? r.nextInt(10) : r.nextInt(3);
      arr[0] = offN;
      for (var i = 0; i < 15 - offN; i++) {
        final slot = homeOnly
            ? 1 + r.nextInt(6)
            : (r.nextInt(20) == 0 ? 25 : 1 + r.nextInt(24));
        arr[slot]++;
      }
    }
    for (var p = 1; p <= 24; p++) {
      if (w[p] > 0 && b[25 - p] > 0) {
        ok = false;
        break;
      }
    }
    if (!ok) continue;
    final board = Board.fromLists(w, b);
    if (board.validate() == null) return board;
  }
}

void main() {
  test('move generator matches brute-force reference on random positions', () {
    final r = Random(2024);
    var compared = 0;
    var nonEmpty = 0;
    for (var i = 0; i < 2500; i++) {
      final board = randomBoard(r);
      final side = r.nextBool() ? Side.white : Side.black;
      final a = 1 + r.nextInt(6);
      final b = 1 + r.nextInt(6);
      final dice = a == b ? [a, a, a, a] : [a, b];
      final ours = moveStrings(legal(board, dice, side));
      final ref = refLegalFirst(
        RefPos.fromBoard(board),
        side == Side.white,
        dice,
      );
      expect(ours, ref, reason: 'board=${board.key} side=$side dice=$dice');
      compared++;
      if (ours.isNotEmpty) nonEmpty++;
    }
    expect(compared, 2500);
    expect(nonEmpty, greaterThan(1500));
  });
}
