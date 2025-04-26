import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsController with ChangeNotifier {
  static const String _themeKey = 'theme';
  static const String _fontSizeKey = 'fontSize';

  ThemeMode _themeMode = ThemeMode.system;
  double _fontSize = 14.0;

  ThemeMode get themeMode => _themeMode;
  double get fontSize => _fontSize;

  Future<void> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final themeIndex = prefs.getInt(_themeKey) ?? ThemeMode.system.index;
    _themeMode = ThemeMode.values[themeIndex];
    _fontSize = prefs.getDouble(_fontSizeKey) ?? 14.0;
    notifyListeners();
  }

  Future<void> updateThemeMode(ThemeMode newThemeMode) async {
    _themeMode = newThemeMode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_themeKey, newThemeMode.index);
    notifyListeners();
  }

  Future<void> updateFontSize(double newSize) async {
    _fontSize = newSize;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_fontSizeKey, newSize);
    notifyListeners();
  }
}