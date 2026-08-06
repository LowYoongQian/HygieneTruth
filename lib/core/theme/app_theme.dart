import 'package:flutter/material.dart';

class AppTheme {
  // Brand Palette matching "Hygiene Truth" Logo
  static const Color primaryColor = Color(0xFF00A88F); // Vibrant Teal from logo
  static const Color navyColor = Color(0xFF0C2340); // Deep Navy from logo "HT" monogram
  static const Color accentColor = Color(0xFF80EE98); // Mint Sparkle Accent

  static const Color backgroundColor = Color(0xFFF8FAFC); // Slate Soft Background
  static const Color surfaceColor = Colors.white;
  static const Color borderColor = Color(0xFFE2E8F0);
  static const Color textColor = Color(0xFF0C2340);
  static const Color subtitleColor = Color(0xFF64748B);

  // Status Indicator Colors
  static const Color safeColor = Color(0xFF10B981);
  static const Color moderateColor = Color(0xFFF59E0B);
  static const Color highRiskColor = Color(0xFFEF4444);

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        primary: primaryColor,
        secondary: navyColor,
        surface: surfaceColor,
        error: highRiskColor,
      ),
      scaffoldBackgroundColor: backgroundColor,
      appBarTheme: const AppBarTheme(
        elevation: 0,
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: textColor,
        iconTheme: IconThemeData(color: textColor),
        titleTextStyle: TextStyle(
          color: textColor,
          fontSize: 17,
          fontWeight: FontWeight.bold,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: surfaceColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: borderColor, width: 1.2),
        ),
        margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryColor,
          side: const BorderSide(color: primaryColor, width: 1.2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
