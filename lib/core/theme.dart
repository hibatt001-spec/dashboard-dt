import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // --- ألوان الوضع الداكن (Mode Nuit) ---
  static const Color primaryColor = Color(0xFF00F0FF); // Cyan blue
  static const Color backgroundColor = Color(0xFF0F172A); // Dark industrial
  static const Color surfaceColor = Color(0xFF1E293B);
  static const Color textPrimaryColor = Colors.white;
  static const Color textSecondaryColor = Colors.white70;

  // --- ألوان الوضع الفاتح الجديد (Mode Jour) ---
  static const Color primaryColorLight = Color(0xFF00A3B4); // Cyan داكن قليلاً ليتناسب مع الخلفية البيضاء
  static const Color backgroundColorLight = Color(0xFFF8FAFC); // خلفية فاتحة مريحة للعين
  static const Color surfaceColorLight = Colors.white;
  static const Color textPrimaryColorLight = Color(0xFF0F172A);
  static const Color textSecondaryColorLight = Colors.black54;

  // ==========================================
  // 🌙 1️⃣ الـ Dark Theme (الخاص بكِ بدون أي تغيير)
  // ==========================================
  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      primaryColor: primaryColor,
      scaffoldBackgroundColor: backgroundColor,
      colorScheme: const ColorScheme.dark(
        primary: primaryColor,
        surface: surfaceColor,
      ),
      textTheme: GoogleFonts.interTextTheme(
        ThemeData.dark().textTheme.copyWith(
          displayLarge: GoogleFonts.outfit(
            color: textPrimaryColor,
            fontWeight: FontWeight.bold,
          ),
          bodyLarge: const TextStyle(color: textPrimaryColor),
          bodyMedium: const TextStyle(color: textSecondaryColor),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: backgroundColor,
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: GoogleFonts.inter(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
          elevation: 8,
          shadowColor: primaryColor.withOpacity(0.5),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: backgroundColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: surfaceColor.withOpacity(0.5)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: surfaceColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primaryColor),
        ),
        labelStyle: const TextStyle(color: textSecondaryColor),
        prefixIconColor: textSecondaryColor,
      ),
    );
  }

  // ==========================================
  // ☀️ 2️⃣ الـ Light Theme المطور (Mode Jour)
  // ==========================================
  static ThemeData get lightTheme {
    return ThemeData(
      brightness: Brightness.light,
      primaryColor: primaryColorLight,
      scaffoldBackgroundColor: backgroundColorLight,
      colorScheme: const ColorScheme.light(
        primary: primaryColorLight,
        surface: surfaceColorLight,
      ),
      textTheme: GoogleFonts.interTextTheme(
        ThemeData.light().textTheme.copyWith(
          displayLarge: GoogleFonts.outfit(
            color: textPrimaryColorLight,
            fontWeight: FontWeight.bold,
          ),
          bodyLarge: const TextStyle(color: textPrimaryColorLight),
          bodyMedium: const TextStyle(color: textSecondaryColorLight),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColorLight,
          foregroundColor: Colors.white, // كتابة بيضاء فوق الزر السماوي
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: GoogleFonts.inter(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
          elevation: 4,
          shadowColor: primaryColorLight.withOpacity(0.3),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.grey[200], // خلفية رمادية خفيفة للحقول في الوضع الفاتح
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primaryColorLight),
        ),
        labelStyle: const TextStyle(color: textSecondaryColorLight),
        prefixIconColor: textSecondaryColorLight,
      ),
    );
  }
}