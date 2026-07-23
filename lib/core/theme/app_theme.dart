import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/app_colors.dart';
import 'transitions.dart';

class AppTheme {
  static const double _radius = 12.0;

  static ThemeData getTheme({bool isPassengerGuide = false}) {
    final Color primaryColor = isPassengerGuide ? AppColors.pgPrimary : AppColors.roPrimary;
    final Color accentColor = isPassengerGuide ? AppColors.pgAccent : AppColors.roAccent;

    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        primary: primaryColor,
        secondary: accentColor,
        surface: AppColors.surface,
        error: AppColors.error,
      ),
      textTheme: GoogleFonts.interTextTheme().copyWith(
        displayLarge: GoogleFonts.inter(letterSpacing: -1.2, fontWeight: FontWeight.normal),
        displayMedium: GoogleFonts.inter(letterSpacing: -1.0, fontWeight: FontWeight.normal),
        displaySmall: GoogleFonts.inter(letterSpacing: -0.8, fontWeight: FontWeight.normal),
        headlineMedium: GoogleFonts.inter(letterSpacing: -0.6, fontWeight: FontWeight.normal),
        titleLarge: GoogleFonts.inter(letterSpacing: -0.4, fontWeight: FontWeight.normal),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_radius),
          side: BorderSide(color: Colors.grey.withValues(alpha: 0.1)),
        ),
        color: Colors.white,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.grey.withValues(alpha: 0.05),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_radius),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_radius),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_radius),
          borderSide: BorderSide(color: primaryColor, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 56),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(_radius),
          ),
          elevation: 0,
        ),
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: AppPageTransitionsBuilder(),
          TargetPlatform.iOS: AppPageTransitionsBuilder(),
          TargetPlatform.windows: AppPageTransitionsBuilder(),
          TargetPlatform.macOS: AppPageTransitionsBuilder(),
        },
      ),
    );
  }

  // Keeping legacy getters for stability during transition, defaulting to Roaming Officer (Green)
  static ThemeData get lightTheme => getTheme(isPassengerGuide: false);
  static ThemeData get darkTheme => getTheme(isPassengerGuide: false).copyWith(brightness: Brightness.dark);
}
