import 'package:flutter/material.dart';

class AppColors {
  // Primary palette — Dark Forest (default)
  static const Color primary = Color(0xFF1A5C3A);
  static const Color secondary = Color(0xFF2D7A50);
  static const Color accent = Color(0xFF34D399);
  static const Color background = Color(0xFF0F3623);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color cardBg = Color(0xFFF8FAFC);

  // Status colors
  static const Color online = Color(0xFF22C55E);
  static const Color offline = Color(0xFFEF4444);
  static const Color warning = Color(0xFFF59E0B);
  static const Color info = Color(0xFF3B82F6);

  // Text
  static const Color textDark = Color(0xFF0F172A);
  static const Color textMedium = Color(0xFF475569);
  static const Color textLight = Color(0xFF94A3B8);
  static const Color textWhite = Color(0xFFFFFFFF);
}

class AppTheme {
  static ThemeData get theme => ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: AppColors.cardBg,
        fontFamily: 'Roboto',
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.surface,
          foregroundColor: AppColors.textDark,
          elevation: 0,
          centerTitle: false,
          titleTextStyle: TextStyle(
            color: AppColors.textDark,
            fontSize: 16,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.3,
          ),
        ),
        cardTheme: CardThemeData(
          color: AppColors.surface,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: Color(0xFFE2E8F0), width: 1),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: AppColors.textWhite,
            minimumSize: const Size(double.infinity, 48),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            textStyle: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.2,
            ),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: AppColors.cardBg,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.primary, width: 2),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      );
}

class AppTextStyles {
  static const screenLabel = TextStyle(
    fontSize: 10,
    fontWeight: FontWeight.w700,
    color: AppColors.textLight,
    letterSpacing: 1.5,
  );

  static const screenTitle = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w900,
    color: AppColors.textDark,
    letterSpacing: -0.5,
  );

  static const cardTitle = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w800,
    color: AppColors.textDark,
    letterSpacing: -0.2,
  );

  static const bodySmall = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: AppColors.textMedium,
  );

  static const monoBadge = TextStyle(
    fontSize: 10,
    fontWeight: FontWeight.w700,
    fontFamily: 'monospace',
    letterSpacing: 0.5,
  );
}
