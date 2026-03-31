import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocaleController with ChangeNotifier {
  bool _ar = false;
  bool _initialized = false;

  bool get isArabic => _ar;
  Locale get locale => _ar ? const Locale('ar') : const Locale('en');

  Future<void> initialize() async {
    if (_initialized) return;

    final prefs = await SharedPreferences.getInstance();
    _ar = prefs.getBool('isArabic') ?? false;
    _initialized = true;
    notifyListeners();
  }

  Future<void> toggle() async {
    _ar = !_ar;
    await _savePreference();
    notifyListeners();
  }

  Future<void> setArabic(bool v) async {
    if (_ar != v) {
      _ar = v;
      await _savePreference();
      notifyListeners();
    }
  }

  Future<void> _savePreference() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isArabic', _ar);
  }

  static void of(BuildContext context) {}
}
