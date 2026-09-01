import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/product.dart';
import '../providers/pantry_provider.dart';
import '../providers/shopping_list_provider.dart';
import '../providers/location_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/product_image_picker.dart';

class ProductFormScreen extends StatefulWidget {
  final Product? existingProduct;
  final String? prefilledNome;
  final String? prefilledCategoria;
  final String? prefilledImageUrl;

  const ProductFormScreen({
    super.key,
    this.existingProduct,
    this.prefilledNome,
    this.prefilledCategoria,
    this.prefilledImageUrl,
  });

  @override
  State<ProductFormScreen> createState() => _ProductFormScreenState();
}

class _ProductFormScreenState extends State<ProductFormScreen> {
  late TextEditingController _nomeController;
  late TextEditingController _quantitaController;

  String? _imagePath;
  String _categoria = 'Altro';
  String _posizione = 'Dispensa';
  String _unita = 'pz';
  late DateTime _dataAcquisto;
  DateTime? _dataScadenza;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<PantryProvider>().loadProducts();
      }
    });

    if (widget.existingProduct != null) {
      final p = widget.existingProduct!;
      _nomeController = TextEditingController(text: p.nome);
      _quantitaController = TextEditingController(
        text: p.quantita % 1 == 0 ? p.quantita.toInt().toString() : p.quantita.toString(),
      );
      _imagePath = p.imagePath;
      _categoria = p.categoria.isNotEmpty ? p.categoria : 'Altro';
      _posizione = p.posizione.isNotEmpty ? p.posizione : 'Dispensa';
      _unita = p.unita.isNotEmpty ? p.unita : 'pz';
      _dataAcquisto = p.dataAcquisto;
      _dataScadenza = p.dataScadenza;
    } else {
      _nomeController = TextEditingController(text: widget.prefilledNome ?? '');
      _quantitaController = TextEditingController(text: '1');
      _imagePath = widget.prefilledImageUrl;
      _dataAcquisto = DateTime.now();
      if (widget.prefilledCategoria != null && widget.prefilledCategoria!.isNotEmpty) {
        _categoria = widget.prefilledCategoria!;
      }
    }
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _quantitaController.dispose();
    super.dispose();
  }

  /// Cerca prodotti in TUTTE le fonti dell'app (Dispensa + Spesa/Carrello)
  List<Product> _getCombinedSuggestions(BuildContext context, String query) {
    final cleanQuery = query.trim().toLowerCase();
    if (cleanQuery.isEmpty) return [];

    final pantryProducts = context.watch<PantryProvider>().products;

    List<dynamic> shoppingItems = [];
    try {
      final shoppingProvider = context.watch<ShoppingListProvider>();
      shoppingItems = [...shoppingProvider.giaPreso];
    } catch (_) {}

    final Map<String, Product> uniqueMatches = {};

    // 1. Cerca nella Dispensa
    for (var p in pantryProducts) {
      if (p.nome.toLowerCase().contains(cleanQuery)) {
        uniqueMatches[p.nome.toLowerCase()] = p;
      }
    }

    // 2. Cerca nella Spesa/Carrello
    for (var item in shoppingItems) {
      final String nomeStr = item.nome ?? '';
      if (nomeStr.toLowerCase().contains(cleanQuery)) {
        final key = nomeStr.toLowerCase();
        final String? img = item.imagePath;

        if (!uniqueMatches.containsKey(key)) {
          uniqueMatches[key] = Product(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            nome: nomeStr,
            quantita: 1.0,
            unita: 'pz',
            categoria: 'Altro',
            posizione: 'Dispensa',
            dataAcquisto: DateTime.now(),
            imagePath: img,
          );
        } else if ((uniqueMatches[key]!.imagePath == null || uniqueMatches[key]!.imagePath!.isEmpty) && img != null) {
          uniqueMatches[key]!.imagePath = img;
        }
      }
    }

    return uniqueMatches.values.toList();
  }

  void _onSuggestionTap(Product suggestion) {
    setState(() {
      _nomeController.text = suggestion.nome;
      _imagePath = suggestion.imagePath; // Copia la foto dal carrello/dispensa
      if (suggestion.categoria.isNotEmpty) {
        _categoria = suggestion.categoria;
      }
      if (suggestion.posizione.isNotEmpty) {
        _posizione = suggestion.posizione;
      }
      if (suggestion.unita.isNotEmpty) {
        _unita = suggestion.unita;
      }
    });
    FocusScope.of(context).unfocus();
  }

  void _saveProduct() {
    final nomeInserito = _nomeController.text.trim();
    if (nomeInserito.isEmpty) return;

    final pantryProvider = context.read<PantryProvider>();
    final quantitaNum = double.tryParse(_quantitaController.text.trim().replaceAll(',', '.')) ?? 1.0;

    if (widget.existingProduct != null) {
      final updated = Product(
        id: widget.existingProduct!.id,
        nome: nomeInserito,
        quantita: quantitaNum,
        unita: _unita,
        categoria: _categoria,
        posizione: _posizione,
        dataAcquisto: _dataAcquisto,
        dataScadenza: _dataScadenza,
        imagePath: _imagePath,
      );
      pantryProvider.updateProduct(updated);
    } else {
      final newProduct = Product(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        nome: nomeInserito,
        quantita: quantitaNum,
        unita: _unita,
        categoria: _categoria,
        posizione: _posizione,
        dataAcquisto: _dataAcquisto,
        dataScadenza: _dataScadenza,
        imagePath: _imagePath,
      );
      pantryProvider.addProduct(newProduct);

      // FIX: Rimuove automaticamente il prodotto dal carrello della spesa se presente
      try {
        final shoppingProvider = context.read<ShoppingListProvider>();
        final cartItems = shoppingProvider.giaPreso;
        for (var item in cartItems) {
          if (item.nome.toString().trim().toLowerCase() == nomeInserito.toLowerCase()) {
            shoppingProvider.deleteItem(item.id);
            break;
          }
        }
      } catch (_) {}
    }

    Navigator.pop(context, true);
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '- / - / -';
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  Future<void> _pickScadenza() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _dataScadenza ?? now,
      firstDate: now.subtract(const Duration(days: 365)),
      lastDate: now.add(const Duration(days: 365 * 5)),
    );
    if (picked != null) {
      setState(() => _dataScadenza = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final locationProvider = context.watch<LocationProvider>();
    final isEditing = widget.existingProduct != null;
    final suggestions = isEditing ? <Product>[] : _getCombinedSuggestions(context, _nomeController.text);

    final locations = locationProvider.locations.map((l) => l.nome).toList();
    if (!locations.contains('Dispensa')) locations.add('Dispensa');
    if (!locations.contains(_posizione)) locations.add(_posizione);

    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: const CloseButton(color: AppColors.black),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Picker Foto
            Center(
              child: ProductImagePicker(
                imagePath: _imagePath,
                onImagePicked: (path) => setState(() => _imagePath = path),
                size: 140,
              ),
            ),
            const SizedBox(height: 24),

            // Input Nome Prodotto
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.black, width: 1.5),
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: TextField(
                controller: _nomeController,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                decoration: const InputDecoration(
                  hintText: 'Nome prodotto',
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                ),
                onChanged: (_) => setState(() {}),
              ),
            ),

            // Autocompletamento Suggerimenti
            if (!isEditing && _nomeController.text.trim().isNotEmpty && suggestions.isNotEmpty)
              Container(
                margin: const EdgeInsets.only(top: 8),
                decoration: BoxDecoration(
                  color: AppColors.grey50,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  border: Border.all(color: AppColors.grey300),
                ),
                child: Column(
                  children: suggestions.map((item) {
                    return ListTile(
                      leading: _buildThumbnail(item.imagePath),
                      title: Text(item.nome, style: const TextStyle(fontWeight: FontWeight.bold)),
                      onTap: () => _onSuggestionTap(item),
                    );
                  }).toList(),
                ),
              ),

            const SizedBox(height: 24),

            // Scadenza
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('SCADENZA', style: AppTextStyles.fieldLabel),
                InkWell(
                  onTap: _pickScadenza,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.black, width: 1),
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                    child: Text(
                      _formatDate(_dataScadenza),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Quantità e Unità
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('QUANTITÀ', style: AppTextStyles.fieldLabel),
                Row(
                  children: [
                    Container(
                      width: 60,
                      decoration: BoxDecoration(
                        border: Border.all(color: AppColors.black, width: 1),
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
                      child: TextField(
                        controller: _quantitaController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(vertical: 8),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        border: Border.all(color: AppColors.black, width: 1),
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _unita,
                          items: ['pz', 'g', 'kg', 'ml', 'l'].map((u) {
                            return DropdownMenuItem(value: u, child: Text(u));
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) setState(() => _unita = val);
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Categoria
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('CATEGORIA', style: AppTextStyles.fieldLabel),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.black, width: 1),
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _categoria,
                      items: ['Altro', 'Frutta/Verdura', 'Latticini', 'Carne/Pesce', 'Dispensa', 'Bevande', 'Surgelati'].map((c) {
                        return DropdownMenuItem(value: c, child: Text(c));
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => _categoria = val);
                      },
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Posizione / Alloca In
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('ALLOCA IN', style: AppTextStyles.fieldLabel),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.black, width: 1),
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _posizione,
                      items: locations.map((loc) {
                        return DropdownMenuItem(value: loc, child: Text(loc));
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => _posizione = val);
                      },
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),

            // Bottone Inserisci / Salva Modifiche
            InkWell(
              onTap: _saveProduct,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.black, width: 1.5),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                alignment: Alignment.center,
                child: Text(
                  isEditing ? 'SALVA MODIFICHE' : 'INSERISCI',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, letterSpacing: 1),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildThumbnail(String? path) {
    if (path == null || path.isEmpty) {
      return Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(color: AppColors.grey200, borderRadius: BorderRadius.circular(AppRadius.md)),
        child: Icon(Icons.image, color: AppColors.grey400, size: 20),
      );
    }

    final isNetwork = path.startsWith('http://') || path.startsWith('https://');
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: isNetwork
          ? Image.network(path, width: 40, height: 40, fit: BoxFit.cover)
          : Image.file(File(path), width: 40, height: 40, fit: BoxFit.cover),
    );
  }
}