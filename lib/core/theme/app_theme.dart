import 'package:flutter/material.dart';

class Palette {
  static const purple = Color(0xFF8B3DDB);
  static const orchid = Color(0xFFB44BEA);
  static const lavender = Color(0xFFF0E5FF);
  static const ink = Color(0xFF241332);
  static const gold = Color(0xFFF5BD4F);
  static const canvas = Color(0xFFF7F5FA);
  static const muted = Color(0xFF9595A2);
  static const pink = Color(0xFFFF8EA9);
  static const green = Color(0xFF48BC76);
}

ThemeData buildTheme() => ThemeData(
  useMaterial3: true,
  fontFamily: 'KapperSans',
  scaffoldBackgroundColor: Palette.canvas,
  colorScheme: ColorScheme.fromSeed(
    seedColor: Palette.purple,
    brightness: Brightness.light,
    primary: Palette.purple,
    secondary: Palette.gold,
    surface: Colors.white,
  ),
  textTheme: const TextTheme(
    headlineMedium: TextStyle(
      fontSize: 28,
      fontWeight: FontWeight.w500,
      color: Palette.ink,
    ),
    titleLarge: TextStyle(
      fontSize: 22,
      fontWeight: FontWeight.w500,
      color: Palette.ink,
    ),
    titleMedium: TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w600,
      color: Palette.ink,
    ),
    bodyMedium: TextStyle(fontSize: 13, color: Palette.ink),
    bodySmall: TextStyle(fontSize: 11, color: Palette.muted),
  ),
  appBarTheme: const AppBarTheme(
    backgroundColor: Colors.white,
    surfaceTintColor: Colors.transparent,
    foregroundColor: Palette.ink,
    centerTitle: true,
    elevation: 0,
  ),
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: Colors.white,
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 15),
    hintStyle: const TextStyle(fontSize: 12, color: Palette.muted),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(7),
      borderSide: const BorderSide(color: Color(0xFFDFDFE8)),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(7),
      borderSide: const BorderSide(color: Color(0xFFDFDFE8)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(7),
      borderSide: const BorderSide(color: Palette.purple),
    ),
  ),
  cardTheme: CardThemeData(
    color: Colors.white,
    surfaceTintColor: Colors.transparent,
    elevation: 1,
    shadowColor: Palette.ink.withValues(alpha: .08),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
  ),
  dialogTheme: DialogThemeData(
    backgroundColor: Colors.white,
    surfaceTintColor: Colors.transparent,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
  ),
  bottomSheetTheme: const BottomSheetThemeData(
    backgroundColor: Colors.white,
    surfaceTintColor: Colors.transparent,
  ),
  dividerTheme: const DividerThemeData(color: Color(0xFFE5DFEA)),
);

ThemeData buildDarkTheme() => ThemeData(
  useMaterial3: true,
  fontFamily: 'KapperSans',
  brightness: Brightness.dark,
  scaffoldBackgroundColor: const Color(0xFF0A0612),
  colorScheme: ColorScheme.fromSeed(
    seedColor: Palette.purple,
    brightness: Brightness.dark,
    primary: Palette.purple,
    secondary: Palette.gold,
    surface: const Color(0xFF130924),
  ),
  textTheme: const TextTheme(
    headlineMedium: TextStyle(
      fontSize: 28,
      fontWeight: FontWeight.w500,
      color: Colors.white,
    ),
    titleLarge: TextStyle(
      fontSize: 22,
      fontWeight: FontWeight.w500,
      color: Colors.white,
    ),
    titleMedium: TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w600,
      color: Colors.white,
    ),
    bodyMedium: TextStyle(fontSize: 13, color: Colors.white),
    bodySmall: TextStyle(fontSize: 11, color: Colors.white60),
  ),
  appBarTheme: const AppBarTheme(
    backgroundColor: Color(0xFF0A0612),
    surfaceTintColor: Colors.transparent,
    foregroundColor: Colors.white,
    centerTitle: true,
    elevation: 0,
  ),
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: const Color(0xFF1B112E),
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 15),
    hintStyle: const TextStyle(fontSize: 12, color: Colors.white38),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(7),
      borderSide: const BorderSide(color: Color(0xFF381B61)),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(7),
      borderSide: const BorderSide(color: Color(0xFF381B61)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(7),
      borderSide: const BorderSide(color: Palette.purple),
    ),
  ),
  cardTheme: CardThemeData(
    color: const Color(0xFF130924),
    surfaceTintColor: Colors.transparent,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
  ),
  dialogTheme: DialogThemeData(
    backgroundColor: const Color(0xFF130924),
    surfaceTintColor: Colors.transparent,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
  ),
  bottomSheetTheme: const BottomSheetThemeData(
    backgroundColor: Color(0xFF130924),
    surfaceTintColor: Colors.transparent,
  ),
  chipTheme: const ChipThemeData(
    backgroundColor: Color(0xFF251A35),
    selectedColor: Palette.purple,
    labelStyle: TextStyle(color: Colors.white),
    secondaryLabelStyle: TextStyle(color: Colors.white),
  ),
  dividerTheme: const DividerThemeData(color: Color(0xFF261545)),
);
