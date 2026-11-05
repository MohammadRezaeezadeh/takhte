// Renders every card icon at HUD size (32 px) and card size (96 px) with its
// name, for the icon clarity audit (docs/cards/icons/).
//   flutter test test/visual/icon_sheet_test.dart --dart-define=ICON_OUT=docs/cards/icons/after.png
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:haftnard/core/effects/cards.dart';
import 'package:haftnard/ui/theme.dart';
import 'package:haftnard/ui/widgets/card_art.dart';

import 'screens_test.dart' show loadFonts;

const out = String.fromEnvironment('ICON_OUT');

void main() {
  setUpAll(loadFonts);

  test('every card has a distinct glyph', () {
    expect(kCards.map((c) => c.glyph).toSet(), hasLength(kCards.length));
  });

  testWidgets('icon sheet', (t) async {
    if (out.isEmpty) return;
    const cols = 8;
    const cellW = 150.0;
    const cellH = 150.0;
    final rows = (kCards.length / cols).ceil();
    await t.runAsync(() async {
      final rec = ui.PictureRecorder();
      final c = Canvas(rec)
        ..drawRect(
          const Rect.fromLTWH(0, 0, cols * cellW, 9999),
          Paint()..color = const Color(0xFF14121C),
        );
      for (var i = 0; i < kCards.length; i++) {
        final card = kCards[i];
        final x = (i % cols) * cellW;
        final y = (i ~/ cols) * cellH;
        final color = AppColors.rarity(card.rarity.index);
        // Card size.
        c
          ..save()
          ..translate(x + 8, y + 8);
        CardGlyphPainter(card.glyph, color).paint(c, const Size(96, 96));
        c.restore();
        // HUD chip size, on the chip's dark disc.
        c.drawCircle(
          Offset(x + 126, y + 26),
          18,
          Paint()..color = const Color(0x8A000000),
        );
        c
          ..save()
          ..translate(x + 110, y + 10);
        CardGlyphPainter(card.glyph, color).paint(c, const Size(32, 32));
        c.restore();
        final tp = TextPainter(
          text: TextSpan(
            text: card.nameEn,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontFamily: 'Vazirmatn',
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout(maxWidth: cellW - 8);
        tp
          ..paint(c, Offset(x + 6, y + 112))
          ..dispose();
      }
      final img = await rec.endRecording().toImage(
        (cols * cellW).toInt(),
        (rows * cellH).toInt(),
      );
      final png = await img.toByteData(format: ui.ImageByteFormat.png);
      File(out).writeAsBytesSync(png!.buffer.asUint8List());
    });
  });
}
