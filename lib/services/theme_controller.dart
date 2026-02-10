import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeController with ChangeNotifier {
  bool _isDark = true; // Default to dark mode
  bool _initialized = false;

  bool get isDark => _isDark;
  ThemeMode get themeMode => _isDark ? ThemeMode.dark : ThemeMode.light;

  Future<void> initialize() async {
    if (_initialized) return;

    final prefs = await SharedPreferences.getInstance();
    _isDark = prefs.getBool('isDarkMode') ?? true; // Default to true
    _initialized = true;
    notifyListeners();
  }

  Future<void> toggle() async {
    _isDark = !_isDark;
    await _savePreference();
    notifyListeners();
  }

  Future<void> setDark(bool v) async {
    if (_isDark != v) {
      _isDark = v;
      await _savePreference();
      notifyListeners();
    }
  }

  Future<void> _savePreference() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDarkMode', _isDark);
  }
}
