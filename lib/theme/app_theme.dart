import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // --- PALETTE PRINCIPALE "ORGANIC FRESH" ---
  static const Color pannaWarm = Color(0xFFF9F8F6);     // Sfondo principale
  static const Color verdeSalvia = Color(0xFF6B8E78);   // Primary / Tasti azione
  static const Color albicoccaSoft = Color(0xFFE8A588); // Accenti
  static const Color verdeBosco = Color(0xFF1E2B22);    // Testi, bordi e icone principali

  // --- ALIAS PER COMPATIBILITÀ ---
  static const Color black = verdeBosco;
  static const Color white = Colors.white;
  static const Color danger = Color(0xFFDC2626);

  // --- TONI DI GRIGIO WARM & DESATURATI ---
  static const Color grey50 = Color(0xFFF3F4F1);
  static const Color grey100 = Color(0xFFE8E8E3);
  static const Color grey200 = Color(0xFFD6D6CF);
  static const Color grey300 = Color(0xFFC2C2B8);
  static const Color grey400 = Color(0xFF9E9E92);
  static const Color grey500 = Color(0xFF7A7A70);
  static const Color grey600 = Color(0xFF57574E);

  // --- UTILITY & SCANNER ---
  static const Color scannerBackground = Color(0xFF1A1A1A);
  static const Color feedbackBackground = Color(0xFF1E2B22);

  // --- CARD DISPENSA (STATI SCADENZA) ---
  static const Color statusExpiredBg = Color(0xFFFEF2F2);
  static const Color statusExpiredBorder = Color(0xFFFCA5A5);

  static const Color statusWarningBg = Color(0xFFFFFBEB);
  static const Color statusWarningBorder = Color(0xFFFDE68A);

  static const Color statusFreshBg = Color(0xFFF0FDF4);
  static const Color statusFreshBorder = Color(0xFFBBF7D0);

  static const Color statusNoDateBg = Color(0xFFF4F4F2);
  static const Color statusNoDateBorder = Color(0xFFE2E2DC);

  // --- CARD SPESA ---
  static const Color statusShoppingBg = Color(0xFFF0F9FF);
  static const Color statusShoppingBorder = Color(0xFFBAE6FD);
}

class AppRadius {
  AppRadius._();
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
  static const double xxl = 24;
  static const double pill = 32;
}

class AppSpacing {
  AppSpacing._();
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
  static const double xxl = 40;
}

class AppTextStyles {
  AppTextStyles._();

  static const TextStyle screenTitle = TextStyle(
    fontWeight: FontWeight.w900,
    fontSize: 22,
    letterSpacing: 0.5,
    color: AppColors.verdeBosco,
  );

  static const TextStyle sectionLabel = TextStyle(
    fontWeight: FontWeight.bold,
    fontSize: 16,
    letterSpacing: 2.0,
    color: AppColors.verdeBosco,
  );

  static const TextStyle fieldLabel = TextStyle(
    fontWeight: FontWeight.bold,
    letterSpacing: 1.0,
    fontSize: 12,
    color: AppColors.verdeBosco,
  );

  static const TextStyle cardTitle = TextStyle(
    fontWeight: FontWeight.bold,
    fontSize: 12,
    color: AppColors.verdeBosco,
  );

  static const TextStyle pillButtonLabel = TextStyle(
    color: AppColors.white,
    fontWeight: FontWeight.bold,
    fontSize: 12,
    letterSpacing: 1.0,
  );

  static const TextStyle primaryActionLabel = TextStyle(
    fontWeight: FontWeight.bold,
    letterSpacing: 2.0,
    fontSize: 16,
    color: AppColors.verdeBosco,
  );

  static const TextStyle emptyState = TextStyle(color: AppColors.grey400, fontSize: 14);
  static const TextStyle hint = TextStyle(color: AppColors.grey400, fontSize: 14);
  static const TextStyle subtitle = TextStyle(color: AppColors.grey500, fontSize: 13);
}

ThemeData buildAppTheme() {
  final colorScheme = ColorScheme.fromSeed(
    seedColor: AppColors.verdeSalvia,
    brightness: Brightness.light,
  ).copyWith(
    primary: AppColors.verdeSalvia,
    onPrimary: AppColors.white,
    secondary: AppColors.albicoccaSoft,
    surface: AppColors.pannaWarm,
    error: AppColors.danger,
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: colorScheme,
    scaffoldBackgroundColor: AppColors.pannaWarm,
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.pannaWarm,
      foregroundColor: AppColors.verdeBosco,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      titleTextStyle: AppTextStyles.screenTitle,
    ),
    textSelectionTheme: const TextSelectionThemeData(cursorColor: AppColors.verdeBosco),
    dividerTheme: const DividerThemeData(color: AppColors.grey200),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: AppColors.verdeSalvia,
      foregroundColor: AppColors.white,
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: AppColors.feedbackBackground,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lg)),
    ),
  );
}