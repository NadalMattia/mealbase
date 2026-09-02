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
  final TextEditingController _marcaController = TextEditingController();
  // FIX: prima il controller partiva con testo REALE '1' (non un
  // placeholder), identico all'hintText '1' del campo qui sotto. Cancellando
  // la cifra digitata, il campo tornava vuoto ma l'hintText mostrava lo
  // stesso identico "1" al suo posto: sembrava che la cancellazione non
  // avesse avuto alcun effetto. Ora il controller parte vuoto e "1" si vede
  // solo come vero placeholder grigio quando il campo è vuoto; il fallback
  // a 1 se l'utente non scrive nulla resta gestito dal parsing in _save()
  // (`int.tryParse(quantitaText) ?? 1`).
  final TextEditingController _quantitaController = TextEditingController();

  bool _isLookingUp = false;
  String? _imagePath;

  @override
  void dispose() {
    _nomeController.dispose();
    _marcaController.dispose();
    _quantitaController.dispose();
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
        if (result.marca != null && result.marca!.isNotEmpty) {
          _marcaController.text = result.marca!;
        }
        _imagePath ??= result.imageUrl;
        _isLookingUp = false;
      });
    } else {
      AppSnackbar.show(
        context,
        message: result.networkError
            ? 'Connessione assente: controlla la rete e riprova'
            : 'Prodotto non trovato',
        icon: result.networkError ? Icons.wifi_off : Icons.info_outline,
      );
      Future.delayed(const Duration(milliseconds: 2500), () {
        if (mounted) setState(() => _isLookingUp = false);
      });
    }
  }

  void _save() {
    final nome = _nomeController.text.trim();
    if (nome.isEmpty) return;

    final marcaText = _marcaController.text.trim();
    final quantitaText = _quantitaController.text.trim();
    final quantita = int.tryParse(quantitaText) ?? 1;

    context.read<ShoppingListProvider>().addItem(
      nome,
      marca: marcaText.isEmpty ? null : marcaText,
      imagePath: _imagePath,
      quantita: quantita,
    );

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
      initialChildSize: 0.52,
      minChildSize: 0.20,
      maxChildSize: 0.85,
      snap: true,
      snapSizes: const [0.20, 0.52, 0.85],
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
              const SizedBox(height: 20),
              Center(
                child: ProductImagePicker(
                  imagePath: _imagePath,
                  onImagePicked: (path) => setState(() => _imagePath = path),
                  size: 90,
                ),
              ),
              const SizedBox(height: 20),

              // Campo Nome Prodotto
              Row(
                children: [
                  const Text('PRODOTTO', style: AppTextStyles.fieldLabel),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Container(
                      height: 44,
                      decoration: BoxDecoration(color: AppColors.grey50, borderRadius: BorderRadius.circular(AppRadius.xl)),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _nomeController,
                              decoration: const InputDecoration(
                                hintText: 'Nome',
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              ),
                            ),
                          ),
                          if (_isLookingUp)
                            const Padding(
                              padding: EdgeInsets.only(right: 12),
                              child: SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Campo Marca
              Row(
                children: [
                  const Text('MARCA', style: AppTextStyles.fieldLabel),
                  const SizedBox(width: 38),
                  Expanded(
                    child: Container(
                      height: 44,
                      decoration: BoxDecoration(color: AppColors.grey50, borderRadius: BorderRadius.circular(AppRadius.xl)),
                      child: TextField(
                        controller: _marcaController,
                        decoration: const InputDecoration(
                          hintText: 'Marca (opzionale)',
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Campo Quantità
              Row(
                children: [
                  const Text('QUANTITÀ', style: AppTextStyles.fieldLabel),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Container(
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppColors.grey50,
                        borderRadius: BorderRadius.circular(AppRadius.xl),
                      ),
                      child: TextField(
                        controller: _quantitaController,
                        // Vedi commento analogo in product_form_screen.dart:
                        // il parsing qui sotto è `int.tryParse`, quindi la
                        // tastiera non deve invitare a scrivere decimali
                        // che verrebbero comunque scartati in silenzio.
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          hintText: '1',
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Tasto Aggiungi
              InkWell(
                onTap: _save,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 16),
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