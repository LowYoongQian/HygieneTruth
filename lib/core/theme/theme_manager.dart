import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeManager extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.system;

  ThemeMode get themeMode => _themeMode;

  bool get isDarkMode => _themeMode == ThemeMode.dark;

  ThemeManager() {
    _loadThemeFromPrefs();
  }

  Future<void> _loadThemeFromPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final themeIndex = prefs.getInt('theme_mode') ?? 0; // 0: light, 1: system, 2: dark
      if (themeIndex == 0) {
        _themeMode = ThemeMode.light;
      } else if (themeIndex == 1) {
        _themeMode = ThemeMode.system;
      } else if (themeIndex == 2) {
        _themeMode = ThemeMode.dark;
      }
      notifyListeners();
    } catch (_) {}
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    if (_themeMode == mode) return;
    _themeMode = mode;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      int index = 0;
      if (mode == ThemeMode.light) index = 0;
      if (mode == ThemeMode.system) index = 1;
      if (mode == ThemeMode.dark) index = 2;
      await prefs.setInt('theme_mode', index);
    } catch (_) {}
  }
}

// Global instance
final themeManager = ThemeManager();
