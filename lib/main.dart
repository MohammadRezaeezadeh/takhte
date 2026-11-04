import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:haftnard/game/audio.dart';
import 'package:haftnard/meta/meta_state.dart';
import 'package:haftnard/meta/problem_log.dart';
import 'package:haftnard/meta/save.dart';
import 'package:haftnard/ui/app.dart';
import 'package:haftnard/ui/widgets/fps_overlay.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  ProblemLog.instance
    ..version = kAppVersion
    ..install();
  Sfx.instance.onLog = (m) => ProblemLog.instance.add(ProblemKind.audio, m);
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  final save = SaveService(FileSaveStore());
  await save.load();
  final s = save.data.settings;
  Sfx.instance
    ..soundOn = s.sound
    ..musicOn = s.music
    ..hapticsOn = s.haptics
    ..musicVolume = s.musicVolume
    ..sfxVolume = s.sfxVolume;
  unawaited(Sfx.instance.preload());
  runApp(
    ProviderScope(
      overrides: [saveServiceProvider.overrideWithValue(save)],
      child: const HaftNardApp(),
    ),
  );
}
