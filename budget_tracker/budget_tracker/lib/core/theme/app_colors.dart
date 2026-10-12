import 'package:flutter/material.dart';

/// One full set of semantic colors — either the light or the dark palette.
/// Previously `AppColors` and `AppColorsDark` were two separate classes of
/// unrelated static constants, and widgets across the app hardcoded
/// `AppColors.textPrimary` etc. directly. That's what caused dark-mode text
/// to render in *light-mode* colors regardless of the device's actual
/// theme — the widget had no way to know which palette it should be using.
/// Now there's one shape ([AppColorPalette]) with a light and a dark
/// instance, and widgets ask for the right one via [AppColorsContext] below.
class AppColorPalette {
  final Color background;
  final Color surface;
  final Color surfaceVariant;
  final Color textPrimary;
  final Color textSecondary;
  final Color textTertiary;
  final Color textDisabled;
  final Color primary;
  final Color primaryLight;
  final Color primaryDark;
  final Color positive;
  final Color positiveLight;
  final Color negative;
  final Color negativeLight;
  final Color warning;
  final Color warningLight;
  final Color border;
  final Color divider;
  final Color interactive;
  final Color interactiveHover;
  final Color interactivePressed;

  const AppColorPalette({
    required this.background,
    required this.surface,
    required this.surfaceVariant,
    required this.textPrimary,
    required this.textSecondary,
    required this.textTertiary,
    required this.textDisabled,
    required this.primary,
    required this.primaryLight,
    required this.primaryDark,
    required this.positive,
    required this.positiveLight,
    required this.negative,
    required this.negativeLight,
    required this.warning,
    required this.warningLight,
    required this.border,
    required this.divider,
    required this.interactive,
    required this.interactiveHover,
    required this.interactivePressed,
  });
}

class AppColors {
  AppColors._();

  /// Light-mode palette: curated slate neutrals with calibrated emerald and rose accents.
  static const light = AppColorPalette(
    background: Color(0xFFF8FAFC),
    surface: Color(0xFFFFFFFF),
    surfaceVariant: Color(0xFFF1F5F9),
    textPrimary: Color(0xFF0F172A),
    textSecondary: Color(0xFF475569),
    textTertiary: Color(0xFF94A3B8),
    textDisabled: Color(0xFFCBD5E1),
    primary: Color(0xFF2563EB),
    primaryLight: Color(0xFF60A5FA),
    primaryDark: Color(0xFF1D4ED8),
    positive: Color(0xFF059669),
    positiveLight: Color(0xFFD1FAE5),
    negative: Color(0xFFE11D48),
    negativeLight: Color(0xFFFFE4E6),
    warning: Color(0xFFD97706),
    warningLight: Color(0xFFFEF3C7),
    border: Color(0xFFE2E8F0),
    divider: Color(0xFFF1F5F9),
    interactive: Color(0xFF2563EB),
    interactiveHover: Color(0xFF1D4ED8),
    interactivePressed: Color(0xFF1E40AF),
  );

  /// Dark-mode palette: deep slate night surfaces with crisp WCAG AA contrast.
  static const dark = AppColorPalette(
    background: Color(0xFF0F172A),
    surface: Color(0xFF1E293B),
    surfaceVariant: Color(0xFF334155),
    textPrimary: Color(0xFFF8FAFC),
    textSecondary: Color(0xFF94A3B8),
    textTertiary: Color(0xFF64748B),
    textDisabled: Color(0xFF475569),
    primary: Color(0xFF3B82F6),
    primaryLight: Color(0xFF60A5FA),
    primaryDark: Color(0xFF1D4ED8),
    positive: Color(0xFF10B981),
    positiveLight: Color(0xFF064E3B),
    negative: Color(0xFFFB7185),
    negativeLight: Color(0xFF881337),
    warning: Color(0xFFFBBF24),
    warningLight: Color(0xFF78350F),
    border: Color(0xFF334155),
    divider: Color(0xFF1E293B),
    interactive: Color(0xFF3B82F6),
    interactiveHover: Color(0xFF60A5FA),
    interactivePressed: Color(0xFF2563EB),
  );
}

/// Resolves the correct palette for the *current* theme brightness.
///
/// Any widget that needs a semantic color not already covered by
/// `Theme.of(context).textTheme` (see AppTheme, which now colors the text
/// theme per-brightness) should read it through `context.appColors`, never
/// through `AppColors.light`/`AppColors.dark` directly.
extension AppColorsContext on BuildContext {
  AppColorPalette get appColors =>
      Theme.of(this).brightness == Brightness.dark ? AppColors.dark : AppColors.light;
}
