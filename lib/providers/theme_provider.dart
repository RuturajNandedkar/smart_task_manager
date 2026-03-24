import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider extends ChangeNotifier {
  /// Private constructor. Use [load()] in production or
  /// [ThemeProvider.withMode()] in tests.
  ThemeProvider._(this._themeMode);

  /// For testing — bypasses SharedPreferences.
  @visibleForTesting
  ThemeProvider.withMode(ThemeMode mode) : _themeMode = mode;

  /// Loads persisted theme preference from SharedPreferences.
  static Future<ThemeProvider> load() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString('themeMode');
    final mode = saved == 'dark'
        ? ThemeMode.dark
        : saved == 'light'
            ? ThemeMode.light
            : ThemeMode.system;
    return ThemeProvider._(mode);
  }

  ThemeMode _themeMode;

  ThemeMode get themeMode => _themeMode;

  bool get isDarkMode => _themeMode == ThemeMode.dark;

  Future<void> toggleTheme() async {
    _themeMode = isDarkMode ? ThemeMode.light : ThemeMode.dark;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('themeMode', isDarkMode ? 'dark' : 'light');
  }
}
