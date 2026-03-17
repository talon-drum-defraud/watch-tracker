import 'package:flutter/material.dart';
import '../services/prefs_service.dart';

class ThemeProvider extends ChangeNotifier {
  ThemeMode _mode = ThemeMode.system;
  ThemeMode get mode => _mode;

  Future<void> load() async {
    final saved = await PrefsService.instance.getThemeMode();
    _mode = _fromString(saved);
    notifyListeners();
  }

  Future<void> setMode(ThemeMode mode) async {
    _mode = mode;
    await PrefsService.instance.setThemeMode(_toString(mode));
    notifyListeners();
  }

  String get label {
    switch (_mode) {
      case ThemeMode.light: return 'Light';
      case ThemeMode.dark:  return 'Dark';
      default:              return 'System';
    }
  }

  static ThemeMode _fromString(String s) {
    switch (s) {
      case 'light': return ThemeMode.light;
      case 'dark':  return ThemeMode.dark;
      default:      return ThemeMode.system;
    }
  }

  static String _toString(ThemeMode m) {
    switch (m) {
      case ThemeMode.light: return 'light';
      case ThemeMode.dark:  return 'dark';
      default:              return 'system';
    }
  }
}
