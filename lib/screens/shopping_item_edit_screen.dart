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
  late String? _imagePath;

  @override
  void initState() {
    super.initState();
    _nomeController = TextEditingController(text: widget.item.nome);
    _marcaController = TextEditingController(text: widget.item.marca ?? '');
    _imagePath = widget.item.imagePath;
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _marcaController.dispose();
    super.dispose();
  }

  void _save() {
    if (_nomeController.text.trim().isEmpty) return;

    final provider = context.read<ShoppingListProvider>();
    final marcaText = _marcaController.text.trim();

    widget.item.nome = _nomeController.text.trim();
    widget.item.marca = marcaText.isEmpty ? null : marcaText;
    widget.item.imagePath = _imagePath;
    provider.updateItem(widget.item);

    AppSnackbar.show(context, message: 'Prodotto aggiornato');

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: const SizedBox.shrink(),
        actions: [
          IconButton(
            icon: const Icon(Icons.close, color: Colors.black),
            onPressed: () => Navigator.pop(context),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: ProductImagePicker(
                imagePath: _imagePath,
                onImagePicked: (path) => setState(() => _imagePath = path),
              ),
            ),
            const SizedBox(height: 32),
            TextFormField(
              controller: _nomeController,
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 2.0, fontSize: 14),
              decoration: const InputDecoration(
                hintText: 'NOME PRODOTTO',
                contentPadding: EdgeInsets.symmetric(vertical: 18),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.zero,
                  borderSide: BorderSide(color: Colors.black87, width: 1.5),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.zero,
                  borderSide: BorderSide(color: Colors.black87, width: 1.5),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.zero,
                  borderSide: BorderSide(color: Colors.black87, width: 2.0),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _marcaController,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14),
              decoration: const InputDecoration(
                hintText: 'MARCA (ES. BARILLA)',
                contentPadding: EdgeInsets.symmetric(vertical: 14),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.zero,
                  borderSide: BorderSide(color: Colors.black38, width: 1.0),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.zero,
                  borderSide: BorderSide(color: Colors.black38, width: 1.0),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.zero,
                  borderSide: BorderSide(color: Colors.black87, width: 1.5),
                ),
              ),
            ),
            const SizedBox(height: 40),
            InkWell(
              onTap: _save,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 18),
                decoration: BoxDecoration(border: Border.all(color: Colors.black87, width: 2)),
                alignment: Alignment.center,
                child: const Text(
                  'MODIFICA',
                  style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 2.0, fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}