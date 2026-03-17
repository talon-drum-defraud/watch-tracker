import 'package:flutter/material.dart';

class AppTheme {
  static const _seed = Color(0xFFB8860B); // dark golden rod

  static ThemeData get dark => ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorSchemeSeed: _seed,
    scaffoldBackgroundColor: const Color(0xFF0F0F0F),
    cardTheme: CardThemeData(
      color: const Color(0xFF1C1C1E),
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF0F0F0F),
      elevation: 0,
      centerTitle: false,
    ),
    tabBarTheme: const TabBarThemeData(
      dividerColor: Color(0xFF2C2C2E),
    ),
    textTheme: const TextTheme(
      displaySmall: TextStyle(fontSize: 36, fontWeight: FontWeight.w200, letterSpacing: -1),
      titleLarge:   TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
      titleMedium:  TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
      bodyMedium:   TextStyle(fontSize: 14, color: Color(0xFFAAAAAA)),
      labelSmall:   TextStyle(fontSize: 11, letterSpacing: 0.8),
    ),
    dividerTheme: const DividerThemeData(color: Color(0xFF2C2C2E)),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFF2C2C2E),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: Color(0xFFB8860B),
      foregroundColor: Colors.black,
    ),
  );

  static ThemeData get light => ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorSchemeSeed: _seed,
    scaffoldBackgroundColor: const Color(0xFFF2F2F7),
    cardTheme: CardThemeData(
      color: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFFF2F2F7),
      elevation: 0,
      centerTitle: false,
      foregroundColor: Color(0xFF1C1C1E),
    ),
    tabBarTheme: const TabBarThemeData(
      dividerColor: Color(0xFFE5E5EA),
      labelColor: Color(0xFF1C1C1E),
      unselectedLabelColor: Color(0xFF8E8E93),
    ),
    textTheme: const TextTheme(
      displaySmall: TextStyle(fontSize: 36, fontWeight: FontWeight.w200,
          letterSpacing: -1, color: Color(0xFF1C1C1E)),
      titleLarge:   TextStyle(fontSize: 20, fontWeight: FontWeight.w600,
          color: Color(0xFF1C1C1E)),
      titleMedium:  TextStyle(fontSize: 16, fontWeight: FontWeight.w500,
          color: Color(0xFF1C1C1E)),
      bodyMedium:   TextStyle(fontSize: 14, color: Color(0xFF636366)),
      labelSmall:   TextStyle(fontSize: 11, letterSpacing: 0.8,
          color: Color(0xFF8E8E93)),
    ),
    dividerTheme: const DividerThemeData(color: Color(0xFFE5E5EA)),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFFE5E5EA),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: Color(0xFFB8860B),
      foregroundColor: Colors.white,
    ),
  );
}
