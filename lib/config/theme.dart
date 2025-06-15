import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static const _primaryBlue = Color(0xFF2196F3); // Material Blue
  static const _accentBlue = Color(0xFF64B5F6); // Lighter Blue
  static const _darkBlue = Color(0xFF1976D2); // Darker Blue
  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.light(
      primary: _primaryBlue,
      secondary: _accentBlue,
      tertiary: _darkBlue,
      surface: Colors.white,
      background: Colors.grey[50]!,
      error: Colors.red[700]!,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: _primaryBlue,
      foregroundColor: Colors.white,
      elevation: 0,
    ),
    cardTheme: CardThemeData(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: _primaryBlue,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: _primaryBlue,
        side: BorderSide(color: _primaryBlue),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: _primaryBlue,
      ),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: _primaryBlue,
      foregroundColor: Colors.white,
    ),
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: _primaryBlue, width: 2),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Colors.grey[300]!),
      ),
    ),
    textTheme: GoogleFonts.robotoTextTheme().copyWith(
      displayLarge: TextStyle(color: Colors.grey[800]),
      displayMedium: TextStyle(color: Colors.grey[800]),
      displaySmall: TextStyle(color: Colors.grey[800]),
      headlineMedium: TextStyle(color: Colors.grey[800]),
      headlineSmall: TextStyle(color: Colors.grey[800]),
      titleLarge: TextStyle(color: Colors.grey[800]),
      bodyLarge: TextStyle(color: Colors.grey[800]),
      bodyMedium: TextStyle(color: Colors.grey[700]),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: _accentBlue.withOpacity(0.1),
      labelStyle: TextStyle(color: _darkBlue),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: _darkBlue,
      contentTextStyle: const TextStyle(color: Colors.white),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
    ),
    dividerTheme: const DividerThemeData(
      color: Colors.black12,
      thickness: 1,
    ),
    checkboxTheme: CheckboxThemeData(
      fillColor: MaterialStateProperty.resolveWith<Color>((states) {
        if (states.contains(MaterialState.selected)) {
          return _primaryBlue;
        }
        return Colors.grey;
      }),
    ),
    progressIndicatorTheme: ProgressIndicatorThemeData(
      color: _primaryBlue,
    ),
    tabBarTheme: TabBarThemeData(
      labelColor: _primaryBlue,
      unselectedLabelColor: Colors.grey,
      indicator: UnderlineTabIndicator(
        borderSide: BorderSide(width: 2.0, color: _primaryBlue),
      ),
    ),
  );
}
