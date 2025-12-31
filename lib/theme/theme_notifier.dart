import 'package:flutter/material.dart';
import 'package:safeguard/theme/app_themes.dart';

class ThemeNotifier with ChangeNotifier {
  ThemeData _currentTheme = AppThemes.whiteTheme; // Default theme

  ThemeData get currentTheme => _currentTheme;

  void setTheme(ThemeData theme) {
    _currentTheme = theme;
    notifyListeners();
  }
}
