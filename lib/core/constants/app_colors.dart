import 'package:flutter/material.dart';

class AppColors {
  // --- ROAMING OFFICER (Green Theme - Default) ---
  static const Color roPrimary = Color(0xFF2E7D32);
  static const Color roPrimaryContainer = Color(0xFFC3EDC9);
  static const Color roOnPrimary = Color(0xFFFFFFFF);
  static const Color roAccent = Color(0xFF7FF500);
  static const Color roAccentContainer = Color(0xFFD5FFB3);

  // --- PASSENGER GUIDE (Red Theme) ---
  static const Color pgPrimary = Color(0xFFD32F2F);
  static const Color pgPrimaryContainer = Color(0xFFFFDAD4);
  static const Color pgOnPrimary = Color(0xFFFFFFFF);
  static const Color pgAccent = Color(0xFFF57C00);
  static const Color pgAccentContainer = Color(0xFFFFDDB3);

  // --- Common / Shared Colors ---
  static const Color background = Color(0xFFFDFBFF);
  static const Color surface = Color(0xFFFDFBFF);
  static const Color onSurface = Color(0xFF1B1B1F);
  static const Color onSurfaceVariant = Color(0xFF44474E);
  static const Color outline = Color(0xFF74777F);

  static const Color success = Color(0xFF2E7D32);
  static const Color error = Color(0xFFBA1A1A);
  static const Color warning = Color(0xFFF9A825);

  static const Color textPrimary = Color(0xFF1B1B1F);
  static const Color textSecondary = Color(0xFF44474E);
  static const Color textTertiary = Color(0xFF74777F);

  // Default values for backward compatibility (defaults to Green)
  static const Color primary = roPrimary;
  static const Color accent = roAccent;
}
