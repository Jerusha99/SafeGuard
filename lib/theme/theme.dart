import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Red dark theme (primary red on black)
  static final ThemeData redDark = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: const ColorScheme(
      brightness: Brightness.dark,
      primary: Color(0xFFFF1744),
      onPrimary: Colors.white,
      secondary: Colors.white,
      onSecondary: Colors.black,
      error: Colors.red,
      onError: Colors.white,
      surface: Color(0xFF111111),
      onSurface: Colors.white,
    ),
    scaffoldBackgroundColor: const Color(0xFF0B0B0B),
    textTheme: GoogleFonts.interTextTheme(
      ThemeData.dark().textTheme,
    ).apply(bodyColor: Colors.white, displayColor: Colors.white),
    appBarTheme: AppBarTheme(
      backgroundColor: const Color(0xFF111111),
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      systemOverlayStyle: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
      titleTextStyle: GoogleFonts.inter(
        color: Colors.white,
        fontSize: 20,
        fontWeight: FontWeight.w800,
        letterSpacing: 0.3,
      ),
      iconTheme: const IconThemeData(color: Colors.white),
      foregroundColor: Colors.white,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFFFF1744),
        foregroundColor: Colors.white,
        shape: const StadiumBorder(),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        textStyle: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 16),
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: const Color(0xFF1C1C1C),
      contentTextStyle: GoogleFonts.inter(color: Colors.white),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFF151515),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
      labelStyle: const TextStyle(color: Colors.white70),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: Color(0xFFFF1744),
      foregroundColor: Colors.white,
      elevation: 8,
    ),
    cardColor: const Color(0xFF151515),
  );

  // White light theme (white surfaces with red accents)
  static final ThemeData whiteLight = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: const ColorScheme(
      brightness: Brightness.light,
      primary: Color(0xFFD50000),
      onPrimary: Colors.white,
      secondary: Color(0xFF0066CC),
      onSecondary: Colors.white,
      error: Colors.red,
      onError: Colors.white,
      surface: Colors.white,
      onSurface: Colors.black,
    ),
    scaffoldBackgroundColor: Colors.white,
    textTheme: GoogleFonts.interTextTheme().apply(
      bodyColor: Colors.black,
      displayColor: Colors.black,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      systemOverlayStyle: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
      ),
      titleTextStyle: GoogleFonts.inter(
        color: Colors.black,
        fontSize: 20,
        fontWeight: FontWeight.w800,
        letterSpacing: 0.3,
      ),
      iconTheme: const IconThemeData(color: Colors.black),
      foregroundColor: Colors.black,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFFD50000),
        foregroundColor: Colors.white,
        shape: const StadiumBorder(),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        textStyle: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 16),
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: Colors.black,
      contentTextStyle: GoogleFonts.inter(color: Colors.white),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFFF5F5F5),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
      labelStyle: const TextStyle(color: Colors.black54),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: Color(0xFFD50000),
      foregroundColor: Colors.white,
      elevation: 8,
    ),
    cardColor: const Color(0xFFF9F9F9),
  );

  // Black dark theme (pure black with white text, minimal red)
  static final ThemeData blackDark = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: const ColorScheme(
      brightness: Brightness.dark,
      primary: Color(0xFFEEEEEE),
      onPrimary: Colors.black,
      secondary: Colors.white,
      onSecondary: Colors.black,
      error: Colors.red,
      onError: Colors.white,
      surface: Color(0xFF0A0A0A),
      onSurface: Colors.white,
    ),
    scaffoldBackgroundColor: Colors.black,
    textTheme: GoogleFonts.interTextTheme(
      ThemeData.dark().textTheme,
    ).apply(bodyColor: Colors.white, displayColor: Colors.white),
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.black,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      systemOverlayStyle: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
      titleTextStyle: GoogleFonts.inter(
        color: Colors.white,
        fontSize: 20,
        fontWeight: FontWeight.w800,
        letterSpacing: 0.3,
      ),
      iconTheme: const IconThemeData(color: Colors.white),
      foregroundColor: Colors.white,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        shape: const StadiumBorder(),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        textStyle: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 16),
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: const Color(0xFF1C1C1C),
      contentTextStyle: GoogleFonts.inter(color: Colors.white),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFF151515),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
      labelStyle: const TextStyle(color: Colors.white70),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: Colors.white,
      foregroundColor: Colors.black,
      elevation: 8,
    ),
    cardColor: const Color(0xFF151515),
  );
}

class ThemeController {
  ThemeController._();
  static final ThemeController instance = ThemeController._();

  final ValueNotifier<ThemeData> theme = ValueNotifier<ThemeData>(
    AppTheme.redDark,
  );

  void setSeedColor(Color seedColor) {
    // Deprecated in favor of setVariant, kept for compatibility
    theme.value = AppTheme.redDark;
  }

  void setVariant(ThemeVariant variant) {
    switch (variant) {
      case ThemeVariant.redDark:
        theme.value = AppTheme.redDark;
        break;
      case ThemeVariant.whiteLight:
        theme.value = AppTheme.whiteLight;
        break;
      case ThemeVariant.blackDark:
        theme.value = AppTheme.blackDark;
        break;
    }
  }
}

enum ThemeVariant { redDark, whiteLight, blackDark }
