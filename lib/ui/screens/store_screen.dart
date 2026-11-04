import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:haftnard/game/audio.dart';
import 'package:haftnard/meta/cosmetics.dart';
import 'package:haftnard/meta/meta_state.dart';
import 'package:haftnard/meta/purchase.dart';
import 'package:haftnard/ui/app.dart';
import 'package:haftnard/ui/theme.dart';
import 'package:haftnard/ui/widgets/jewel.dart';
import 'package:haftnard/ui/widgets/menu_background.dart';
import 'package:haftnard/ui/widgets/previews.dart';
import 'package:haftnard/ui/widgets/top_bar.dart';

String itemTypeLabel(BuildContext context, ItemType t) {
  final l = context.l10n;
  return switch (t) {
    ItemType.board => l.storeBoards,
    ItemType.environment => l.storeEnvironments,
    ItemType.checker => l.storeCheckers,
    ItemType.dice => l.storeDice,
    ItemType.cardBack => l.storeCardBacks,
    ItemType.cardFrame => l.storeCardBacks,
    ItemType.victory => l.storeVictory,
    ItemType.emote => l.storeEmotes,
  };
}

class StoreScreen extends ConsumerWidget {
  const StoreScreen({super.key});

  static const List<ItemType> _tabs = [
    ItemType.board,
    ItemType.environment,
    ItemType.checker,
    ItemType.dice,
    ItemType.cardBack,
    ItemType.victory,
    ItemType.emote,
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    return DefaultTabController(
      length: _tabs.length + 1,
      child: Scaffold(
        body: MenuBackground(
          child: SafeArea(
            child: Column(
              children: [
                ScreenHeader(title: l.store),
                const ProfileBar(),
                TabBar(
                  isScrollable: true,
                  tabAlignment: TabAlignment.start,
                  labelColor: AppColors.goldLight,
                  unselectedLabelColor: AppColors.muted,
                  indicatorColor: AppColors.goldLight,
                  labelStyle: const TextStyle(
                    fontFamily: AppFonts.display,
                    fontSize: 18,
                  ),
                  tabs: [
                    Tab(text: l.dailyShop),
                    for (final t in _tabs) Tab(text: itemTypeLabel(context, t)),
                  ],
                ),
                Expanded(
                  child: TabBarView(
                    children: [
                      const _DailyTab(),
                      for (final t in _tabs)
                        _ItemGrid(
                          items: [
                            ...itemsOfType(t),
                            if (t == ItemType.cardBack)
                              ...itemsOfType(ItemType.cardFrame),
                          ],
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DailyTab extends ConsumerWidget {
  const _DailyTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    ref.watch(metaProvider);
    final n = ref.read(metaProvider.notifier);
    final now = DateTime.now();
    final daily = n.dailyShop(now);
    final midnight = DateTime(now.year, now.month, now.day + 1);
    final left = midnight.difference(now);
    final time =
        '${left.inHours}:${(left.inMinutes % 60).toString().padLeft(2, '0')}';
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        Text(
          l.refreshesIn(context.lang == 'fa' ? toPersianDigits(time) : time),
          textAlign: TextAlign.center,
          style: const TextStyle(color: AppColors.muted),
        ),
        const SizedBox(height: 8),
        _ItemGrid(items: daily, daily: true, shrink: true),
        const SizedBox(height: 16),
        OrnateTitle(l.storeBundles, size: 24),
        const SizedBox(height: 8),
        for (final b in kBundles) _BundleTile(bundle: b),
      ],
    );
  }
}

class _BundleTile extends ConsumerWidget {
  const _BundleTile({required this.bundle});
  final Bundle bundle;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final lang = context.lang;
    final p = ref.watch(metaProvider).profile;
    final owned = bundle.items.every(p.owned.contains);
    final full = bundle.items.fold<int>(
      0,
      (a, id) => a + (itemById(id)?.coins ?? 0),
    );
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Panel(
        glow: AppColors.turquoiseLight,
        padding: const EdgeInsets.all(10),
        child: Row(
          children: [
            SizedBox(
              width: 120,
              height: 84,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: ItemPreview(item: itemById(bundle.items.first)!),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    bundle.name(lang),
                    style: const TextStyle(
                      fontFamily: AppFonts.display,
                      fontSize: 20,
                      color: AppColors.goldLight,
                    ),
                  ),
                  Text(
                    bundle.items
                        .map((id) => itemById(id)!.name(lang))
                        .join(' · '),
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.muted,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                        formatNumber(full, lang),
                        style: const TextStyle(
                          decoration: TextDecoration.lineThrough,
                          color: AppColors.muted,
                        ),
                      ),
                      CurrencyChip(amount: bundle.coins, gem: false),
                    ],
                  ),
                ],
              ),
            ),
            JewelButton(
              label: owned ? l.owned : l.buy,
              expand: false,
              height: 48,
              fontSize: 16,
              color: AppColors.emerald,
              onPressed: owned
                  ? null
                  : () {
                      final ok = ref
                          .read(metaProvider.notifier)
                          .buyBundle(bundle);
                      Sfx.instance.play(ok ? 'coin' : 'ui_back');
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(ok ? l.purchased : l.notEnough)),
                      );
                    },
            ),
          ],
        ),
      ),
    );
  }
}

class _ItemGrid extends ConsumerWidget {
  const _ItemGrid({
    required this.items,
    this.daily = false,
    this.shrink = false,
  });
  final List<CosmeticItem> items;
  final bool daily;
  final bool shrink;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final width = MediaQuery.sizeOf(context).width;
    final cols = (width / 200).floor().clamp(2, 5);
    return GridView.builder(
      shrinkWrap: shrink,
      physics: shrink ? const NeverScrollableScrollPhysics() : null,
      padding: const EdgeInsets.all(10),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: cols,
        childAspectRatio: 0.78,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemCount: items.length,
      itemBuilder: (_, i) => StoreTile(item: items[i], daily: daily),
    );
  }
}

class StoreTile extends ConsumerWidget {
  const StoreTile({required this.item, super.key, this.daily = false});
  final CosmeticItem item;
  final bool daily;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final lang = context.lang;
    final meta = ref.watch(metaProvider);
    final n = ref.read(metaProvider.notifier);
    final p = meta.profile;
    final owned = p.owned.contains(item.id);
    final locked = p.level < item.unlockLevel;
    final gemPrice = item.gems > 0 && item.coins == 0;
    final price = daily
        ? n.dailyPrice(item)
        : (gemPrice ? item.gems : item.coins);
    return GestureDetector(
      onTap: () => unawaited(_details(context, ref)),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.ink,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: item.tier == ItemTier.standard
                ? Colors.white12
                : AppColors.goldLight.withValues(alpha: 0.6),
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  ItemPreview(item: item, loadout: p.equipped),
                  if (locked)
                    ColoredBox(
                      color: Colors.black54,
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.lock, color: AppColors.muted),
                            Text(
                              l.level(item.unlockLevel),
                              style: const TextStyle(fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 6, 8, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name(lang),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 4),
                  if (owned)
                    Text(
                      l.owned,
                      style: const TextStyle(
                        color: AppColors.emerald,
                        fontWeight: FontWeight.w700,
                      ),
                    )
                  else if (item.isFree)
                    Text(l.free)
                  else
                    CurrencyChip(amount: price, gem: gemPrice && !daily),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _details(BuildContext context, WidgetRef ref) async {
    final l = context.l10n;
    final lang = context.lang;
    final n = ref.read(metaProvider.notifier);
    final p = n.profile;
    final owned = p.owned.contains(item.id);
    final locked = p.level < item.unlockLevel;
    await showDialog<void>(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        child: Panel(
          glow: AppColors.goldLight,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                item.name(lang),
                style: const TextStyle(
                  fontFamily: AppFonts.display,
                  fontSize: 26,
                  color: AppColors.goldLight,
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 200,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: ItemPreview(item: item, loadout: p.equipped),
                ),
              ),
              if (item.desc(lang).isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(item.desc(lang), textAlign: TextAlign.center),
              ],
              const SizedBox(height: 14),
              if (owned)
                JewelButton(
                  label: p.equipped[item.type] == item.id
                      ? l.equipped
                      : l.equip,
                  color: AppColors.emerald,
                  onPressed: () {
                    n.equip(item.type, item.id);
                    Navigator.pop(ctx);
                  },
                )
              else if (locked)
                Text(
                  l.level(item.unlockLevel),
                  style: const TextStyle(color: AppColors.muted),
                )
              else
                JewelButton(
                  label: l.buy,
                  icon: Icons.shopping_bag,
                  color: AppColors.emerald,
                  onPressed: () async {
                    final ok = await PurchaseProviders.current.purchase(
                      n,
                      item,
                      priceOverride: daily ? n.dailyPrice(item) : null,
                    );
                    Sfx.instance.play(ok ? 'coin' : 'ui_back');
                    if (ok) n.equip(item.type, item.id);
                    if (ctx.mounted) Navigator.pop(ctx);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(ok ? l.purchased : l.notEnough)),
                      );
                    }
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }
}
