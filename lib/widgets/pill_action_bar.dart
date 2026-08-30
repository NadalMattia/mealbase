import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Una singola azione dentro una [PillActionBar].
class PillBarAction {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  /// Colore di icona/testo per questa azione (es. rosso per "elimina").
  /// Se null usa il bianco standard.
  final Color? color;

  const PillBarAction({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color,
  });
}

/// Barra nera, pillola, con 2 (o più) azioni separate da un divisore.
///
/// Prima questo stesso widget esisteva duplicato (con nomi diversi ma
/// codice identico) come `_ScanInsertBar`/`_BarButton` in pantry_screen.dart
/// e come `_DeleteSelectionBar` sia in pantry_screen.dart che in
/// shopping_list_screen.dart. Ora è un solo widget riusabile ovunque serva
/// una barra di azioni in stile "pillola".
class PillActionBar extends StatelessWidget {
  final List<PillBarAction> actions;

  const PillActionBar({super.key, required this.actions});

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 8,
      borderRadius: BorderRadius.circular(AppRadius.pill),
      color: AppColors.black,
      child: SizedBox(
        height: 56,
        child: Row(
          children: [
            for (var i = 0; i < actions.length; i++) ...[
              if (i > 0) Container(width: 1, height: 28, color: Colors.white38),
              Expanded(
                child: _PillBarButton(
                  action: actions[i],
                  borderRadius: _radiusFor(i, actions.length),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  BorderRadius _radiusFor(int index, int length) {
    if (index == 0) {
      return const BorderRadius.horizontal(left: Radius.circular(AppRadius.pill));
    }
    if (index == length - 1) {
      return const BorderRadius.horizontal(right: Radius.circular(AppRadius.pill));
    }
    return BorderRadius.zero;
  }
}

class _PillBarButton extends StatelessWidget {
  final PillBarAction action;
  final BorderRadius borderRadius;

  const _PillBarButton({required this.action, required this.borderRadius});

  @override
  Widget build(BuildContext context) {
    final color = action.color ?? AppColors.white;
    return InkWell(
      onTap: action.onTap,
      borderRadius: borderRadius,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(action.icon, color: color, size: 16),
          const SizedBox(width: 8),
          Text(action.label, style: AppTextStyles.pillButtonLabel.copyWith(color: color)),
        ],
      ),
    );
  }
}

/// Variante pronta all'uso: barra "ANNULLA / ELIMINA (n)" mostrata durante
/// la selezione multipla, comune a Dispensa e Lista della spesa.
class DeleteSelectionBar extends StatelessWidget {
  final int selectedCount;
  final VoidCallback onDelete;
  final VoidCallback onCancel;

  const DeleteSelectionBar({
    super.key,
    required this.selectedCount,
    required this.onDelete,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return PillActionBar(
      actions: [
        PillBarAction(icon: Icons.close, label: 'ANNULLA', onTap: onCancel),
        PillBarAction(
          icon: Icons.delete,
          label: 'ELIMINA ($selectedCount)',
          onTap: onDelete,
          color: AppColors.danger,
        ),
      ],
    );
  }
}
