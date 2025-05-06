// lib/components/theme.dart
import 'package:flutter/material.dart';

const kPrimaryAccent = Color(0xFF8A56AC);
const kGradientStart = Color(0xFF6A1B9A); // Darker purple for gradient
const kGradientEnd = kPrimaryAccent;

class AppTheme {
  static final lightTheme = ThemeData(
    useMaterial3: false,
    scaffoldBackgroundColor: Colors.white,
    primaryColor: kPrimaryAccent,
    colorScheme: ColorScheme.fromSeed(
      seedColor: kPrimaryAccent,
      brightness: Brightness.light,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.white,
      foregroundColor: Colors.black,
      elevation: 0,
      shadowColor: Colors.transparent,
      centerTitle: true,
      titleTextStyle: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Colors.black,
      ),
      toolbarHeight: 48,
    ),
    cardTheme: const CardTheme(
      elevation: 2,
      color: Colors.white,
      margin: EdgeInsets.only(bottom: 16.0),
    ),
    textTheme: TextTheme(
      headlineSmall: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: kPrimaryAccent,
      ),
      titleLarge: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: Colors.black,
      ),
      bodyMedium: TextStyle(
        fontSize: 14,
        color: Colors.grey[900],
      ),
      labelMedium: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: Colors.black,
      ),
      labelSmall: const TextStyle(
        fontSize: 12,
        color: Colors.grey,
      ),
    ),
    iconTheme: const IconThemeData(color: Colors.black),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      selectedItemColor: kPrimaryAccent,
      unselectedItemColor: Colors.grey,
      backgroundColor: Colors.white,
      elevation: 10,
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: kPrimaryAccent,
      foregroundColor: Colors.white,
    ),
  );

  static final darkTheme = ThemeData(
    useMaterial3: false,
    scaffoldBackgroundColor: const Color(0xFF121212),
    primaryColor: kPrimaryAccent,
    colorScheme: ColorScheme.fromSeed(
      seedColor: kPrimaryAccent,
      brightness: Brightness.dark,
      background: const Color(0xFF121212),
      surface: const Color(0xFF1E1E1E),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: kPrimaryAccent,
      foregroundColor: Colors.white,
      elevation: 0,
      shadowColor: Colors.transparent,
      centerTitle: true,
      titleTextStyle: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: Colors.white,
      ),
      toolbarHeight: 48,
    ),
    cardTheme: const CardTheme(
      elevation: 2,
      color: Color(0xFF1E1E1E),
      margin: EdgeInsets.only(bottom: 16.0),
    ),
    textTheme: const TextTheme(
      headlineSmall: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: kPrimaryAccent,
      ),
      titleLarge: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: Colors.white,
      ),
      bodyMedium: TextStyle(
        fontSize: 14,
        color: Colors.grey,
      ),
      labelMedium: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: Colors.white,
      ),
      labelSmall: TextStyle(
        fontSize: 12,
        color: Colors.grey,
      ),
    ),
    iconTheme: const IconThemeData(color: Colors.white),
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      selectedItemColor: kPrimaryAccent,
      unselectedItemColor: Colors.grey[400],
      backgroundColor: const Color(0xFF1E1E1E),
      elevation: 10,
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: kPrimaryAccent,
      foregroundColor: Colors.white,
    ),
  );
}
