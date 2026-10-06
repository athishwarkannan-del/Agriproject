import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.turmeric,
        primary: AppColors.turmeric,
        secondary: AppColors.indigo,
        surface: AppColors.paper,
        error: AppColors.error,
      ),
      scaffoldBackgroundColor: AppColors.paper,
      
      fontFamily: GoogleFonts.muktaMalar().fontFamily,
      
      textTheme: TextTheme(
        displayLarge: TextStyle(
          fontFamily: GoogleFonts.fraunces().fontFamily,
          fontWeight: FontWeight.w900,
          color: AppColors.ink,
          letterSpacing: -0.5,
        ),
        displayMedium: TextStyle(
          fontFamily: GoogleFonts.fraunces().fontFamily,
          fontWeight: FontWeight.w900,
          color: AppColors.ink,
          letterSpacing: -0.5,
        ),
        titleLarge: TextStyle(
          fontFamily: GoogleFonts.fraunces().fontFamily,
          fontWeight: FontWeight.w700,
          color: AppColors.ink,
          fontSize: 19,
        ),
        bodyLarge: const TextStyle(color: AppColors.ink, fontSize: 16),
        bodyMedium: const TextStyle(color: AppColors.ink, fontSize: 14),
        labelLarge: TextStyle(
          fontWeight: FontWeight.w800,
          fontSize: 13,
          letterSpacing: 2,
          color: AppColors.sub,
        ),
      ),
      
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.paper,
        foregroundColor: AppColors.ink,
        elevation: 0,
        titleTextStyle: TextStyle(
          fontFamily: GoogleFonts.fraunces().fontFamily,
          fontWeight: FontWeight.w900,
          fontSize: 22,
          color: AppColors.ink,
          letterSpacing: -0.5,
        ),
      ),
      
      cardTheme: CardThemeData(
        color: AppColors.card,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: AppColors.ink, width: 2.5),
        ),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.leaf,
          foregroundColor: AppColors.textLight,
          textStyle: const TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 19,
          ),
          padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: const BorderSide(color: AppColors.ink, width: 2.5),
          ),
        ),
      ),
    );
  }
}
