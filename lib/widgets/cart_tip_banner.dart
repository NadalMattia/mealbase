import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Banner inline che spiega, una sola volta, il meccanismo che ha
/// generato più confusione nella valutazione con utenti (problemi P4/P8
/// della relazione: distinzione poco chiara tra "Spesa" e "Carrello", e
/// utenti che non capivano che toccare un prodotto lo sposta da una
/// lista all'altra).
///
/// A differenza di [ScanTipBubble] (una bolla fluttuante sopra un
/// pulsante) questo è un banner inline dentro la lista scrollabile:
/// più adatto qui perché non deve "puntare" a un pulsante fisso, ma
/// stare vicino agli articoli a cui si riferisce. Si chiude con la "x"
/// e non ricompare più (stato salvato tramite `OnboardingService`).
class CartTipBanner extends StatelessWidget {
  final VoidCallback onDismiss;

  const CartTipBanner({super.key, required this.onDismiss});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.verdeSalvia.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: AppColors.verdeSalvia.withValues(alpha: 0.3)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.touch_app_outlined, color: AppColors.verdeBosco, size: 20),
            const SizedBox(width: 10),
            const Expanded(
              child: Text(
                'Tocca un prodotto per spostarlo nel Carrello quando lo hai preso dallo scaffale',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.verdeBosco),
              ),
            ),
            InkWell(
              onTap: onDismiss,
              borderRadius: BorderRadius.circular(12),
              child: const Padding(
                padding: EdgeInsets.all(2),
                child: Icon(Icons.close, size: 16, color: AppColors.verdeBosco),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
