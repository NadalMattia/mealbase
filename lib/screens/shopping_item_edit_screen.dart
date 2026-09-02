import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/shopping_item.dart';
import '../providers/shopping_list_provider.dart';
import '../theme/app_theme.dart';
import '../utils/app_snackbar.dart';
import '../widgets/product_image_picker.dart';

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
    super.dispose();
  }

  void _save() {
    if (_nomeController.text.trim().isEmpty) return;

    final provider = context.read<ShoppingListProvider>();
    final marcaText = _marcaController.text.trim();
    final quantitaText = _quantitaController.text.trim();

    final previousImagePath = widget.item.imagePath;

    widget.item.nome = _nomeController.text.trim();
    widget.item.marca = marcaText.isEmpty ? null : marcaText;
    widget.item.quantita = int.tryParse(quantitaText) ?? 1;
    widget.item.imagePath = _imagePath;

    provider.updateItem(widget.item, previousImagePath: previousImagePath);

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
                border: Border.all(color: AppColors.grey300, width: 1),
              ),
              child: TextField(
                controller: _nomeController,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
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