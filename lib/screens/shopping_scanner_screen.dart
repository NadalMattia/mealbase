import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';
import 'package:permission_handler/permission_handler.dart';
import '../providers/shopping_list_provider.dart';
import '../services/barcode_service.dart';
import '../theme/app_theme.dart';
import '../utils/app_snackbar.dart';
import '../widgets/product_image_picker.dart';
import '../widgets/scanner_chrome.dart';

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
  bool _isPermissionGranted = false;
  bool _isChecking = true;
  String? _imagePath;

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
      setState(() {
        _nomeController.text = result.nome!;
        _imagePath ??= result.imageUrl;
      });
      setState(() => _isLookingUp = false);
    } else {
      AppSnackbar.show(context, message: 'Prodotto non trovato', icon: Icons.info_outline);
      Future.delayed(const Duration(milliseconds: 2500), () {
        if (mounted) setState(() => _isLookingUp = false);
      });
    }
  }

  void _save() {
    if (_nomeController.text.trim().isEmpty) return;

    context.read<ShoppingListProvider>().addItem(_nomeController.text.trim(), imagePath: _imagePath);
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
            Positioned.fill(child: _buildAddFormBottomSheet(context)),
        ],
      ),
    );
  }

  Widget _buildAddFormBottomSheet(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.45,
      minChildSize: 0.20,
      maxChildSize: 0.85,
      snap: true,
      snapSizes: const [0.20, 0.45, 0.85],
      builder: (context, scrollController) {
        return Container(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
          decoration: const BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.pill)),
          ),
          child: ListView(
            controller: scrollController,
            padding: EdgeInsets.zero,
            children: [
              Center(
                child: Container(
                  width: 40, height: 4,
                  decoration: BoxDecoration(color: AppColors.grey300, borderRadius: BorderRadius.circular(2)),
                ),
              ),
              const SizedBox(height: 24),
              Center(
                child: ProductImagePicker(
                  imagePath: _imagePath,
                  onImagePicked: (path) => setState(() => _imagePath = path),
                  size: 100,
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
                      decoration: BoxDecoration(color: AppColors.grey50, borderRadius: BorderRadius.circular(AppRadius.xl)),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _nomeController,
                              decoration: const InputDecoration(border: InputBorder.none, contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14)),
                            ),
                          ),
                          if (_isLookingUp)
                            const Padding(padding: EdgeInsets.only(right: 12), child: SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))),
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
                  decoration: BoxDecoration(color: AppColors.black, borderRadius: BorderRadius.circular(AppRadius.pill)),
                  alignment: Alignment.center,
                  child: const Text('AGGIUNGI', style: AppTextStyles.pillButtonLabel),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}