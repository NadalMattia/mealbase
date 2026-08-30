import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';
import '../theme/app_theme.dart';

/// Mostrata al posto del feed camera quando il permesso fotocamera è
/// negato (definitivamente o meno).
///
/// Prima, senza `errorBuilder`, se il permesso mancava `MobileScanner`
/// restituiva semplicemente uno schermo nero senza alcun messaggio:
/// l'utente non capiva se l'app fosse bloccata o se mancasse qualcosa.
/// Con questo widget l'errore diventa visibile e azionabile.
class ScannerPermissionDenied extends StatelessWidget {
  final VoidCallback onClose;

  const ScannerPermissionDenied({super.key, required this.onClose});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.scannerBackground,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.no_photography_outlined, color: AppColors.grey400, size: 48),
              const SizedBox(height: 20),
              const Text(
                'Permesso fotocamera necessario',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Per scansionare i codici a barre, consenti l\'accesso alla '
                'fotocamera dalle impostazioni del telefono.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.grey400, fontSize: 13),
              ),
              const SizedBox(height: 28),
              InkWell(
                onTap: () => openAppSettings(),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                  child: const Text(
                    'APRI IMPOSTAZIONI',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 1.0),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: onClose,
                child: Text('Torna indietro', style: TextStyle(color: AppColors.grey400)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
///
/// Prima `scanner_screen.dart` e `shopping_scanner_screen.dart`
/// duplicavano identici `_buildViewfinder`, `_buildCorner` e
/// `_buildControlButton`. Ora sono due widget riusabili.
class ScannerViewfinder extends StatelessWidget {
  const ScannerViewfinder({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 260,
      height: 260,
      child: Stack(
        children: [
          Positioned(top: 0, left: 0, child: _Corner(top: true, left: true)),
          Positioned(top: 0, right: 0, child: _Corner(top: true, left: false)),
          Positioned(bottom: 0, left: 0, child: _Corner(top: false, left: true)),
          Positioned(bottom: 0, right: 0, child: _Corner(top: false, left: false)),
          Center(
            child: Container(
              width: double.infinity,
              height: 2,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.5),
                boxShadow: [
                  BoxShadow(
                    color: Colors.white.withOpacity(0.6),
                    blurRadius: 8,
                    spreadRadius: 2,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Corner extends StatelessWidget {
  final bool top;
  final bool left;

  const _Corner({required this.top, required this.left});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        border: Border(
          top: top ? const BorderSide(color: Colors.white, width: 4) : BorderSide.none,
          bottom: !top ? const BorderSide(color: Colors.white, width: 4) : BorderSide.none,
          left: left ? const BorderSide(color: Colors.white, width: 4) : BorderSide.none,
          right: !left ? const BorderSide(color: Colors.white, width: 4) : BorderSide.none,
        ),
        borderRadius: BorderRadius.only(
          topLeft: top && left ? const Radius.circular(16) : Radius.zero,
          topRight: top && !left ? const Radius.circular(16) : Radius.zero,
          bottomLeft: !top && left ? const Radius.circular(16) : Radius.zero,
          bottomRight: !top && !left ? const Radius.circular(16) : Radius.zero,
        ),
      ),
    );
  }
}

/// Riga di controlli in alto (flash / chiudi), comune alle due schermate
/// scanner.
///
/// Prima l'icona del flash rifletteva una variabile locale (`_isFlashOn`)
/// tenuta manualmente in sync dalla schermata chiamante: la versione di
/// `mobile_scanner` in uso ha un bug noto per cui lo stato della torcia
/// risulta invertito subito dopo `toggleTorch()`, quindi quella variabile
/// poteva disallinearsi da cosa stava facendo davvero la fotocamera (icona
/// "accesa" col flash spento o viceversa). Ora l'icona legge lo stato vero
/// direttamente dal controller (`controller.value.torchState`), che è
/// sempre la fonte di verità.
class ScannerTopControls extends StatelessWidget {
  final MobileScannerController controller;
  final VoidCallback onCloseTap;

  const ScannerTopControls({
    super.key,
    required this.controller,
    required this.onCloseTap,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            ValueListenableBuilder<MobileScannerState>(
              valueListenable: controller,
              builder: (context, state, child) {
                final torch = state.torchState;
                // Se il dispositivo non ha una torcia (rilevato dal
                // controller stesso), disabilitiamo il tasto invece di
                // lasciarlo cliccabile senza alcun effetto.
                final isUnavailable = torch == TorchState.unavailable;
                return _ControlButton(
                  icon: torch == TorchState.on ? Icons.flash_on : Icons.flash_off,
                  onTap: isUnavailable ? null : () => controller.toggleTorch(),
                  disabled: isUnavailable,
                );
              },
            ),
            _ControlButton(icon: Icons.close, onTap: onCloseTap),
          ],
        ),
      ),
    );
  }
}

class _ControlButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final bool disabled;

  const _ControlButton({required this.icon, required this.onTap, this.disabled = false});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(30),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(disabled ? 0.06 : 0.15),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: disabled ? Colors.white38 : Colors.white, size: 24),
      ),
    );
  }
}
