import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../services/barcode_service.dart';
import 'product_form_screen.dart';
import '../models/product.dart';

class ScannerScreen extends StatefulWidget {
  const ScannerScreen({super.key});

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen> {
  final BarcodeService _barcodeService = BarcodeService();
  bool _isProcessing = false;

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_isProcessing) return;

    final barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;

    final String? code = barcodes.first.rawValue;
    if (code == null) return;

    setState(() => _isProcessing = true);

    final result = await _barcodeService.lookup(code);

    if (!mounted) return;

    if (result.found) {
      _goToForm(nome: result.nome, categoria: result.categoria);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Prodotto non trovato: completa manualmente'),
        ),
      );
      _goToForm(nome: null, categoria: null);
    }
  }

  void _goToForm({String? nome, String? categoria}) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => ProductFormScreen(
          prefilledNome: nome,
          prefilledCategoria: categoria,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Scansiona codice a barre')),
      body: Stack(
        children: [
          MobileScanner(onDetect: _onDetect),
          if (_isProcessing)
            const Center(child: CircularProgressIndicator()),
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: ElevatedButton.icon(
                icon: const Icon(Icons.edit),
                label: const Text('Inserisci manualmente'),
                onPressed: () => _goToForm(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}