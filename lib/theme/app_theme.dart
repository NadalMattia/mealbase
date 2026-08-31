import 'package:flutter/material.dart';

/// Palette colori dell'app. Prima d'ora ogni schermata definiva i propri
/// `Colors.black87` / `Colors.grey.shade400` "a mano": centralizzarli qui
/// permette di cambiare il look dell'app da un solo punto e rende evidente
/// quali colori fanno parte del design system.
class AppColors {
  AppColors._();

  static const Color black = Colors.black;
  static const Color white = Colors.white;
  static const Color danger = Colors.redAccent;

  static final Color grey50 = Colors.grey.shade50;
  static final Color grey100 = Colors.grey.shade100;
  static final Color grey200 = Colors.grey.shade200;
  static final Color grey300 = Colors.grey.shade300;
  static final Color grey400 = Colors.grey.shade400;
  static final Color grey500 = Colors.grey.shade500;
  static final Color grey600 = Colors.grey.shade600;

  /// Sfondo scuro usato dalle schermate fotocamera/scanner.
  static const Color scannerBackground = Color(0xFF1A1A1A);

  static const Color feedbackBackground = Colors.black87;
}

/// Raggi di bordo standard, per non ritrovarsi valori come 12, 16, 20, 24, 32
/// sparsi a caso nei vari file.
class AppRadius {
  AppRadius._();

  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
  static const double xxl = 24;
  static const double pill = 32;
}

/// Spaziature standard (multipli di 4, come nel resto dell'app).
class AppSpacing {
  AppSpacing._();

  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
  static const double xxl = 40;
}

/// Stili testo riutilizzabili, estratti dai vari screen dove erano
/// duplicati con gli stessi identici valori (bold + letterSpacing).
class AppTextStyles {
  AppTextStyles._();

  static const TextStyle screenTitle = TextStyle(
    fontWeight: FontWeight.bold,
    fontSize: 20,
    color: AppColors.black,
  );

  static const TextStyle sectionLabel = TextStyle(
    fontWeight: FontWeight.bold,
    fontSize: 16,
    letterSpacing: 2.0,
    color: AppColors.black,
  );

  static const TextStyle fieldLabel = TextStyle(
    fontWeight: FontWeight.bold,
    letterSpacing: 1.0,
    fontSize: 12,
    color: AppColors.black,
  );

  static const TextStyle cardTitle = TextStyle(
    fontWeight: FontWeight.w600,
    fontSize: 12,
    color: AppColors.black,
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
    color: AppColors.black,
  );

  static TextStyle emptyState = TextStyle(color: AppColors.grey400);
  static TextStyle hint = TextStyle(color: AppColors.grey400, fontSize: 14);
  static TextStyle subtitle = TextStyle(color: AppColors.grey500, fontSize: 13);
}

/// Tema Material dell'app. Prima veniva impostato `primarySwatch: Colors.teal`
/// in `main.dart` ma non era mai davvero utilizzato: tutte le schermate
/// disegnavano manualmente in bianco/nero/grigio. Questo tema riflette lo
/// stile minimale che l'app usa realmente.
ThemeData buildAppTheme() {
  final colorScheme = ColorScheme.fromSeed(
    seedColor: AppColors.black,
    brightness: Brightness.light,
  ).copyWith(
    primary: AppColors.black,
    onPrimary: AppColors.white,
    secondary: AppColors.black,
    surface: AppColors.white,
    error: AppColors.danger,
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: colorScheme,
    scaffoldBackgroundColor: AppColors.white,
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.white,
      foregroundColor: AppColors.black,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: AppTextStyles.screenTitle,
    ),
    textSelectionTheme: const TextSelectionThemeData(cursorColor: AppColors.black),
    dividerTheme: DividerThemeData(color: AppColors.grey200),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: AppColors.black,
      foregroundColor: AppColors.white,
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: AppColors.feedbackBackground,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lg)),
    ),
  );
}
