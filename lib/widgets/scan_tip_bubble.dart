import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Piccolo suggerimento contestuale che segnala la funzione più
/// distintiva dell'app (lo scanner barcode) senza un tutorial invasivo.
///
/// Compare una sola volta nella vita dell'app (lo stato "già visto" è
/// gestito da `OnboardingService`, non da questo widget), e si chiude
/// toccandolo ovunque — nessuna freccia o overlay a schermo intero,
/// nessuna sequenza di più tip da chiudere uno dopo l'altro.
class ScanTipBubble extends StatelessWidget {
  final VoidCallback onDismiss;

  const ScanTipBubble({super.key, required this.onDismiss});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.md),
        onTap: onDismiss,
        child: Container(
          constraints: const BoxConstraints(maxWidth: 230),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: AppColors.verdeBosco,
            borderRadius: BorderRadius.circular(AppRadius.md),
            boxShadow: [
              BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 8, offset: const Offset(0, 3)),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.qr_code_scanner, color: AppColors.white, size: 18),
              const SizedBox(width: 8),
              const Flexible(
                child: Text(
                  'Scansiona il codice a barre per compilare tutto in automatico',
                  style: TextStyle(color: AppColors.white, fontSize: 12, fontWeight: FontWeight.w600),
                ),
              ),
              const SizedBox(width: 6),
              const Icon(Icons.close, color: Colors.white70, size: 16),
            ],
          ),
        ),
      ),
    );
  }
}
