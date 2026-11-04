import 'package:flutter/material.dart';
import 'package:haftnard/core/effects/card_meta.dart';
import 'package:haftnard/core/effects/cards.dart';
import 'package:haftnard/l10n/gen/app_localizations.dart';
import 'package:haftnard/ui/app.dart';
import 'package:haftnard/ui/theme.dart';
import 'package:haftnard/ui/widgets/jewel.dart';

/// "⏳ ۲ نوبت", "نوبت بعد", "تا هفت‌هفت بعدی" or "فوری".
String durationLabel(AppLocalizations l, String lang, String cardId) {
  final t = cardMeta(cardId).turns;
  if (t == CardMeta.untilSeven) return l.durSeven;
  if (t == 1) return l.durNext;
  if (t > 1) return l.durTurns(formatNumber(t, lang));
  return l.durInstant;
}

String whoLabel(AppLocalizations l, String cardId) =>
    switch (cardMeta(cardId).who) {
      CardWho.opponent => l.tagOpponent,
      CardWho.self => l.tagSelf,
      CardWho.board => l.tagBoard,
    };

IconData whoIcon(String cardId) => switch (cardMeta(cardId).who) {
  CardWho.opponent => Icons.gps_fixed,
  CardWho.self => Icons.person,
  CardWho.board => Icons.grid_view,
};

/// Rarity · duration · target chips under a card's sentence.
class CardTags extends StatelessWidget {
  const CardTags({required this.card, this.compact = false, super.key});
  final CardDef card;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final lang = context.lang;
    final fs = compact ? 10.0 : 12.0;
    Widget chip(IconData? icon, String text, Color color) => Container(
      padding: EdgeInsets.symmetric(horizontal: compact ? 5 : 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.7)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: fs + 2, color: color),
            const SizedBox(width: 3),
          ],
          Text(
            text,
            style: TextStyle(fontSize: fs, color: AppColors.ivory),
          ),
        ],
      ),
    );
    final rarityColor = AppColors.rarity(card.rarity.index);
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 4,
      runSpacing: 4,
      children: [
        if (!compact) chip(null, _rarityName(l, card.rarity), rarityColor),
        chip(
          Icons.hourglass_bottom,
          durationLabel(l, lang, card.id),
          AppColors.goldLight,
        ),
        chip(whoIcon(card.id), whoLabel(l, card.id), AppColors.turquoiseLight),
      ],
    );
  }

  static String _rarityName(AppLocalizations l, Rarity r) => switch (r) {
    Rarity.common => l.rarityCommon,
    Rarity.rare => l.rarityRare,
    Rarity.epic => l.rarityEpic,
    Rarity.legendary => l.rarityLegendary,
  };
}
