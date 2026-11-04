// Renders board/checker/dice art to PNGs for visual inspection.
// Run: flutter test test/visual --dart-define=ART_OUT=/path/to/dir
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:haftnard/core/rules/board.dart';
import 'package:haftnard/core/rules/types.dart';
import 'package:haftnard/game/layout.dart';
import 'package:haftnard/game/themes/board_themes.dart';
import 'package:haftnard/game/themes/pieces.dart';

const outDir = String.fromEnvironment('ART_OUT');

Future<void> savePng(
  String name,
  int w,
  int h,
  void Function(Canvas) paint,
) async {
  final rec = ui.PictureRecorder();
  final c = Canvas(rec);
  paint(c);
  final img = await rec.endRecording().toImage(w, h);
  final data = await img.toByteData(format: ui.ImageByteFormat.png);
  if (outDir.isEmpty) return;
  File('$outDir/$name.png').writeAsBytesSync(data!.buffer.asUint8List());
}

void paintBoardWithCheckers(
  Canvas c,
  Size size,
  String themeId,
  String checkerId,
) {
  c.drawRect(Offset.zero & size, Paint()..color = const Color(0xFF0B0F1F));
  final l = BoardLayout(size);
  BoardArt(boardTheme(themeId), l).paint(c);
  final b = Board.initial();
  final st = checkerStyle(checkerId);
  for (var abs = 1; abs <= 24; abs++) {
    final (side, n) = b.atAbsolute(abs);
    if (side == null) continue;
    for (var i = 0; i < n; i++) {
      paintChecker(
        c,
        l.checkerCenter(PointSlot(abs), i, n),
        l.checkerR,
        side,
        st,
      );
    }
  }
  final ds = diceStyle('dice_bone');
  final dc = l.diceCenter(Side.white);
  paintDie(c, dc - Offset(l.dieSize * 0.7, 0), l.dieSize, 5, ds, angle: 0.2);
  paintDie(c, dc + Offset(l.dieSize * 0.7, 0), l.dieSize, 7, ds, angle: -0.15);
}

void main() {
  testWidgets('render all boards', (tester) async {
    await tester.runAsync(() async {
      const size = Size(780, 680);
      final checkers = kCheckerStyles.keys.toList();
      var i = 0;
      for (final id in kBoardThemes.keys) {
        await savePng(
          'board_$id',
          780,
          680,
          (c) => paintBoardWithCheckers(
            c,
            size,
            id,
            checkers[i++ % checkers.length],
          ),
        );
      }
    });
  });

  testWidgets('render pieces sheet', (tester) async {
    await tester.runAsync(() async {
      await savePng('pieces', 900, 420, (c) {
        c.drawRect(
          const Rect.fromLTWH(0, 0, 900, 420),
          Paint()..color = const Color(0xFF3A0E15),
        );
        var x = 50.0;
        for (final st in kCheckerStyles.values) {
          paintChecker(c, Offset(x, 60), 36, Side.white, st);
          paintChecker(c, Offset(x, 150), 36, Side.black, st);
          x += 95;
        }
        x = 50;
        for (final ds in kDiceStyles.values) {
          for (var v = 1; v <= 2; v++) {
            paintDie(c, Offset(x, 230.0 + v * 60), 50, v == 1 ? 6 : 3, ds);
          }
          x += 110;
        }
        paintDie(
          c,
          const Offset(820, 300),
          70,
          7,
          kDiceStyles.values.first,
          time: 1,
        );
      });
    });
  });
}
