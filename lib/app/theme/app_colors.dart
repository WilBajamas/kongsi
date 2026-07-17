import 'package:flutter/material.dart';

/// Single source of truth for colour; the Material ColorScheme is derived from
/// these values.
@immutable
class AppColors extends ThemeExtension<AppColors> {
  const AppColors({
    required this.bg,
    required this.surface,
    required this.surface2,
    required this.ink,
    required this.slate,
    required this.muted,
    required this.hairline,
    required this.accent,
    required this.accentPress,
    required this.credit,
    required this.debit,
  });

  static const light = AppColors(
    bg: Color(0xFFF6F6F4),
    surface: Color(0xFFFFFFFF),
    surface2: Color(0xFFEFEFEC),
    ink: Color(0xFF17171A),
    slate: Color(0xFF6C6C72),
    muted: Color(0xFF9A9AA0),
    hairline: Color(0x14000000),
    accent: Color(0xFF1B5FE0),
    accentPress: Color(0xFF1547B0),
    credit: Color(0xFF1E8E5A),
    debit: Color(0xFFC4443A),
  );

  static const dark = AppColors(
    bg: Color(0xFF0C0C0D),
    surface: Color(0xFF17171A),
    surface2: Color(0xFF202024),
    ink: Color(0xFFF4F4F3),
    slate: Color(0xFF9C9CA2),
    muted: Color(0xFF6C6C72),
    hairline: Color(0x1AFFFFFF),
    accent: Color(0xFF5A8CFF),
    accentPress: Color(0xFF4A7CF0),
    credit: Color(0xFF34C77B),
    debit: Color(0xFFE5675C),
  );

  final Color bg;
  final Color surface;
  final Color surface2;
  final Color ink;
  final Color slate;
  final Color muted;
  final Color hairline;
  final Color accent;
  final Color accentPress;
  final Color credit;
  final Color debit;

  @override
  AppColors copyWith({
    Color? bg,
    Color? surface,
    Color? surface2,
    Color? ink,
    Color? slate,
    Color? muted,
    Color? hairline,
    Color? accent,
    Color? accentPress,
    Color? credit,
    Color? debit,
  }) {
    return AppColors(
      bg: bg ?? this.bg,
      surface: surface ?? this.surface,
      surface2: surface2 ?? this.surface2,
      ink: ink ?? this.ink,
      slate: slate ?? this.slate,
      muted: muted ?? this.muted,
      hairline: hairline ?? this.hairline,
      accent: accent ?? this.accent,
      accentPress: accentPress ?? this.accentPress,
      credit: credit ?? this.credit,
      debit: debit ?? this.debit,
    );
  }

  @override
  AppColors lerp(ThemeExtension<AppColors>? other, double t) {
    if (other is! AppColors) return this;
    return AppColors(
      bg: Color.lerp(bg, other.bg, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      surface2: Color.lerp(surface2, other.surface2, t)!,
      ink: Color.lerp(ink, other.ink, t)!,
      slate: Color.lerp(slate, other.slate, t)!,
      muted: Color.lerp(muted, other.muted, t)!,
      hairline: Color.lerp(hairline, other.hairline, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
      accentPress: Color.lerp(accentPress, other.accentPress, t)!,
      credit: Color.lerp(credit, other.credit, t)!,
      debit: Color.lerp(debit, other.debit, t)!,
    );
  }
}
