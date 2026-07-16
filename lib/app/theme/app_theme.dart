import 'package:flutter/material.dart';
import 'package:kongsi/app/theme/app_colors.dart';
import 'package:kongsi/app/theme/app_theme_dimensions.dart';
import 'package:kongsi/app/theme/app_typography.dart';

/// Assembles the light and dark [ThemeData].

abstract final class AppTheme {
  static final ThemeData light = _build(AppColors.light, Brightness.light);
  static final ThemeData dark = _build(AppColors.dark, Brightness.dark);

  static ThemeData _build(AppColors c, Brightness brightness) {
    // Determines if the current theme is light or dark.
    final isLight = brightness == Brightness.light;

    // Generates a [ColorScheme] based on the provided [AppColors].
    final scheme =
        ColorScheme.fromSeed(
          seedColor: c.accent,
          brightness: brightness,
        ).copyWith(
          primary: c.accent,
          onPrimary: isLight
              ? const Color(0xFFFFFFFF)
              : const Color(0xFF0C0C0D),
          surface: c.surface,
          onSurface: c.ink,
          onSurfaceVariant: c.slate,
          surfaceContainerLowest: c.surface,
          surfaceContainerLow: c.surface2,
          surfaceContainer: c.surface2,
          surfaceContainerHigh: c.surface2,
          surfaceContainerHighest: c.surface2,
          outline: c.muted,
          outlineVariant: c.hairline,
          error: c.debit,
        );

    // Setting the default themes and styles for common widgets.
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: c.bg,
      fontFamily: 'Geist',
      textTheme: appTextTheme,
      extensions: [c],
      cardTheme: CardThemeData(
        color: c.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(WidgetRadius.card),
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(WidgetRadius.sheet),
          ),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(WidgetRadius.button),
          ),
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: c.bg,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
      ),
    );
  }
}
