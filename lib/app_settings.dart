import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppSettings with ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.system;
  double _baseFontSize = 14.0;
  final Map<TextType, double> _fontSizeMultipliers = {
    TextType.display: 2.0,
    TextType.headline: 1.8,
    TextType.title: 1.5,
    TextType.body: 1.0,
    TextType.label: 0.9,
  };

  ThemeMode get themeMode => _themeMode;
  double get baseFontSize => _baseFontSize;

  Future<void> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _themeMode = ThemeMode.values[prefs.getInt('themeMode') ?? ThemeMode.system.index];
    _baseFontSize = prefs.getDouble('baseFontSize') ?? 14.0;
    notifyListeners();
  }

  Future<void> updateThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('themeMode', mode.index);
    notifyListeners();
  }

  Future<void> updateBaseFontSize(double size) async {
    _baseFontSize = size;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('baseFontSize', size);
    notifyListeners();
  }

  TextStyle createTextStyle(TextType type, {Color? color}) {
    final baseColor = _themeMode == ThemeMode.dark ? Colors.white : Colors.black;
    return TextStyle(
      fontSize: _baseFontSize * _fontSizeMultipliers[type]!,
      color: color ?? baseColor,
    );
  }

  ThemeData get lightTheme => ThemeData(
    brightness: Brightness.light,
    primarySwatch: Colors.orange,
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.orange,
      titleTextStyle: createTextStyle(TextType.title, color: Colors.white),
      iconTheme: IconThemeData(color: Colors.white),
    ),
    textTheme: TextTheme(
      displayLarge: createTextStyle(TextType.display),
      headlineMedium: createTextStyle(TextType.headline),
      titleLarge: createTextStyle(TextType.title),
      bodyMedium: createTextStyle(TextType.body),
      labelSmall: createTextStyle(TextType.label),
    ),
  );

  ThemeData get darkTheme => ThemeData(
    brightness: Brightness.dark,
    primarySwatch: Colors.orange,
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.grey[900],
      titleTextStyle: createTextStyle(TextType.title, color: Colors.white),
      iconTheme: IconThemeData(color: Colors.white),
    ),
    textTheme: TextTheme(
      displayLarge: createTextStyle(TextType.display, color: Colors.white),
      headlineMedium: createTextStyle(TextType.headline, color: Colors.white),
      titleLarge: createTextStyle(TextType.title, color: Colors.white),
      bodyMedium: createTextStyle(TextType.body, color: Colors.white),
      labelSmall: createTextStyle(TextType.label, color: Colors.white70),
    ),
  );
}

enum TextType { display, headline, title, body, label }