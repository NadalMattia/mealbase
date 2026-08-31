import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';
import '../providers/shopping_list_provider.dart';
import '../services/barcode_service.dart';
import '../theme/app_theme.dart';
import '../utils/app_snackbar.dart';
import '../widgets/product_image_picker.dart';
import '../widgets/scanner_layout.dart';

class ShoppingScannerScreen extends StatefulWidget {
  const ShoppingScannerScreen({super.key});

  @override
  State<ShoppingScannerScreen> createState() => _ShoppingScannerScreenState();
}

class _ShoppingScannerScreenState extends State<ShoppingScannerScreen> {
  final BarcodeService _barcodeService = BarcodeService();
  final TextEditingController _nomeController = TextEditingController();

  bool _isLookingUp = false;
  String? _imagePath;

  @override
  void dispose() {
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
        _isLookingUp = false;
      });
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
    return ScannerLayout(
      resizeToAvoidBottomInset: true,
      onDetect: _onDetect,
      bottomSheetBuilder: (context, controller) => _buildAddFormBottomSheet(context),
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