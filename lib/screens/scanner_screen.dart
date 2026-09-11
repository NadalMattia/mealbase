import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';
import '../providers/shopping_list_provider.dart';
import '../services/barcode_service.dart';
import '../theme/app_theme.dart';
import '../utils/app_snackbar.dart';
import '../widgets/product_card.dart';
import '../widgets/scanner_layout.dart';
import 'product_form_screen.dart';

/// Scansione di un codice a barre per aggiungere un prodotto alla
/// dispensa.
///
/// Il foglio inferiore mostra il carrello, così un articolo già in lista
/// può essere inserito senza scansionarlo.
class ScannerScreen extends StatefulWidget {
  const ScannerScreen({super.key});

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen> {
  final BarcodeService _barcodeService = BarcodeService();
  final DraggableScrollableController _sheetController = DraggableScrollableController();
  bool _isProcessing = false;

  @override
  void dispose() {
    _sheetController.dispose();
    super.dispose();
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_isProcessing) return;

    final code = capture.barcodes.isNotEmpty ? capture.barcodes.first.rawValue : null;
    if (code == null || code.isEmpty) return;

    setState(() => _isProcessing = true);

    final result = await _barcodeService.lookup(code);
    if (!mounted) return;

    if (result.found) {
      final saved = await Navigator.push<bool>(
        context,
        MaterialPageRoute(
          fullscreenDialog: true,
          builder: (_) => ProductFormScreen(
            prefilledNome: result.nome,
            prefilledMarca: result.marca,
            prefilledCategoria: result.categoria,
            prefilledImageUrl: result.imageUrl,
            prefilledQuantita: 1,
          ),
        ),
      );

      if (!mounted) return;

      // Il form restituisce true solo se il prodotto è stato salvato: in
      // quel caso si chiude anche lo scanner, riportando l'utente alla
      // dispensa dove il prodotto appena inserito è già visibile.
      // Annullando il form si resta invece qui, pronti per una nuova
      // scansione.
      if (saved == true) {
        Navigator.pop(context);
        return;
      }

      setState(() => _isProcessing = false);
    } else {
      // Un codice assente dal database di Open Food Facts e una ricerca
      // fallita per mancanza di rete richiedono messaggi diversi: nel
      // secondo caso il prodotto potrebbe esistere e vale la pena
      // riprovare.
      AppSnackbar.show(
        context,
        message: result.networkError
            ? 'Connessione assente: controlla la rete e riprova'
            : 'Prodotto non trovato',
        icon: result.networkError ? Icons.wifi_off : Icons.info_outline,
      );
      Future.delayed(const Duration(milliseconds: 2500), () {
        if (mounted) setState(() => _isProcessing = false);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return ScannerLayout(
      onDetect: _onDetect,
      bottomSheetBuilder: (context, controller) => _buildCartBottomSheet(context),
    );
  }

  Widget _buildCartBottomSheet(BuildContext context) {
    final provider = context.watch<ShoppingListProvider>();
    final cartItems = provider.giaPreso;

    return DraggableScrollableSheet(
      controller: _sheetController,
      initialChildSize: 0.38,
      minChildSize: 0.12,
      maxChildSize: 0.85,
      snap: true,
      snapSizes: const [0.12, 0.38, 0.85],
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.pill)),
          ),
          child: Column(
            children: [
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onVerticalDragUpdate: (details) {
                  final screenHeight = MediaQuery.of(context).size.height;
                  final newSize = (_sheetController.size - details.primaryDelta! / screenHeight).clamp(0.12, 0.85);
                  _sheetController.jumpTo(newSize);
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Column(
                    children: [
                      Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(color: AppColors.grey300, borderRadius: BorderRadius.circular(2)),
                      ),
                      const SizedBox(height: 20),
                      const Text('CARRELLO', style: AppTextStyles.sectionLabel),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: cartItems.isEmpty
                    ? ListView(
                  controller: scrollController,
                  children: [
                    SizedBox(height: MediaQuery.of(context).size.height * 0.15),
                    Center(child: Text('Nessun prodotto', style: AppTextStyles.subtitle)),
                  ],
                )
                    : GridView.builder(
                  controller: scrollController,
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
                      brand: item.marca,
                      imageUrl: item.imagePath,
                      quantity: item.quantita,
                      onTap: () async {
                        final saved = await Navigator.push<bool>(
                          context,
                          MaterialPageRoute(
                            fullscreenDialog: true,
                            builder: (_) => ProductFormScreen(
                              prefilledNome: item.nome,
                              prefilledMarca: item.marca,
                              prefilledImageUrl: item.imagePath,
                              prefilledQuantita: item.quantita,
                            ),
                          ),
                        );

                        if (!context.mounted) return;

                        if (saved == true) {
                          // L'articolo esce dal carrello solo a prodotto
                          // salvato, poi si chiude lo scanner come dopo una
                          // scansione riuscita.
                          final provider = context.read<ShoppingListProvider>();
                          await provider.deleteItem(item.id);

                          if (!context.mounted) return;
                          Navigator.pop(context);
                        }
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}