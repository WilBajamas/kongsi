import 'package:flutter/material.dart';

/// The text type scale
abstract final class AppTextStyles {
  static const _family = 'Geist';

  /// Balance headline — the signature money treatment. Tabular.
  static const balanceHero = TextStyle(
    fontFamily: _family,
    fontSize: 42,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.5,
    height: 1,
    fontFeatures: [FontFeature.tabularFigures()],
  );

  /// Inline monetary value (list rows, chips). Tabular.
  static const amount = TextStyle(
    fontFamily: _family,
    fontSize: 16,
    fontWeight: FontWeight.w600,
    fontFeatures: [FontFeature.tabularFigures()],
  );

  static const titleL = TextStyle(
    fontFamily: _family,
    fontSize: 28,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.2,
  );

  static const title = TextStyle(
    fontFamily: _family,
    fontSize: 22,
    fontWeight: FontWeight.w600,
  );

  static const headline = TextStyle(
    fontFamily: _family,
    fontSize: 17,
    fontWeight: FontWeight.w600,
  );

  static const body = TextStyle(
    fontFamily: _family,
    fontSize: 16,
    fontWeight: FontWeight.w400,
  );

  static const callout = TextStyle(
    fontFamily: _family,
    fontSize: 13,
    fontWeight: FontWeight.w500,
  );

  static const caption = TextStyle(
    fontFamily: _family,
    fontSize: 12,
    fontWeight: FontWeight.w400,
  );
}

/// Mapped onto Material slots so stock widgets inherit Geist and our sizing.
const appTextTheme = TextTheme(
  displayMedium: AppTextStyles.balanceHero,
  headlineMedium: AppTextStyles.titleL,
  titleLarge: AppTextStyles.title,
  titleMedium: AppTextStyles.headline,
  bodyLarge: AppTextStyles.body,
  bodyMedium: AppTextStyles.body,
  labelLarge: AppTextStyles.callout,
  bodySmall: AppTextStyles.caption,
);
