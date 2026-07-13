import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AppColors {
  static const Color primary     = Color(0xFF1A5C3A);
  static const Color primaryDark = Color(0xFF0F3623);
  static const Color secondary   = Color(0xFF2D7A50);
  static const Color accent      = Color(0xFF34D399);
  static const Color accentDark  = Color(0xFF059669);
  static const Color background  = Color(0xFF0F3623);
  static const Color surface     = Color(0xFFFFFFFF);
  static const Color cardBg      = Color(0xFFF4F7F5);

  static const Color online  = Color(0xFF16A34A);
  static const Color offline = Color(0xFFDC2626);
  static const Color warning = Color(0xFFD97706);
  static const Color info    = Color(0xFF2563EB);

  static const Color textDark   = Color(0xFF0C1F14);
  static const Color textMedium = Color(0xFF3D5A47);
  static const Color textLight  = Color(0xFF7A9E89);
  static const Color textWhite  = Color(0xFFFFFFFF);

  static const Color surfaceGreen  = Color(0xFFECF5EF);
  static const Color surfaceAccent = Color(0xFFD1FAE5);
  static const Color borderColor   = Color(0xFFD4E6DA);
}

class AppTheme {
  static ThemeData get theme => ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      brightness: Brightness.light,
    ).copyWith(
      primary: AppColors.primary,
      secondary: AppColors.accent,
      surface: AppColors.surface,
    ),
    scaffoldBackgroundColor: AppColors.cardBg,
    fontFamily: 'Roboto',
    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.surface,
      foregroundColor: AppColors.textDark,
      elevation: 0,
      centerTitle: false,
      scrolledUnderElevation: 1,
      shadowColor: AppColors.borderColor.withValues(alpha: 0.5),
      systemOverlayStyle: SystemUiOverlayStyle.dark,
      titleTextStyle: const TextStyle(
        color: AppColors.textDark,
        fontSize: 15,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.3,
      ),
      iconTheme: const IconThemeData(color: AppColors.primary),
    ),
    cardTheme: CardThemeData(
      color: AppColors.surface,
      elevation: 0,
      shadowColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.borderColor, width: 1),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.textWhite,
        minimumSize: const Size(double.infinity, 50),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        elevation: 0,
        textStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.3,
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.primary,
        minimumSize: const Size(double.infinity, 50),
        side: const BorderSide(color: AppColors.primary, width: 1.5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.surfaceGreen,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.borderColor),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.borderColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.primary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.offline),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      hintStyle: TextStyle(color: AppColors.textLight, fontSize: 14),
      prefixIconColor: AppColors.textLight,
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((s) =>
          s.contains(WidgetState.selected) ? AppColors.surface : AppColors.textLight),
      trackColor: WidgetStateProperty.resolveWith((s) =>
          s.contains(WidgetState.selected) ? AppColors.primary : AppColors.borderColor),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: AppColors.surfaceGreen,
      selectedColor: AppColors.surfaceAccent,
      labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primary),
      side: const BorderSide(color: AppColors.borderColor),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    ),
    dividerTheme: const DividerThemeData(color: AppColors.borderColor, thickness: 1),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: AppColors.surface,
      indicatorColor: AppColors.surfaceAccent,
      labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      labelTextStyle: WidgetStateProperty.resolveWith((s) => TextStyle(
        fontSize: 11,
        fontWeight: s.contains(WidgetState.selected) ? FontWeight.w700 : FontWeight.w500,
        color: s.contains(WidgetState.selected) ? AppColors.primary : AppColors.textLight,
      )),
      iconTheme: WidgetStateProperty.resolveWith((s) => IconThemeData(
        color: s.contains(WidgetState.selected) ? AppColors.primary : AppColors.textLight,
        size: 22,
      )),
    ),
  );
}

class AppTextStyles {
  static const screenLabel = TextStyle(
    fontSize: 10, fontWeight: FontWeight.w700,
    color: AppColors.textLight, letterSpacing: 1.8,
  );
  static const screenTitle = TextStyle(
    fontSize: 20, fontWeight: FontWeight.w900,
    color: AppColors.textDark, letterSpacing: -0.6,
  );
  static const cardTitle = TextStyle(
    fontSize: 13, fontWeight: FontWeight.w800,
    color: AppColors.textDark, letterSpacing: -0.2,
  );
  static const bodySmall = TextStyle(
    fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.textMedium,
  );
  static const monoBadge = TextStyle(
    fontSize: 10, fontWeight: FontWeight.w700,
    fontFamily: 'monospace', letterSpacing: 0.8,
  );
  static const statValue = TextStyle(
    fontSize: 22, fontWeight: FontWeight.w900,
    color: AppColors.textDark, letterSpacing: -0.5,
  );
}
