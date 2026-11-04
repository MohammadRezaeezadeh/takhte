import 'package:flutter/material.dart';
import 'package:haftnard/ui/app.dart';
import 'package:haftnard/ui/game/overlays.dart';
import 'package:haftnard/ui/theme.dart';

/// "?" panel: one plain line for every element visible during a game.
Future<void> showBoardHelp(BuildContext context, {required bool cube}) {
  final l = context.l10n;
  final rows = <(IconData, String)>[
    (Icons.casino, l.helpDice),
    (Icons.person, l.helpPips),
    (Icons.vertical_align_center, l.helpBar),
    (Icons.inventory_2, l.helpOff),
    if (cube) (Icons.looks_two, l.helpCube),
    (Icons.style, l.helpSeven),
    (Icons.auto_awesome, l.helpEffects),
    (Icons.toll, l.helpCharges),
    (Icons.touch_app, l.helpButtons),
    (Icons.emoji_emotions, l.helpEmotes),
  ];
  return showPanelDialog<void>(
    context,
    (ctx) => ConstrainedBox(
      constraints: BoxConstraints(
        maxWidth: 420,
        maxHeight: MediaQuery.sizeOf(ctx).height * 0.7,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            l.help,
            style: const TextStyle(
              fontFamily: AppFonts.display,
              fontSize: 22,
              color: AppColors.goldLight,
            ),
          ),
          const SizedBox(height: 10),
          Flexible(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  for (final (icon, text) in rows)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(icon, size: 20, color: AppColors.goldLight),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              text,
                              style: const TextStyle(fontSize: 14, height: 1.5),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    ),
  );
}
