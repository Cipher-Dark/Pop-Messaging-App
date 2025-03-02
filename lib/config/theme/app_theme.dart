import 'dart:ui';

import 'package:flutter/material.dart';

class AppTheme {
  static const primaryColor = Color(0Xff692960);
  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,

    // colors
    colorScheme: const ColorScheme.light(
      primary: primaryColor,
      secondary: Color(0XFF8E8E93),
      surface: Colors.white,

      // adding complementary colors that work well with #acdde0
      tertiary: Color(0XFF7CBEC2),
      onPrimary: Colors.black87,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.white,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
        color: Colors.black,
        fontSize: 18,
        fontWeight: FontWeight.w600,
      ),
      iconTheme: IconThemeData(color: Colors.black),
    ),
  );
}
