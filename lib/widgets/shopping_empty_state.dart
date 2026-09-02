import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// "Invito persistente" mostrato quando la lista della spesa (sia la
/// sezione "da acquistare" sia "carrello") è completamente vuota.
///
/// Come [PantryEmptyState] in dispensa, non richiede nessuno stato
/// salvato: scompare da solo appena viene aggiunto il primo articolo,
/// perché chi lo mostra osserva già `ShoppingListProvider`.
class ShoppingEmptyState extends StatelessWidget {
  const ShoppingEmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 48),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.shopping_cart_outlined, size: 64, color: AppColors.grey300),
          const SizedBox(height: 16),
          const Text(
            'La tua lista della spesa è vuota',
            textAlign: TextAlign.center,
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.grey600),
          ),
          const SizedBox(height: 8),
          const Text(
            'Tocca il pulsante "+" qui sotto\nper aggiungere il primo articolo',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: AppColors.grey400),
          ),
        ],
      ),
    );
  }
}
