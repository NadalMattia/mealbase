import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Messaggi temporanei di conferma ed errore, con stile uniforme in tutta
/// l'app.
///
/// Ogni metodo chiude la snackbar corrente prima di mostrarne una nuova:
/// senza, i messaggi si accoderebbero e l'utente ne vedrebbe di vecchi
/// comparire dopo azioni nuove.
///
/// Classe di soli membri statici, non istanziabile: non ha stato da
/// conservare.
class AppSnackbar {
  AppSnackbar._();

  /// Chiude immediatamente la snackbar visibile, se presente.
  static void hide(BuildContext context) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
  }

  /// Mostra un messaggio con icona.
  ///
  /// Restituisce il controller della snackbar, il cui future `closed`
  /// riporta il motivo della chiusura.
  static ScaffoldFeatureController<SnackBar, SnackBarClosedReason> show(
      BuildContext context, {
        required String message,
        IconData icon = Icons.check_circle_outline,
        Duration duration = const Duration(seconds: 2),
        EdgeInsets margin = const EdgeInsets.only(bottom: 24, left: 16, right: 16),
      }) {
    hide(context);
    return ScaffoldMessenger.of(context).showSnackBar(
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
        dismissDirection: DismissDirection.horizontal,
      ),
    );
  }

  /// Mostra la conferma di un'eliminazione, con l'azione di annullamento
  /// se [onUndo] è fornita.
  ///
  /// Il margine inferiore è più ampio di quello di [show] per non finire
  /// sotto la barra di azioni della dispensa.
  ///
  /// Il controller restituito permette al chiamante di attendere
  /// `closed` e decidere in base al [SnackBarClosedReason] se rendere
  /// definitiva l'eliminazione.
  static ScaffoldFeatureController<SnackBar, SnackBarClosedReason> showDeleted(
      BuildContext context, {
        required String message,
        VoidCallback? onUndo,
        Duration duration = const Duration(seconds: 2),
      }) {
    return ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.delete_outline, color: AppColors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: AppColors.feedbackBackground,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lg)),
        margin: const EdgeInsets.only(bottom: 90, left: 16, right: 16),
        duration: duration,
        dismissDirection: DismissDirection.horizontal,
        action: onUndo != null
            ? SnackBarAction(
          label: 'ANNULLA',
          textColor: Colors.amber,
          onPressed: onUndo,
        )
            : null,
      ),
    );
  }

  /// Segnala che [feature] non è ancora disponibile.
  static void showComingSoon(BuildContext context, String feature) {
    show(context, message: '$feature in arrivo!', icon: Icons.access_time);
  }
}