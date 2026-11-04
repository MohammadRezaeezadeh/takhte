import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:haftnard/meta/meta_state.dart';
import 'package:haftnard/ui/app.dart';
import 'package:haftnard/ui/theme.dart';
import 'package:haftnard/ui/widgets/jewel.dart';

/// Level badge with XP bar and currencies.
class ProfileBar extends ConsumerWidget {
  const ProfileBar({super.key, this.leading});
  final Widget? leading;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = ref.watch(metaProvider).profile;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          ?leading,
          Container(
            width: 44,
            height: 44,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const RadialGradient(
                colors: [AppColors.violet, AppColors.lapis],
              ),
              border: Border.all(color: AppColors.goldLight, width: 2),
            ),
            child: Text(
              formatNumber(p.level, context.lang),
              style: const TextStyle(
                fontFamily: AppFonts.display,
                fontSize: 20,
                color: AppColors.goldLight,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  context.l10n.level(p.level),
                  style: const TextStyle(fontSize: 12, color: AppColors.muted),
                ),
                const SizedBox(height: 4),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: p.levelProgress,
                    minHeight: 7,
                    backgroundColor: Colors.black45,
                    valueColor: const AlwaysStoppedAnimation(
                      AppColors.goldLight,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          CurrencyChip(amount: p.coins, gem: false),
          const SizedBox(width: 6),
          CurrencyChip(amount: p.gems, gem: true),
        ],
      ),
    );
  }
}

/// Standard screen header with a back button and title.
class ScreenHeader extends StatelessWidget {
  const ScreenHeader({required this.title, super.key, this.trailing});
  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 4),
      child: Row(
        children: [
          JewelIconButton(
            icon: Directionality.of(context) == TextDirection.rtl
                ? Icons.arrow_forward
                : Icons.arrow_back,
            tooltip: context.l10n.back,
            onPressed: () => Navigator.of(context).maybePop(),
          ),
          Expanded(child: OrnateTitle(title, size: 28)),
          SizedBox(width: 48, child: trailing),
        ],
      ),
    );
  }
}
