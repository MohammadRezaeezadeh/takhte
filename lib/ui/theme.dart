import 'package:flutter/material.dart';

/// Palette: "Persian mysticism meets modern arcade".
abstract final class AppColors {
  static const night = Color(0xFF0B0F1F);
  static const ink = Color(0xFF141A33);
  static const inkLight = Color(0xFF1E2748);
  static const lapis = Color(0xFF1B2A6B);
  static const turquoise = Color(0xFF1FA3A3);
  static const turquoiseLight = Color(0xFF6CF2FF);
  static const gold = Color(0xFFD4AF37);
  static const goldLight = Color(0xFFFFD36B);
  static const ivory = Color(0xFFF3E9D2);
  static const ruby = Color(0xFFC2324A);
  static const emerald = Color(0xFF1E9E6A);
  static const violet = Color(0xFF6B4BD8);
  static const muted = Color(0xFF9AA3C7);

  static Color rarity(int index) => switch (index) {
    0 => const Color(0xFFE9E1CC),
    1 => turquoiseLight,
    2 => const Color(0xFFB794FF),
    _ => goldLight,
  };
}

abstract final class AppFonts {
  static const body = 'Vazirmatn';
  static const display = 'Lalezar';
  static const logoLatin = 'Cinzel';
}

ThemeData buildTheme({required bool highContrast}) {
  final base = ThemeData(
    brightness: Brightness.dark,
    useMaterial3: true,
    fontFamily: AppFonts.body,
    scaffoldBackgroundColor: AppColors.night,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.turquoise,
      brightness: Brightness.dark,
      primary: AppColors.goldLight,
      secondary: AppColors.turquoise,
      surface: AppColors.ink,
    ),
  );
  final text = base.textTheme.apply(
    bodyColor: highContrast ? Colors.white : AppColors.ivory,
    displayColor: highContrast ? Colors.white : AppColors.ivory,
    fontFamily: AppFonts.body,
  );
  return base.copyWith(
    textTheme: text.copyWith(
      displayLarge: text.displayLarge?.copyWith(fontFamily: AppFonts.display),
      displayMedium: text.displayMedium?.copyWith(fontFamily: AppFonts.display),
      headlineLarge: text.headlineLarge?.copyWith(fontFamily: AppFonts.display),
      headlineMedium: text.headlineMedium?.copyWith(
        fontFamily: AppFonts.display,
      ),
      headlineSmall: text.headlineSmall?.copyWith(fontFamily: AppFonts.display),
      titleLarge: text.titleLarge?.copyWith(fontFamily: AppFonts.display),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.selected)
            ? AppColors.goldLight
            : AppColors.muted,
      ),
      trackColor: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.selected)
            ? AppColors.gold.withValues(alpha: 0.5)
            : AppColors.inkLight,
      ),
    ),
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: {TargetPlatform.android: FadeForwardsPageTransitionsBuilder()},
    ),
    snackBarTheme: const SnackBarThemeData(
      backgroundColor: AppColors.inkLight,
      contentTextStyle: TextStyle(
        color: AppColors.ivory,
        fontFamily: AppFonts.body,
      ),
      behavior: SnackBarBehavior.floating,
    ),
  );
}
