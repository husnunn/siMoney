import 'package:flutter/material.dart';

abstract final class AppColors {
  // Surfaces (darkest -> lightest)
  static const Color surfaceContainerLowest = Color(0xFF0A0E16);
  static const Color surface = Color(0xFF0F131B);
  static const Color surfaceContainerLow = Color(0xFF181C24);
  static const Color surfaceContainer = Color(0xFF1C2028);
  static const Color surfaceContainerHigh = Color(0xFF262A33);
  static const Color surfaceContainerHighest = Color(0xFF31353E);

  // Content on surfaces
  static const Color onSurface = Color(0xFFDFE2EE);
  static const Color onSurfaceVariant = Color(0xFFD4C4B0);
  static const Color outline = Color(0xFF9D8F7C);
  static const Color outlineVariant = Color(0xFF504535);

  // Primary (gold) - the one accent
  static const Color primary = Color(0xFFFFC665);
  static const Color onPrimary = Color(0xFF432C00);
  static const Color primaryContainer = Color(0xFFE5A93C);

  // Secondary (mint) - income/success
  static const Color secondary = Color(0xFF4EDEA3);
  static const Color onSecondary = Color(0xFF003824);
  static const Color secondaryContainer = Color(0xFF00A572);

  // Tertiary (coral) - category tag variety only, never expense amounts
  static const Color tertiary = Color(0xFFFFBFC2);
  static const Color onTertiary = Color(0xFF67001B);
  static const Color tertiaryContainer = Color(0xFFFF959D);

  // Error (salmon) - the one expense/destructive color
  static const Color error = Color(0xFFFFB4AB);
  static const Color onError = Color(0xFF690005);
  static const Color errorContainer = Color(0xFF93000A);

  // Domain aliases - keep call sites readable in finance context
  static const Color income = secondary;
  static const Color expense = error;
}
