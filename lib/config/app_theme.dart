import 'package:flutter/material.dart';

/// Centralized theme configuration for the entire application
/// Provides Material 3 light and dark themes
class AppTheme {
  AppTheme._(); // Private constructor

  /// Spacing constants
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 16.0;
  static const double lg = 24.0;
  static const double xl = 32.0;
  static const double xxl = 48.0;

  /// Border radius constants
  static const double radiusSm = 8.0;
  static const double radiusMd = 12.0;
  static const double radiusLg = 16.0;
  static const double radiusXl = 24.0;

  /// Light theme
  static ThemeData lightTheme() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.fromSeed(
        seedColor: Colors.blue,
        brightness: Brightness.light,
      ).copyWith(
        primary: Colors.blue.shade600,
        onPrimary: Colors.white,
        primaryContainer: Colors.blue.shade50,
        onPrimaryContainer: Colors.blue.shade900,
        secondary: Colors.teal.shade400,
        onSecondary: Colors.white,
        secondaryContainer: Colors.teal.shade50,
        onSecondaryContainer: Colors.teal.shade900,
        tertiary: Colors.purple.shade400,
        onTertiary: Colors.white,
        tertiaryContainer: Colors.purple.shade50,
        onTertiaryContainer: Colors.purple.shade900,
        error: Colors.red.shade600,
        onError: Colors.white,
        errorContainer: Colors.red.shade50,
        onErrorContainer: Colors.red.shade900,
        surface: const Color(0xFFF6F7FB),
        onSurface: const Color(0xFF1B1E24),
        surfaceContainerHighest: Colors.white,
        surfaceContainer: Colors.white,
        surfaceContainerLow: const Color(0xFFFAFAFA),
        onSurfaceVariant: Colors.grey.shade700,
        outline: Colors.grey.shade300,
        outlineVariant: Colors.grey.shade200,
        shadow: Colors.black.withValues(alpha: 0.1),
        inverseSurface: const Color(0xFF1B1E24),
        onInverseSurface: Colors.white,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusLg),
          side: BorderSide(
            color: Colors.grey.shade300,
            width: 1,
          ),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: lg, vertical: md),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusMd),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: lg, vertical: md),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusMd),
          ),
          side: const BorderSide(width: 2),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: BorderSide(color: Colors.blue.shade600, width: 2),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: md, vertical: md),
      ),
      appBarTheme: AppBarTheme(
        elevation: 0,
        centerTitle: true,
        backgroundColor: Colors.blue.shade600,
        foregroundColor: Colors.white,
      ),
    );
  }

  /// Dark theme (Enhanced)
  static ThemeData darkTheme() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.fromSeed(
        seedColor: Colors.blue,
        brightness: Brightness.dark,
        dynamicSchemeVariant: DynamicSchemeVariant.fidelity,
      ).copyWith(
        primary: Colors.blue.shade300,
        onPrimary: Colors.black,
        primaryContainer: Colors.blue.shade900,
        onPrimaryContainer: Colors.blue.shade100,
        secondary: Colors.teal.shade300,
        onSecondary: Colors.black,
        secondaryContainer: Colors.teal.shade900,
        onSecondaryContainer: Colors.teal.shade100,
        tertiary: Colors.purple.shade300,
        onTertiary: Colors.black,
        tertiaryContainer: Colors.purple.shade900,
        onTertiaryContainer: Colors.purple.shade100,
        error: Colors.red.shade300,
        onError: Colors.black,
        errorContainer: Colors.red.shade900,
        onErrorContainer: Colors.red.shade100,
        surface: const Color(0xFF0F1419), // Very dark surface
        onSurface: Colors.white,
        surfaceContainerHighest: const Color(0xFF1C1B1F),
        surfaceContainer: const Color(0xFF1C1B1F),
        surfaceContainerLow: const Color(0xFF16171B),
        onSurfaceVariant: Colors.white.withValues(alpha: 0.8),
        outline: Colors.white.withValues(alpha: 0.2),
        outlineVariant: Colors.white.withValues(alpha: 0.1),
        shadow: Colors.black,
        scrim: Colors.black,
        inverseSurface: Colors.white,
        onInverseSurface: Colors.black,
        inversePrimary: Colors.blue.shade600,
        surfaceTint: Colors.blue.shade300,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: const Color(0xFF1C1B1F),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusLg),
          side: BorderSide(
            color: Colors.white.withValues(alpha: 0.1),
            width: 1,
          ),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: lg, vertical: md),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusMd),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: lg, vertical: md),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusMd),
          ),
          side: const BorderSide(width: 2),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF1C1B1F),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.2)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.2)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: BorderSide(color: Colors.blue.shade300, width: 2),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: md, vertical: md),
      ),
      appBarTheme: AppBarTheme(
        elevation: 0,
        centerTitle: true,
        backgroundColor: const Color(0xFF1C1B1F),
        foregroundColor: Colors.white,
      ),
    );
  }
}
