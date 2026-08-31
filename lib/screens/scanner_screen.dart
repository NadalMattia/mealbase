import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';
import 'package:permission_handler/permission_handler.dart';
import '../providers/shopping_list_provider.dart';
import '../services/barcode_service.dart';
import '../theme/app_theme.dart';
import '../utils/app_snackbar.dart';
import '../widgets/product_card.dart';
import '../widgets/scanner_chrome.dart';
import 'product_form_screen.dart';

class ScannerScreen extends StatefulWidget {
  const ScannerScreen({super.key});

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen> {
  final MobileScannerController _controller = MobileScannerController();
  final BarcodeService _barcodeService = BarcodeService();
  final DraggableScrollableController _sheetController = DraggableScrollableController();

  bool _isProcessing = false;
  bool _isPermissionGranted = false;
  bool _isChecking = true;

  @override
  void initState() {
    super.initState();
    _checkCameraPermission();
  }

  Future<void> _checkCameraPermission() async {
    final status = await Permission.camera.request();
    if (!mounted) return;

    setState(() {
      _isPermissionGranted = status.isGranted;
      _isChecking = false;
    });
  }

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
      AppSnackbar.show(context, message: 'Prodotto non trovato', icon: Icons.info_outline);
      Future.delayed(const Duration(milliseconds: 2500), () {
        if (mounted) setState(() => _isProcessing = false);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scannerBackground,
      body: Stack(
        children: [
          // 0. SFONDO: Fotocamera isolata a schermo intero
          Positioned.fill(
            child: _isChecking
                ? const Center(child: CircularProgressIndicator(color: AppColors.white))
                : _isPermissionGranted
                ? MobileScanner(
              controller: _controller,
              onDetect: _onDetect,
              errorBuilder: (context, error, child) {
                return ScannerPermissionDenied(onClose: () => Navigator.pop(context));
              },
            )
                : ScannerPermissionDenied(onClose: () => Navigator.pop(context)),
          ),

          // 1. OVERLAY E MIRINO
          if (_isPermissionGranted && !_isChecking) ...[
            Positioned.fill(child: Container(color: Colors.black.withOpacity(0.35))),
            const Center(child: ScannerViewfinder()),
            Positioned(
              top: 0, left: 0, right: 0,
              child: ScannerTopControls(
                controller: _controller,
                onCloseTap: () => Navigator.pop(context),
              ),
            ),
          ],

          // 2. PANNELLO INFERIORE
          if (!_isChecking)
            Positioned.fill(child: _buildCartBottomSheet(context)),
        ],
      ),
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
                        width: 40, height: 4,
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
                    crossAxisCount: 3, crossAxisSpacing: 16, mainAxisSpacing: 16, childAspectRatio: 0.8,
                  ),
                  itemCount: cartItems.length,
                  itemBuilder: (context, index) {
                    final item = cartItems[index];
                    return ProductCard(
                      name: item.nome,
                      imageUrl: item.imagePath,
                      onTap: () => Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          fullscreenDialog: true,
                          builder: (_) => ProductFormScreen(prefilledNome: item.nome, prefilledImageUrl: item.imagePath),
                        ),
                      ),
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