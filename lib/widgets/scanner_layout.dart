import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../theme/app_theme.dart';
import 'scanner_chrome.dart';

/// Layout base per le schermate di scansione
/// Gestisce nativamente il ciclo di vita e le autorizzazioni della fotocamera.
class ScannerLayout extends StatefulWidget {
  final Function(BarcodeCapture) onDetect;
  final Widget Function(BuildContext context, MobileScannerController controller) bottomSheetBuilder;
  final bool resizeToAvoidBottomInset;

  const ScannerLayout({
    super.key,
    required this.onDetect,
    required this.bottomSheetBuilder,
    this.resizeToAvoidBottomInset = false,
  });

  @override
  State<ScannerLayout> createState() => _ScannerLayoutState();
}

class _ScannerLayoutState extends State<ScannerLayout> {
  final MobileScannerController _controller = MobileScannerController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scannerBackground,
      resizeToAvoidBottomInset: widget.resizeToAvoidBottomInset,
      body: Stack(
        children: [
          // 1. STREAM FOTOCAMERA ISOLATO (MobileScanner gestisce nativamente permessi ed avvio)
          Positioned.fill(
            child: RepaintBoundary(
              child: MobileScanner(
                controller: _controller,
                onDetect: widget.onDetect,
                errorBuilder: (context, error) {
                  if (error.errorCode == MobileScannerErrorCode.permissionDenied) {
                    return ScannerPermissionDenied(onClose: () => Navigator.pop(context));
                  }

                  return Container(
                    color: AppColors.scannerBackground,
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.videocam_off_outlined, color: AppColors.grey400, size: 48),
                        const SizedBox(height: 16),
                        const Text(
                          'Errore fotocamera',
                          style: TextStyle(color: AppColors.white, fontWeight: FontWeight.bold, fontSize: 16),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          error.errorDetails?.message ?? error.errorCode.name,
                          style: TextStyle(color: AppColors.grey400, fontSize: 12),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),

          // 2. OVERLAY E MIRINO GRAFICO
          Positioned.fill(
            child: IgnorePointer(
              child: Container(color: Colors.black.withOpacity(0.35)),
            ),
          ),
          const IgnorePointer(
            child: Center(child: ScannerViewfinder()),
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: ScannerTopControls(
              controller: _controller,
              onCloseTap: () => Navigator.pop(context),
            ),
          ),

          // 3. TENDINA TRASCINABILE INFERIORE
          Positioned.fill(
            child: widget.bottomSheetBuilder(context, _controller),
          ),
        ],
      ),
    );
  }
}