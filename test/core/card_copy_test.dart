import 'package:haftnard/core/effects/card_meta.dart';
import 'package:haftnard/core/effects/cards.dart';
import 'package:test/test.dart';

String faDigits(int n) =>
    n.toString().split('').map((d) => '۰۱۲۳۴۵۶۷۸۹'[int.parse(d)]).join();

void main() {
  test('every card has plain-language metadata', () {
    for (final c in kCards) {
      expect(kCardMeta, contains(c.id), reason: c.id);
    }
    expect(kCardMeta, hasLength(kCards.length));
  });

  for (final c in kCards) {
    test('copy: ${c.id} is short and states its duration', () {
      expect(c.descFa.length, lessThanOrEqualTo(90), reason: c.descFa);
      expect(c.descEn.length, lessThanOrEqualTo(90), reason: c.descEn);
      final m = cardMeta(c.id);
      final en = c.descEn.toLowerCase();
      if (m.turns >= 2) {
        expect(en, contains('${m.turns} turns'), reason: c.descEn);
        expect(c.descFa, contains('${faDigits(m.turns)} نوبت'));
      } else if (m.turns == 1) {
        expect(en, contains('next turn'), reason: c.descEn);
        expect(c.descFa, contains('نوبت بعد'), reason: c.descFa);
      } else if (m.turns == CardMeta.untilSeven) {
        expect(en, contains('next 7–7'), reason: c.descEn);
        expect(c.descFa, contains('هفت‌هفت بعد'), reason: c.descFa);
      }
      // No jargon left over from the old copy.
      for (final word in ['relative', 'pips beyond', 'stealable']) {
        expect(en, isNot(contains(word)));
      }
    });
  }
}
