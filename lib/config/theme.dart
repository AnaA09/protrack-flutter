import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static const _primaryGreen = Color(0xFF4CAF50); // Material Green
  static const _accentGreen = Color(0xFF81C784); // Lighter Green
  static const _darkGreen = Color(0xFF388E3C); // Darker Green

  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.light(
      primary: _primaryGreen,
      secondary: _accentGreen,
      tertiary: _darkGreen,
      surface: Colors.white,
      background: Colors.grey[50]!,
      error: Colors.red[700]!,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: _primaryGreen,
      foregroundColor: Colors.white,
      elevation: 0,
    ),
    cardTheme: CardThemeData(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: _primaryGreen,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: _primaryGreen,
        side: BorderSide(color: _primaryGreen),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: _primaryGreen,
      ),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: _primaryGreen,
      foregroundColor: Colors.white,
    ),
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: _primaryGreen, width: 2),
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
      backgroundColor: _accentGreen.withOpacity(0.1),
      labelStyle: TextStyle(color: _darkGreen),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: _darkGreen,
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
          return _primaryGreen;
        }
        return Colors.grey;
      }),
    ),
    progressIndicatorTheme: ProgressIndicatorThemeData(
      color: _primaryGreen,
    ),
    tabBarTheme: TabBarThemeData(
      labelColor: _primaryGreen,
      unselectedLabelColor: Colors.grey,
      indicator: UnderlineTabIndicator(
        borderSide: BorderSide(width: 2.0, color: _primaryGreen),
      ),
    ),
  );
}
