import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.system;
  bool _isVisibilityMode = true; // Default to true (Visibility Mode)

  ThemeMode get themeMode => _themeMode;
  bool get isVisibilityMode => _isVisibilityMode;

  ThemeProvider() {
    _loadTheme();
  }

  void _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final themeIndex = prefs.getInt('theme_mode');
    if (themeIndex != null) {
      _themeMode = ThemeMode.values[themeIndex];
    }

    // Load Visibility Mode
    final visibility = prefs.getBool('is_visibility_mode');
    if (visibility != null) {
      _isVisibilityMode = visibility;
    }

    notifyListeners();
  }

  void setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('theme_mode', mode.index);
  }

  void toggleVisibilityMode(bool isEnabled) async {
    _isVisibilityMode = isEnabled;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_visibility_mode', isEnabled);
  }
}
