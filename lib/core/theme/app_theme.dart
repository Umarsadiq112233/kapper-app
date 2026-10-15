import 'package:flutter/material.dart';

class Palette {
  static const purple = Color(0xFF9B65CD);
  static const orchid = Color(0xFFBB58D1);
  static const lavender = Color(0xFFEBCBFF);
  static const ink = Color(0xFF200C30);
  static const gold = Color(0xFFF5BD4F);
  static const canvas = Color(0xFFF3F3F3);
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
    primary: Palette.purple,
    secondary: Palette.gold,
    surface: Palette.canvas,
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
    backgroundColor: Palette.canvas,
    surfaceTintColor: Colors.transparent,
    foregroundColor: Palette.ink,
    centerTitle: true,
    elevation: 0,
  ),
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: const Color(0xFFEEEEF0),
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
  dividerTheme: const DividerThemeData(color: Color(0xFFE5DFEA)),
);
