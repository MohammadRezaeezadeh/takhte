import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:haftnard/game/audio.dart';
import 'package:haftnard/meta/meta_state.dart';
import 'package:haftnard/meta/settings.dart';
import 'package:haftnard/ui/app.dart';
import 'package:haftnard/ui/game/overlays.dart';
import 'package:haftnard/ui/screens/problem_report_screen.dart';
import 'package:haftnard/ui/theme.dart';
import 'package:haftnard/ui/widgets/fps_overlay.dart';
import 'package:haftnard/ui/widgets/jewel.dart';
import 'package:haftnard/ui/widgets/menu_background.dart';
import 'package:haftnard/ui/widgets/top_bar.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final s = ref.watch(metaProvider).settings;
    final n = ref.read(metaProvider.notifier);
    void set(Settings v) {
      n.updateSettings(v);
      Sfx.instance
        ..soundOn = v.sound
        ..musicOn = v.music
        ..hapticsOn = v.haptics
        ..sfxVolume = v.sfxVolume;
      unawaited(Sfx.instance.setMusicVolume(v.musicVolume));
      unawaited(Sfx.instance.setAmbient(on: v.music));
    }

    Widget sw(String title, bool v, Settings Function(bool) f, {String? sub}) =>
        SwitchListTile(
          value: v,
          onChanged: (x) => set(f(x)),
          title: Text(title),
          subtitle: sub == null
              ? null
              : Text(
                  sub,
                  style: const TextStyle(color: AppColors.muted, fontSize: 12),
                ),
        );

    Widget slider(
      String title,
      double v,
      Settings Function(double) f, {
      required String key,
    }) => Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: const TextStyle(fontSize: 13, color: AppColors.muted),
            ),
          ),
          Expanded(
            flex: 2,
            child: Slider(
              key: ValueKey(key),
              value: v.clamp(0.0, 1.0),
              onChanged: (x) => set(f(x)),
            ),
          ),
        ],
      ),
    );

    Widget seg<T>(
      String title,
      T value,
      List<(T, String)> options,
      void Function(T) onSel,
    ) => Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title),
          const SizedBox(height: 6),
          SegmentedButton<T>(
            showSelectedIcon: false,
            segments: [
              for (final (v, label) in options)
                ButtonSegment(
                  value: v,
                  label: Text(label, style: const TextStyle(fontSize: 13)),
                ),
            ],
            selected: {value},
            onSelectionChanged: (x) => onSel(x.first),
          ),
        ],
      ),
    );

    return Scaffold(
      body: MenuBackground(
        child: SafeArea(
          child: Column(
            children: [
              ScreenHeader(title: l.settings),
              Expanded(
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 560),
                    child: ListView(
                      padding: const EdgeInsets.all(12),
                      children: [
                        Panel(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Column(
                            children: [
                              seg<String>(l.language, s.language, [
                                ('fa', 'فارسی'),
                                ('en', 'English'),
                              ], (v) => set(s.copyWith(language: v))),
                              seg<bool>(l.boardOrientation, s.homeOnRight, [
                                (true, l.orientationCcw),
                                (false, l.orientationCw),
                              ], (v) => set(s.copyWith(homeOnRight: v))),
                              seg<double>(l.animationSpeed, s.animSpeed, [
                                (0.7, l.speedSlow),
                                (1.0, l.speedNormal),
                                (1.6, l.speedFast),
                              ], (v) => set(s.copyWith(animSpeed: v))),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        Panel(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Column(
                            children: [
                              sw(l.sound, s.sound, (v) => s.copyWith(sound: v)),
                              slider(
                                l.sfxVolume,
                                s.sfxVolume,
                                (v) => s.copyWith(sfxVolume: v),
                                key: 'sfx-volume',
                              ),
                              sw(l.music, s.music, (v) => s.copyWith(music: v)),
                              slider(
                                l.musicVolume,
                                s.musicVolume,
                                (v) => s.copyWith(musicVolume: v),
                                key: 'music-volume',
                              ),
                              sw(
                                l.haptics,
                                s.haptics,
                                (v) => s.copyWith(haptics: v),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        Panel(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Column(
                            children: [
                              sw(
                                l.autoMove,
                                s.autoMove,
                                (v) => s.copyWith(autoMove: v),
                              ),
                              sw(
                                l.showPips,
                                s.showPips,
                                (v) => s.copyWith(showPips: v),
                              ),
                              sw(
                                l.leftHanded,
                                s.leftHanded,
                                (v) => s.copyWith(leftHanded: v),
                              ),
                              sw(
                                l.colorblind,
                                s.colorblind,
                                (v) => s.copyWith(colorblind: v),
                              ),
                              sw(
                                l.highContrast,
                                s.highContrast,
                                (v) => s.copyWith(highContrast: v),
                              ),
                              sw(
                                l.reducedMotion,
                                s.reducedMotion,
                                (v) => s.copyWith(reducedMotion: v),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        Panel(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                l.about,
                                style: const TextStyle(
                                  fontFamily: AppFonts.display,
                                  fontSize: 20,
                                  color: AppColors.goldLight,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                l.aboutText,
                                style: const TextStyle(
                                  fontSize: 13,
                                  height: 1.5,
                                ),
                              ),
                              const SizedBox(height: 8),
                              // Long-press toggles the hidden FPS overlay.
                              GestureDetector(
                                onLongPress: () {
                                  set(s.copyWith(showFps: !s.showFps));
                                  Sfx.instance.haptic(HapticKind.medium);
                                },
                                child: Text(
                                  'HaftNard v$kAppVersion${s.showFps ? ' · FPS' : ''}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppColors.muted,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),
                              JewelButton(
                                key: const ValueKey('report-problem'),
                                label: l.reportProblem,
                                icon: Icons.bug_report,
                                color: AppColors.violet,
                                height: 50,
                                fontSize: 17,
                                onPressed: () => unawaited(
                                  Navigator.of(context).push(
                                    MaterialPageRoute<void>(
                                      builder: (_) =>
                                          const ProblemReportScreen(),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 10),
                              JewelButton(
                                label: l.resetProgress,
                                icon: Icons.delete_forever,
                                color: AppColors.ruby,
                                height: 50,
                                fontSize: 17,
                                onPressed: () async {
                                  final ok = await showPanelDialog<bool>(
                                    context,
                                    (ctx) => Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          l.resetConfirm,
                                          textAlign: TextAlign.center,
                                        ),
                                        const SizedBox(height: 14),
                                        Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            JewelButton(
                                              label: l.cancel,
                                              expand: false,
                                              onPressed: () =>
                                                  Navigator.pop(ctx, false),
                                            ),
                                            const SizedBox(width: 10),
                                            JewelButton(
                                              label: l.confirm,
                                              expand: false,
                                              color: AppColors.ruby,
                                              onPressed: () =>
                                                  Navigator.pop(ctx, true),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  );
                                  if (ok ?? false) n.resetProgress();
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
