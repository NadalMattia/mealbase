import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Snackbar di feedback standard dell'app.
///
/// Prima questo stesso blocco (icona + testo + sfondo nero + bordi
/// arrotondati + margine) era copiato e incollato identico in
/// pantry_screen, shopping_list_screen, product_form_screen,
/// shopping_item_edit_screen e shopping_scanner_screen. Centralizzarlo qui
/// significa che un domani basta cambiare stile in un solo punto.
class AppSnackbar {
  AppSnackbar._();

  /// Feedback positivo/neutro (conferma, inserimento, modifica...).
  static void show(
    BuildContext context, {
    required String message,
    IconData icon = Icons.check_circle_outline,
    Duration duration = const Duration(seconds: 2),
    EdgeInsets margin = const EdgeInsets.only(bottom: 24, left: 16, right: 16),
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: AppColors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: AppColors.feedbackBackground,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lg)),
        margin: margin,
        duration: duration,
      ),
    );
  }

  /// Feedback di eliminazione. Usa lo stesso stile ma un'icona/margine
  /// pensati per non coprire la bottom bar pillola dell'app.
  static void showDeleted(
    BuildContext context, {
    required String message,
  }) {
    show(
      context,
      message: message,
      icon: Icons.delete_outline,
      margin: const EdgeInsets.only(bottom: 90, left: 16, right: 16),
    );
  }

  /// Feedback per funzionalità non ancora implementate.
  static void showComingSoon(BuildContext context, String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$feature in arrivo!')),
    );
  }
}
