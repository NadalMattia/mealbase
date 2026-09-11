import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';
import '../providers/shopping_list_provider.dart';
import '../services/barcode_service.dart';
import '../theme/app_theme.dart';
import '../utils/app_snackbar.dart';
import '../widgets/product_image_picker.dart';
import '../widgets/scanner_layout.dart';

/// Scansione di un codice a barre per aggiungere un articolo alla lista
/// della spesa, con form di conferma nel foglio inferiore.
class ShoppingScannerScreen extends StatefulWidget {
  const ShoppingScannerScreen({super.key});

  @override
  State<ShoppingScannerScreen> createState() => _ShoppingScannerScreenState();
}

class _ShoppingScannerScreenState extends State<ShoppingScannerScreen> {
  final BarcodeService _barcodeService = BarcodeService();
  final TextEditingController _nomeController = TextEditingController();
  final TextEditingController _marcaController = TextEditingController();
  /// Parte vuoto di proposito: "1" compare come placeholder grigio e il
  /// valore predefinito è applicato dal parsing in [_save].
  final TextEditingController _quantitaController = TextEditingController();
  final FocusNode _nomeFocusNode = FocusNode();

  /// Ultimo codice a barre elaborato.
  ///
  /// La fotocamera invoca il callback a ogni frame: confrontare il codice
  /// evita di ripetere la stessa ricerca finché resta inquadrato, senza
  /// impedire la scansione di un prodotto diverso.
  String? _lastScannedCode;

  bool _isLookingUp = false;
  String? _imagePath;

  /// Segnala che si è tentato un salvataggio con il nome vuoto.
  bool _nomeError = false;

  @override
  void dispose() {
    _nomeController.dispose();
    _marcaController.dispose();
    _quantitaController.dispose();
    _nomeFocusNode.dispose();
    super.dispose();
  }

  /// Cerca su Open Food Facts il codice inquadrato e precompila il form.
  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_isLookingUp) return;

    final code = capture.barcodes.isNotEmpty ? capture.barcodes.first.rawValue : null;
    if (code == null || code.isEmpty) return;
    if (code == _lastScannedCode) return;

    _lastScannedCode = code;
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
        _nomeError = false;
      });
    } else {
      // Azzerando il codice si può ritentare subito lo stesso prodotto,
      // per esempio dopo aver ripristinato la connessione.
      _lastScannedCode = null;
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

  /// Aggiunge l'articolo alla lista della spesa e chiude la schermata.
  Future<void> _save() async {
    final nome = _nomeController.text.trim();
    if (nome.isEmpty) {
      setState(() => _nomeError = true);
      _nomeFocusNode.requestFocus();
      AppSnackbar.show(
        context,
        message: 'Inserisci il nome del prodotto',
        icon: Icons.error_outline,
      );
      return;
    }

    final marcaText = _marcaController.text.trim();
    final quantitaText = _quantitaController.text.trim();
    final quantita = int.tryParse(quantitaText) ?? 1;

    await context.read<ShoppingListProvider>().addItem(
      nome,
      marca: marcaText.isEmpty ? null : marcaText,
      imagePath: _imagePath,
      quantita: quantita,
    );

    if (!mounted) return;
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
                      decoration: BoxDecoration(
                        color: AppColors.grey50,
                        borderRadius: BorderRadius.circular(AppRadius.xl),
                        border: _nomeError ? Border.all(color: Colors.red, width: 1.5) : null,
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _nomeController,
                              focusNode: _nomeFocusNode,
                              onChanged: (_) {
                                if (_nomeError) setState(() => _nomeError = false);
                              },
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
                        keyboardType: TextInputType.number,
                        // Solo cifre e al massimo quattro: la tastiera
                        // numerica su alcune varianti Android espone
                        // comunque segno e separatore, e il parsing li
                        // scarterebbe in silenzio riportando la quantità
                        // a 1 senza spiegazioni.
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(4),
                        ],
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