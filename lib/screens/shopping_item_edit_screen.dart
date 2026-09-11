import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/shopping_item.dart';
import '../providers/shopping_list_provider.dart';
import '../theme/app_theme.dart';
import '../utils/app_snackbar.dart';
import '../widgets/product_image_picker.dart';

/// Modifica di un articolo della lista della spesa: nome, marca, quantità
/// e immagine.
class ShoppingItemEditScreen extends StatefulWidget {
  final ShoppingItem item;

  const ShoppingItemEditScreen({super.key, required this.item});

  @override
  State<ShoppingItemEditScreen> createState() => _ShoppingItemEditScreenState();
}

class _ShoppingItemEditScreenState extends State<ShoppingItemEditScreen> {
  late TextEditingController _nomeController;
  late TextEditingController _marcaController;
  late TextEditingController _quantitaController;
  late String? _imagePath;
  final FocusNode _nomeFocusNode = FocusNode();

  /// Segnala che si è tentato un salvataggio con il nome vuoto.
  bool _nomeError = false;

  @override
  void initState() {
    super.initState();
    _nomeController = TextEditingController(text: widget.item.nome);
    _marcaController = TextEditingController(text: widget.item.marca ?? '');
    _quantitaController = TextEditingController(text: widget.item.quantita.toString());
    _imagePath = widget.item.imagePath;
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _marcaController.dispose();
    _quantitaController.dispose();
    _nomeFocusNode.dispose();
    super.dispose();
  }

  /// Persiste le modifiche e chiude la schermata.
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

    final provider = context.read<ShoppingListProvider>();
    final marcaText = _marcaController.text.trim();
    final quantitaText = _quantitaController.text.trim();

    // Va letto prima di sovrascrivere i campi: l'articolo è mutato
    // in-place e il provider ha bisogno del path precedente per
    // cancellare l'eventuale immagine sostituita.
    final previousImagePath = widget.item.imagePath;

    widget.item.nome = nome;
    widget.item.marca = marcaText.isEmpty ? null : marcaText;
    widget.item.quantita = int.tryParse(quantitaText) ?? 1;
    widget.item.imagePath = _imagePath;

    await provider.updateItem(widget.item, previousImagePath: previousImagePath);

    if (!mounted) return;
    AppSnackbar.show(context, message: 'Prodotto aggiornato');
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.pannaWarm, // Sfondo coerente con l'app
      appBar: AppBar(
        backgroundColor: AppColors.pannaWarm,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: const CloseButton(color: AppColors.black),
        centerTitle: true,
        title: const Text('MODIFICA ARTICOLO', style: AppTextStyles.fieldLabel),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: ProductImagePicker(
                imagePath: _imagePath,
                onImagePicked: (path) => setState(() => _imagePath = path),
                size: 130,
              ),
            ),
            const SizedBox(height: 32),

            // Campo Nome Prodotto
            const Text('PRODOTTO', style: AppTextStyles.fieldLabel),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(AppRadius.lg),
                border: Border.all(
                  color: _nomeError ? Colors.red : AppColors.grey300,
                  width: _nomeError ? 1.5 : 1,
                ),
              ),
              child: TextField(
                controller: _nomeController,
                focusNode: _nomeFocusNode,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                onChanged: (_) {
                  if (_nomeError) setState(() => _nomeError = false);
                },
                decoration: const InputDecoration(
                  hintText: 'Nome prodotto',
                  hintStyle: AppTextStyles.hint,
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Campo Marca
            const Text('MARCA', style: AppTextStyles.fieldLabel),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(AppRadius.lg),
                border: Border.all(color: AppColors.grey300, width: 1),
              ),
              child: TextField(
                controller: _marcaController,
                style: const TextStyle(fontSize: 15),
                decoration: const InputDecoration(
                  hintText: 'Marca (opzionale)',
                  hintStyle: AppTextStyles.hint,
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Campo Quantità
            const Text('QUANTITÀ', style: AppTextStyles.fieldLabel),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(AppRadius.lg),
                border: Border.all(color: AppColors.grey300, width: 1),
              ),
              child: TextField(
                controller: _quantitaController,
                keyboardType: TextInputType.number,
                // Vedi product_form_screen: solo cifre, massimo quattro.
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(4),
                ],
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                decoration: const InputDecoration(
                  hintText: '1',
                  hintStyle: AppTextStyles.hint,
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
              ),
            ),
            const SizedBox(height: 36),

            // Tasto Salva / Modifica
            InkWell(
              onTap: _save,
              borderRadius: BorderRadius.circular(AppRadius.pill),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  color: AppColors.black,
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
                alignment: Alignment.center,
                child: const Text(
                  'SALVA MODIFICHE',
                  style: AppTextStyles.pillButtonLabel,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}