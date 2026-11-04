import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:haftnard/game/audio.dart';
import 'package:haftnard/l10n/gen/app_localizations.dart';
import 'package:haftnard/meta/meta_state.dart';
import 'package:haftnard/ui/screens/splash_screen.dart';
import 'package:haftnard/ui/theme.dart';
import 'package:haftnard/ui/widgets/fps_overlay.dart';

class HaftNardApp extends ConsumerStatefulWidget {
  const HaftNardApp({super.key, this.home});

  /// Overrides the first screen (tests).
  final Widget? home;

  @override
  ConsumerState<HaftNardApp> createState() => _HaftNardAppState();
}

class _HaftNardAppState extends ConsumerState<HaftNardApp>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
        unawaited(ref.read(saveServiceProvider).flush());
        unawaited(Sfx.instance.onPause());
      case AppLifecycleState.hidden:
        unawaited(Sfx.instance.onPause());
      case AppLifecycleState.resumed:
        // Android may have released the players while in the background (a
        // call, screen off): rebuild them all.
        unawaited(Sfx.instance.onResume());
      case AppLifecycleState.inactive:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(metaProvider.select((m) => m.settings));
    final locale = switch (settings.language) {
      'en' => const Locale('en'),
      'fa' => const Locale('fa'),
      _ => null,
    };
    return MaterialApp(
      title: 'HaftNard',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(highContrast: settings.highContrast),
      locale: locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      localeResolutionCallback: (device, supported) {
        if (locale != null) return locale;
        if (device?.languageCode == 'fa') return const Locale('fa');
        return const Locale('en');
      },
      builder: (context, child) {
        final mq = MediaQuery.of(context);
        return MediaQuery(
          data: mq.copyWith(
            disableAnimations: settings.reducedMotion || mq.disableAnimations,
            textScaler: mq.textScaler.clamp(maxScaleFactor: 1.3),
          ),
          child: settings.showFps
              ? Stack(
                  children: [
                    child!,
                    const Positioned(top: 30, left: 6, child: FpsOverlay()),
                  ],
                )
              : child!,
        );
      },
      home: widget.home ?? const SplashScreen(),
    );
  }
}

/// Fade + slight scale page transition used across the app.
Route<T> fadeRoute<T>(Widget page) => PageRouteBuilder<T>(
  transitionDuration: const Duration(milliseconds: 380),
  reverseTransitionDuration: const Duration(milliseconds: 280),
  pageBuilder: (_, _, _) => page,
  transitionsBuilder: (_, a, _, child) {
    final curved = CurvedAnimation(parent: a, curve: Curves.easeOutCubic);
    return FadeTransition(
      opacity: curved,
      child: ScaleTransition(
        scale: Tween<double>(begin: 0.96, end: 1).animate(curved),
        child: child,
      ),
    );
  },
);

extension L10nX on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
  String get lang => Localizations.localeOf(this).languageCode;
}
