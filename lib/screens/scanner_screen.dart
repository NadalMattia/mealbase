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

class ScannerScreen extends StatefulWidget {
  const ScannerScreen({super.key});

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen> {
  final BarcodeService _barcodeService = BarcodeService();
  final DraggableScrollableController _sheetController = DraggableScrollableController();
  bool _isProcessing = false;

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_isProcessing) return;

    final code = capture.barcodes.isNotEmpty ? capture.barcodes.first.rawValue : null;
    if (code == null || code.isEmpty) return;

    setState(() => _isProcessing = true);

    final result = await _barcodeService.lookup(code);
    if (!mounted) return;

    if (result.found) {
      // Rimosso 'final saved =' non utilizzato
      await Navigator.push<bool>(
        context,
        MaterialPageRoute(
          fullscreenDialog: true,
          builder: (_) => ProductFormScreen(
            prefilledNome: result.nome,
            prefilledMarca: result.marca,
            prefilledCategoria: result.categoria,
            prefilledImageUrl: result.imageUrl,
          ),
        ),
      );

      if (mounted) {
        setState(() => _isProcessing = false);
      }
    } else {
      // Messaggio diverso a seconda che il barcode non sia stato trovato
      // nel database Open Food Facts (result.networkError == false) o che
      // la ricerca sia fallita per un problema di connessione
      // (result.networkError == true): prima i due casi mostravano lo
      // stesso messaggio "Prodotto non trovato", fuorviante quando in
      // realtà il problema era la rete.
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
                    // `item` è tipizzato `ShoppingItem` (viene da
                    // `provider.giaPreso`): prima si passava per una
                    // funzione `_getItemMarca(dynamic item)` con
                    // try/catch "difensivo" che non serviva a nulla, dato
                    // che il tipo è già garantito dal compilatore.
                    final itemMarca = item.marca;

                    return ProductCard(
                      name: item.nome,
                      brand: itemMarca,
                      imageUrl: item.imagePath,
                      onTap: () async {
                        final saved = await Navigator.push<bool>(
                          context,
                          MaterialPageRoute(
                            fullscreenDialog: true,
                            builder: (_) => ProductFormScreen(
                              prefilledNome: item.nome,
                              prefilledMarca: itemMarca,
                              prefilledImageUrl: item.imagePath,
                            ),
                          ),
                        );

                        if (saved == true && context.mounted) {
                          context.read<ShoppingListProvider>().deleteItem(item.id);
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