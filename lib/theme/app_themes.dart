import 'package:flutter/material.dart';

class AppThemes {
  static final ThemeData redTheme = ThemeData(
    brightness: Brightness.light,
    primaryColor: Colors.red,
    colorScheme: ColorScheme.light(
      primary: Colors.red,
      onPrimary: Colors.white,
      secondary: Colors.redAccent,
      onSecondary: Colors.white,
      surface: Colors.white,
      onSurface: Colors.black,
      error: Colors.red.shade700,
      onError: Colors.white,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.red,
      foregroundColor: Colors.white,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
      ),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      selectedItemColor: Colors.red,
      unselectedItemColor: Colors.grey,
      backgroundColor: Colors.white,
    ),
  );

  static final ThemeData blackTheme = ThemeData(
    brightness: Brightness.dark,
    primaryColor: Colors.black,
    colorScheme: ColorScheme.dark(
      primary: Colors.black,
      onPrimary: Colors.white,
      secondary: Colors.grey.shade900,
      onSecondary: Colors.white,
      surface: Colors.grey.shade800,
      onSurface: Colors.white,
      error: Colors.red.shade700,
      onError: Colors.white,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.black,
      foregroundColor: Colors.white,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      selectedItemColor: Colors.white,
      unselectedItemColor: Colors.grey,
      backgroundColor: Colors.black,
    ),
  );

  static final ThemeData whiteTheme = ThemeData(
    brightness: Brightness.light,
    primaryColor: Colors.white,
    colorScheme: ColorScheme.light(
      primary: Colors.white,
      onPrimary: Colors.black,
      secondary: Colors.grey.shade200,
      onSecondary: Colors.black,
      surface: Colors.white,
      onSurface: Colors.black,
      error: Colors.red.shade700,
      onError: Colors.white,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.white,
      foregroundColor: Colors.black,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      selectedItemColor: Colors.black,
      unselectedItemColor: Colors.grey,
      backgroundColor: Colors.white,
    ),
  );
}
