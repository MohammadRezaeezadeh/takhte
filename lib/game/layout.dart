import 'dart:math' as math;
import 'dart:ui';

import 'package:haftnard/core/rules/types.dart';
import 'package:meta/meta.dart';

/// Where a checker can sit, for rendering.
@immutable
sealed class Slot {
  const Slot();
}

class PointSlot extends Slot {
  const PointSlot(this.abs);
  final int abs;
  @override
  bool operator ==(Object other) => other is PointSlot && other.abs == abs;
  @override
  int get hashCode => abs;
}

class BarSlot extends Slot {
  const BarSlot(this.side);
  final Side side;
  @override
  bool operator ==(Object other) => other is BarSlot && other.side == side;
  @override
  int get hashCode => 100 + side.index;
}

class OffSlot extends Slot {
  const OffSlot(this.side);
  final Side side;
  @override
  bool operator ==(Object other) => other is OffSlot && other.side == side;
  @override
  int get hashCode => 200 + side.index;
}

/// Pure geometry of the board for a given canvas size.
///
/// Absolute point numbering: White's home is 1..6. With [homeOnRight] the
/// bottom row reads 12..1 left→right and the top row 13..24 left→right.
class BoardLayout {
  BoardLayout(this.size, {this.homeOnRight = true}) {
    final w = size.width;
    final h = size.height;
    // Board aspect ~1.2 (w/h) incl. trays; fit inside size.
    const aspect = 1.18;
    var bw = w;
    var bh = bw / aspect;
    if (bh > h) {
      bh = h;
      bw = bh * aspect;
    }
    outer = Rect.fromLTWH((w - bw) / 2, (h - bh) / 2, bw, bh);
    frame = bw * 0.028;
    trayW = bw * 0.075;
    final inner = Rect.fromLTRB(
      outer.left + frame + (homeOnRight ? 0 : trayW),
      outer.top + frame,
      outer.right - frame - (homeOnRight ? trayW : 0),
      outer.bottom - frame,
    );
    field = inner;
    barW = inner.width * 0.07;
    pointW = (inner.width - barW) / 12;
    bar = Rect.fromLTWH(inner.left + pointW * 6, inner.top, barW, inner.height);
    final trayX = homeOnRight
        ? inner.right + frame * 0.5
        : outer.left + frame * 0.5;
    final trayInnerW = trayW - frame * 0.5;
    final half = (inner.height - frame) / 2;
    // White bears off on the bottom tray; Black on the top one.
    whiteTray = Rect.fromLTWH(trayX, inner.bottom - half, trayInnerW, half);
    blackTray = Rect.fromLTWH(trayX, inner.top, trayInnerW, half);
    checkerR = math.min(pointW * 0.47, inner.height * 0.045);
    pointH = inner.height * 0.42;
  }

  final Size size;
  final bool homeOnRight;
  late final Rect outer;
  late final Rect field;
  late final Rect bar;
  late final Rect whiteTray;
  late final Rect blackTray;
  late final double frame;
  late final double trayW;
  late final double barW;
  late final double pointW;
  late final double pointH;
  late final double checkerR;

  /// Column index 0..11 from the left on its row, and whether it is the top row.
  (int col, bool top) _colOf(int abs) {
    if (abs <= 12) {
      // Bottom row: with home on right, 1 is the rightmost column.
      final fromRight = abs - 1;
      return (homeOnRight ? 11 - fromRight : fromRight, false);
    }
    final fromLeft = abs - 13;
    return (homeOnRight ? fromLeft : 11 - fromLeft, true);
  }

  double _colX(int col) {
    final x = field.left + col * pointW + (col >= 6 ? barW : 0);
    return x;
  }

  /// The triangle area of a point.
  Rect pointRect(int abs) {
    final (col, top) = _colOf(abs);
    final x = _colX(col);
    return top
        ? Rect.fromLTWH(x, field.top, pointW, pointH)
        : Rect.fromLTWH(x, field.bottom - pointH, pointW, pointH);
  }

  /// Full-height touch column for a point (half the board).
  Rect pointHitRect(int abs) {
    final (col, top) = _colOf(abs);
    final x = _colX(col);
    final halfH = field.height / 2;
    return top
        ? Rect.fromLTWH(x, field.top, pointW, halfH)
        : Rect.fromLTWH(x, field.top + halfH, pointW, halfH);
  }

  bool isTop(int abs) => abs > 12;

  /// Centre of the [index]-th checker (0 = base) in a stack of [count].
  Offset checkerCenter(Slot slot, int index, int count) {
    final d = checkerR * 2;
    switch (slot) {
      case PointSlot(:final abs):
        final r = pointRect(abs);
        final avail = field.height / 2 - d * 0.6;
        final step = count <= 1 ? d : math.min(d, (avail - d) / (count - 1));
        final cx = r.center.dx;
        final y0 = isTop(abs) ? field.top + checkerR : field.bottom - checkerR;
        final dy = isTop(abs) ? step * index : -step * index;
        return Offset(cx, y0 + dy);
      case BarSlot(:final side):
        // White's bar checkers sit in the top half (they enter at the top).
        final cx = bar.center.dx;
        final step = math.min(
          d * 0.9,
          (field.height * 0.4) / math.max(count, 1),
        );
        if (side == Side.white) {
          return Offset(cx, bar.center.dy - d * 0.9 - step * index);
        }
        return Offset(cx, bar.center.dy + d * 0.9 + step * index);
      case OffSlot(:final side):
        // Borne-off checkers are drawn edge-on as thin slabs.
        final tray = side == Side.white ? whiteTray : blackTray;
        final slab = math.min(tray.height / 16, checkerR * 0.55);
        final cx = tray.center.dx;
        return side == Side.white
            ? Offset(cx, tray.bottom - slab * (index + 0.6))
            : Offset(cx, tray.top + slab * (index + 0.6));
    }
  }

  double offSlab(Side side) {
    final tray = side == Side.white ? whiteTray : blackTray;
    return math.min(tray.height / 16, checkerR * 0.55);
  }

  /// Point under [p] (1..24), 0 for the bar, -1 for a tray, null otherwise.
  int? hitTest(Offset p) {
    if (bar.contains(p)) return 0;
    if (whiteTray.inflate(4).contains(p) || blackTray.inflate(4).contains(p)) {
      return -1;
    }
    for (var abs = 1; abs <= 24; abs++) {
      if (pointHitRect(abs).contains(p)) return abs;
    }
    return null;
  }

  /// Where the dice of [side] are shown.
  Offset diceCenter(Side side) {
    final leftHalf = Rect.fromLTRB(
      field.left,
      field.top,
      bar.left,
      field.bottom,
    );
    final rightHalf = Rect.fromLTRB(
      bar.right,
      field.top,
      field.right,
      field.bottom,
    );
    final white = homeOnRight ? rightHalf : leftHalf;
    final black = homeOnRight ? leftHalf : rightHalf;
    return (side == Side.white ? white : black).center;
  }

  double get dieSize => math.min(pointW * 1.15, field.height * 0.11);
}
