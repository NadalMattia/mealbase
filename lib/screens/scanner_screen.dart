import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';
import '../providers/shopping_list_provider.dart';
import '../services/barcode_service.dart';
import '../theme/app_theme.dart';
import '../utils/app_snackbar.dart';
import '../widgets/product_card.dart';
import '../widgets/scanner_chrome.dart';
import 'product_form_screen.dart';

/// Scanner barcode per aggiungere rapidamente un prodotto in dispensa.
///
/// Prima questa schermata era solo una scenografia (un mirino disegnato su
/// sfondo nero, nessuna fotocamera reale): l'icona "SCANSIONA" prometteva
/// una funzione inesistente. `BarcodeService` esisteva ma non veniva mai
/// chiamato da nessuno screen. Ora la fotocamera è reale (mobile_scanner) e
/// il barcode letto viene cercato su Open Food Facts tramite
/// `BarcodeService`, precompilando il form del prodotto.
class ScannerScreen extends StatefulWidget {
  const ScannerScreen({super.key});

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen> {
  final MobileScannerController _controller = MobileScannerController();
  final BarcodeService _barcodeService = BarcodeService();

  bool _isProcessing = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_isProcessing) return;

    final code = capture.barcodes.isNotEmpty ? capture.barcodes.first.rawValue : null;
    if (code == null || code.isEmpty) return;

    setState(() => _isProcessing = true);
    await _controller.stop();

    final result = await _barcodeService.lookup(code);
    if (!mounted) return;

    if (result.found) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          fullscreenDialog: true,
          builder: (_) => ProductFormScreen(
            prefilledNome: result.nome,
            prefilledCategoria: result.categoria,
            prefilledImageUrl: result.imageUrl,
          ),
        ),
      );
    } else {
      AppSnackbar.show(
        context,
        message: 'Prodotto non trovato: inseriscilo manualmente',
        icon: Icons.info_outline,
      );
      setState(() => _isProcessing = false);
      await _controller.start();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scannerBackground,
      body: Stack(
        children: [
          // 0. Anteprima reale della fotocamera
          MobileScanner(
            controller: _controller,
            onDetect: _onDetect,
            // Prima l'assenza del permesso produceva solo uno schermo
            // nero senza spiegazioni. Ora mostriamo un messaggio chiaro
            // con un tasto per aprire le impostazioni di sistema.
            errorBuilder: (context, error, child) {
              return ScannerPermissionDenied(onClose: () => Navigator.pop(context));
            },
          ),

          // Overlay scuro per far risaltare il mirino sopra il feed camera
          Container(color: Colors.black.withOpacity(0.35)),

          // 1. Mirino dello scanner centrale
          const Center(child: ScannerViewfinder()),

          // 2. Pulsanti superiori (Flash e Chiudi)
          ScannerTopControls(
            controller: _controller,
            onCloseTap: () => Navigator.pop(context),
          ),

          // 3. Pannello inferiore "Carrello"
          Align(
            alignment: Alignment.bottomCenter,
            child: _buildCartBottomSheet(context),
          ),
        ],
      ),
    );
  }

  // Pannello bianco inferiore scorrevole
  Widget _buildCartBottomSheet(BuildContext context) {
    final provider = context.watch<ShoppingListProvider>();
    final cartItems = provider.giaPreso; // Prodotti segnati come "nel carrello"

    return Container(
      height: MediaQuery.of(context).size.height * 0.42,
      decoration: const BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.pill)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 12),
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.grey300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 24),
          const Center(child: Text('CARRELLO', style: AppTextStyles.sectionLabel)),
          const SizedBox(height: 24),
          Expanded(
            child: cartItems.isEmpty
                ? Center(
                    child: Text('Nessun prodotto nel carrello', style: AppTextStyles.subtitle),
                  )
                : GridView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: 0.8,
                    ),
                    itemCount: cartItems.length,
                    itemBuilder: (context, index) {
                      final item = cartItems[index];
                      return ProductCard(
                        name: item.nome,
                        onTap: () {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              fullscreenDialog: true,
                              builder: (_) => ProductFormScreen(prefilledNome: item.nome),
                            ),
                          );
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
