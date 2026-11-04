import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:haftnard/game/audio.dart';
import 'package:haftnard/meta/cosmetics.dart';
import 'package:haftnard/meta/meta_state.dart';
import 'package:haftnard/ui/app.dart';
import 'package:haftnard/ui/screens/store_screen.dart';
import 'package:haftnard/ui/theme.dart';
import 'package:haftnard/ui/widgets/jewel.dart';
import 'package:haftnard/ui/widgets/menu_background.dart';
import 'package:haftnard/ui/widgets/previews.dart';
import 'package:haftnard/ui/widgets/top_bar.dart';

class LockerScreen extends ConsumerWidget {
  const LockerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final lang = context.lang;
    final meta = ref.watch(metaProvider);
    final n = ref.read(metaProvider.notifier);
    final p = meta.profile;
    return Scaffold(
      body: MenuBackground(
        child: SafeArea(
          child: Column(
            children: [
              ScreenHeader(
                title: l.locker,
                trailing: JewelIconButton(
                  icon: Icons.shuffle,
                  tooltip: l.randomizeLoadout,
                  onPressed: () {
                    n.randomizeLoadout();
                    Sfx.instance.play('magic');
                  },
                ),
              ),
              AspectRatio(
                aspectRatio: 1.5,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: LoadoutPreview(loadout: p.equipped),
                  ),
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(12),
                  children: [
                    for (final t in ItemType.values)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              t == ItemType.cardFrame
                                  ? '${itemTypeLabel(context, t)} ✦'
                                  : itemTypeLabel(context, t),
                              style: const TextStyle(
                                fontFamily: AppFonts.display,
                                fontSize: 20,
                                color: AppColors.goldLight,
                              ),
                            ),
                            const SizedBox(height: 6),
                            SizedBox(
                              height: 116,
                              child: ListView(
                                scrollDirection: Axis.horizontal,
                                children: [
                                  for (final i in itemsOfType(
                                    t,
                                  ).where((i) => p.owned.contains(i.id)))
                                    _LockerTile(
                                      item: i,
                                      equipped: p.equipped[t] == i.id,
                                      label: i.name(lang),
                                      onTap: () {
                                        n.equip(t, i.id);
                                        Sfx.instance.play('ui_confirm');
                                      },
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LockerTile extends StatelessWidget {
  const _LockerTile({
    required this.item,
    required this.equipped,
    required this.label,
    required this.onTap,
  });
  final CosmeticItem item;
  final bool equipped;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: equipped,
      label: label,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 120,
          margin: const EdgeInsetsDirectional.only(end: 8),
          decoration: BoxDecoration(
            color: AppColors.ink,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: equipped ? AppColors.goldLight : Colors.white12,
              width: equipped ? 2.5 : 1,
            ),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              Expanded(child: ItemPreview(item: item)),
              Padding(
                padding: const EdgeInsets.all(4),
                child: Row(
                  children: [
                    if (equipped)
                      const Icon(
                        Icons.check_circle,
                        size: 14,
                        color: AppColors.goldLight,
                      ),
                    Expanded(
                      child: Text(
                        label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
