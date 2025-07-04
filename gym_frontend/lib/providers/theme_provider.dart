import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider with ChangeNotifier {
  static const String _themeKey = 'theme_mode';
  
  ThemeMode _themeMode = ThemeMode.system;
  bool _isLoading = true;

  ThemeMode get themeMode => _themeMode;
  bool get isLoading => _isLoading;
  
  bool get isDarkMode {
    switch (_themeMode) {
      case ThemeMode.dark:
        return true;
      case ThemeMode.light:
        return false;
      case ThemeMode.system:
        return WidgetsBinding.instance.platformDispatcher.platformBrightness == Brightness.dark;
    }
  }

  ThemeProvider() {
    _loadThemePreference();
  }

  /// Load saved theme preference from SharedPreferences
  Future<void> _loadThemePreference() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedThemeIndex = prefs.getInt(_themeKey) ?? 0;
      
      _themeMode = ThemeMode.values[savedThemeIndex];
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      // If loading fails, default to system theme
      _themeMode = ThemeMode.system;
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Save theme preference to SharedPreferences
  Future<void> _saveThemePreference() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_themeKey, _themeMode.index);
    } catch (e) {
      // Handle save error silently
      debugPrint('Failed to save theme preference: $e');
    }
  }

  /// Set theme mode and save preference
  Future<void> setThemeMode(ThemeMode themeMode) async {
    if (_themeMode != themeMode) {
      _themeMode = themeMode;
      notifyListeners();
      await _saveThemePreference();
    }
  }

  /// Toggle between light and dark mode
  Future<void> toggleTheme() async {
    final newThemeMode = _themeMode == ThemeMode.dark 
        ? ThemeMode.light 
        : ThemeMode.dark;
    await setThemeMode(newThemeMode);
  }

  /// Set dark mode enabled/disabled
  Future<void> setDarkMode(bool enabled) async {
    final newThemeMode = enabled ? ThemeMode.dark : ThemeMode.light;
    await setThemeMode(newThemeMode);
  }

  /// Reset to system theme
  Future<void> useSystemTheme() async {
    await setThemeMode(ThemeMode.system);
  }

  /// Get theme mode display name
  String get themeModeDisplayName {
    switch (_themeMode) {
      case ThemeMode.light:
        return 'Light';
      case ThemeMode.dark:
        return 'Dark';
      case ThemeMode.system:
        return 'System';
    }
  }
}