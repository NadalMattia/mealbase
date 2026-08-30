import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';
import '../providers/shopping_list_provider.dart';
import '../services/barcode_service.dart';
import '../theme/app_theme.dart';
import '../utils/app_snackbar.dart';
import '../widgets/scanner_chrome.dart';

/// Scanner barcode per aggiungere rapidamente un prodotto alla lista della
/// spesa. Come `scanner_screen.dart`, ora usa la fotocamera reale
/// (mobile_scanner) e `BarcodeService` per precompilare il nome: prima era
/// solo un campo testo manuale dietro a un mirino disegnato.
class ShoppingScannerScreen extends StatefulWidget {
  const ShoppingScannerScreen({super.key});

  @override
  State<ShoppingScannerScreen> createState() => _ShoppingScannerScreenState();
}

class _ShoppingScannerScreenState extends State<ShoppingScannerScreen> {
  final MobileScannerController _controller = MobileScannerController();
  final BarcodeService _barcodeService = BarcodeService();
  final TextEditingController _nomeController = TextEditingController();

  bool _isLookingUp = false;

  @override
  void dispose() {
    _controller.dispose();
    _nomeController.dispose();
    super.dispose();
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_isLookingUp || _nomeController.text.trim().isNotEmpty) return;

    final code = capture.barcodes.isNotEmpty ? capture.barcodes.first.rawValue : null;
    if (code == null || code.isEmpty) return;

    setState(() => _isLookingUp = true);
    final result = await _barcodeService.lookup(code);
    if (!mounted) return;

    if (result.found && result.nome != null) {
      // Precompila il nome ma lascia comunque il campo modificabile e la
      // conferma manuale prima di aggiungere: l'utente resta in controllo.
      setState(() => _nomeController.text = result.nome!);
    } else {
      AppSnackbar.show(
        context,
        message: 'Prodotto non trovato: scrivi il nome manualmente',
        icon: Icons.info_outline,
      );
    }
    setState(() => _isLookingUp = false);
  }

  void _save() {
    if (_nomeController.text.trim().isEmpty) return;

    context.read<ShoppingListProvider>().addItem(_nomeController.text.trim());
    AppSnackbar.show(context, message: 'Prodotto aggiunto alla spesa');
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scannerBackground,
      resizeToAvoidBottomInset: true,
      body: Stack(
        children: [
          MobileScanner(
            controller: _controller,
            onDetect: _onDetect,
            errorBuilder: (context, error, child) {
              return ScannerPermissionDenied(onClose: () => Navigator.pop(context));
            },
          ),
          Container(color: Colors.black.withOpacity(0.35)),
          const Center(child: ScannerViewfinder()),
          ScannerTopControls(
            controller: _controller,
            onCloseTap: () => Navigator.pop(context),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: _buildAddFormBottomSheet(context),
          ),
        ],
      ),
    );
  }

  Widget _buildAddFormBottomSheet(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
      decoration: const BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.pill)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.grey300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 24),
          InkWell(
            onTap: () => AppSnackbar.showComingSoon(context, 'Selezione immagine'),
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: AppColors.grey100,
                borderRadius: BorderRadius.circular(AppRadius.xxl),
              ),
              child: Icon(Icons.image, color: AppColors.grey300, size: 36),
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              const Text('PRODOTTO', style: AppTextStyles.fieldLabel),
              const SizedBox(width: 16),
              Expanded(
                child: Container(
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.grey50,
                    borderRadius: BorderRadius.circular(AppRadius.xl),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _nomeController,
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          ),
                        ),
                      ),
                      if (_isLookingUp)
                        const Padding(
                          padding: EdgeInsets.only(right: 12),
                          child: SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          InkWell(
            onTap: _save,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 18),
              decoration: BoxDecoration(
                color: AppColors.black,
                borderRadius: BorderRadius.circular(AppRadius.pill),
              ),
              alignment: Alignment.center,
              child: const Text('AGGIUNGI', style: AppTextStyles.pillButtonLabel),
            ),
          ),
        ],
      ),
    );
  }
}
