import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class AppSnackbar {
  AppSnackbar._();

  static void hide(BuildContext context) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
  }

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

  static ScaffoldFeatureController<SnackBar, SnackBarClosedReason> showDeleted(
      BuildContext context, {
        required String message,
        VoidCallback? onUndo,
        Duration duration = const Duration(seconds: 2),
      }) {
    hide(context);
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

  static void showComingSoon(BuildContext context, String feature) {
    show(context, message: '$feature in arrivo!', icon: Icons.access_time);
  }
}