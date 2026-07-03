import 'package:flutter/material.dart';

class AppTheme {
  // Brand color scheme: Deep purple/Indigo accents with soft surfaces
  static const Color primaryLight = Color(0xFF6750A4);
  static const Color primaryContainerLight = Color(0xFFEADDFF);
  static const Color secondaryLight = Color(0xFF625B71);
  static const Color backgroundLight = Color(0xFFFEF7FF);
  static const Color surfaceLight = Color(0xFFFFF7FF);
  static const Color errorLight = Color(0xFFB3261E);

  static const Color primaryDark = Color(0xFFD0BCFF);
  static const Color primaryContainerDark = Color(0xFF4F378B);
  static const Color secondaryDark = Color(0xFFCCC2DC);
  static const Color backgroundDark = Color(0xFF141218);
  static const Color surfaceDark = Color(0xFF1D1B20);
  static const Color errorDark = Color(0xFFF2B8B5);

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: const ColorScheme.light(
        primary: primaryLight,
        primaryContainer: primaryContainerLight,
        secondary: secondaryLight,
        surface: surfaceLight,
        error: errorLight,
      ),
      scaffoldBackgroundColor: backgroundLight,
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0xFFCAC4D0), width: 0.5),
        ),
        color: surfaceLight,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: backgroundLight,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: primaryLight),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        backgroundColor: backgroundLight,
      ),
      dialogTheme: DialogThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        backgroundColor: backgroundLight,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFFECE6F0),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primaryLight, width: 2),
        ),
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: const ColorScheme.dark(
        primary: primaryDark,
        primaryContainer: primaryContainerDark,
        secondary: secondaryDark,
        surface: surfaceDark,
        error: errorDark,
      ),
      scaffoldBackgroundColor: backgroundDark,
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0xFF49454F), width: 0.5),
        ),
        color: surfaceDark,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: backgroundDark,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: primaryDark),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        backgroundColor: backgroundDark,
      ),
      dialogTheme: DialogThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        backgroundColor: backgroundDark,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF2B2930),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primaryDark, width: 2),
        ),
      ),
    );
  }
}
