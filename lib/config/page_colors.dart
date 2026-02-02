import 'package:flutter/material.dart';

/// Color constants for each page in the application
/// Provides consistent color identity across light and dark themes
class PageColors {
  PageColors._(); // Private constructor to prevent instantiation

  // Home/Dashboard - Blue
  static const Color home = Color(0xFF2196F3);
  static const Color homeLight = Color(0xFF64B5F6);
  static const Color homeDark = Color(0xFF1976D2);

  // Cuti - Green
  static const Color cuti = Color(0xFF4CAF50);
  static const Color cutiLight = Color(0xFF81C784);
  static const Color cutiDark = Color(0xFF388E3C);

  // Eksepsi - Orange
  static const Color eksepsi = Color(0xFFFF9800);
  static const Color eksepsiLight = Color(0xFFFFB74D);
  static const Color eksepsiDark = Color(0xFFF57C00);

  // Insentif - Purple
  static const Color insentif = Color(0xFF9C27B0);
  static const Color insentifLight = Color(0xFFBA68C8);
  static const Color insentifDark = Color(0xFF7B1FA2);

  // Surat Keluar - Teal
  static const Color suratKeluar = Color(0xFF009688);
  static const Color suratKeluarLight = Color(0xFF4DB6AC);
  static const Color suratKeluarDark = Color(0xFF00796B);

  // Data Management - Indigo
  static const Color dataManagement = Color(0xFF3F51B5);
  static const Color dataManagementLight = Color(0xFF7986CB);
  static const Color dataManagementDark = Color(0xFF303F9F);

  // Data Pribadi - Pink
  static const Color dataPribadi = Color(0xFFE91E63);
  static const Color dataPribadiLight = Color(0xFFF06292);
  static const Color dataPribadiDark = Color(0xFFC2185B);

  // Settings - Grey
  static const Color settings = Color(0xFF607D8B);
  static const Color settingsLight = Color(0xFF90A4AE);
  static const Color settingsDark = Color(0xFF455A64);

  /// Get the appropriate page color based on theme brightness
  static Color getPageColor(Color lightColor, Color darkColor, bool isDark) {
    return isDark ? darkColor : lightColor;
  }
}
