import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// "Invito persistente" mostrato quando la dispensa della casa corrente
/// non contiene ancora nessun prodotto.
///
/// Non richiede alcuno stato salvato né logica di "non mostrare più":
/// scompare da solo appena viene aggiunto il primo prodotto, perché chi
/// lo mostra (`PantryProductList`) osserva già `PantryProvider` e si
/// ricostruisce automaticamente ad ogni cambiamento. Rimane finché la
/// condizione che lo giustifica (dispensa vuota) è vera, esattamente
/// come un invito persistente dovrebbe comportarsi.
class PantryEmptyState extends StatelessWidget {
  const PantryEmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.kitchen_outlined, size: 64, color: AppColors.grey300),
            const SizedBox(height: 16),
            const Text(
              'La tua dispensa è vuota',
              textAlign: TextAlign.center,
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.grey600),
            ),
            const SizedBox(height: 8),
            const Text(
              'Tocca "Inserisci" o "Scansiona" qui sotto\nper aggiungere il tuo primo prodotto',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: AppColors.grey400),
            ),
          ],
        ),
      ),
    );
  }
}
