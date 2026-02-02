import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Controller for managing theme (light/dark mode) across the entire app
class ThemeController extends GetxController {
  static const String _themeKey = 'isDarkMode';

  // Observable for dark mode state
  final RxBool isDarkMode = true.obs; // Default to dark mode

  @override
  void onInit() {
    super.onInit();
    _loadThemePreference();
  }

  /// Load theme preference from SharedPreferences
  Future<void> _loadThemePreference() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedDarkMode = prefs.getBool(_themeKey);

      if (savedDarkMode != null) {
        isDarkMode.value = savedDarkMode;
      } else {
        // First time: default to dark mode
        isDarkMode.value = true;
        await prefs.setBool(_themeKey, true);
      }
    } catch (e) {
      // If error, default to dark mode
      isDarkMode.value = true;
    }
  }

  /// Toggle between light and dark mode
  Future<void> toggleTheme() async {
    isDarkMode.value = !isDarkMode.value;
    await _saveThemePreference();

    // Update GetX theme mode
    Get.changeThemeMode(isDarkMode.value ? ThemeMode.dark : ThemeMode.light);
  }

  /// Save theme preference to SharedPreferences
  Future<void> _saveThemePreference() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_themeKey, isDarkMode.value);
    } catch (e) {
      // Silent failure - theme will still work for current session
      debugPrint('Failed to save theme preference: $e');
    }
  }

  /// Get current theme mode
  ThemeMode get themeMode =>
      isDarkMode.value ? ThemeMode.dark : ThemeMode.light;

  /// Check if current theme is dark
  bool get isCurrentlyDark => isDarkMode.value;
}
