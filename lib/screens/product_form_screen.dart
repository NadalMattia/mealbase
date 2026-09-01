import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../models/product.dart';
import '../models/product_category.dart';
import '../providers/pantry_provider.dart';
import '../providers/shopping_list_provider.dart';
import '../providers/location_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/product_image_picker.dart';

class ProductFormScreen extends StatefulWidget {
  final Product? existingProduct;
  final String? prefilledNome;
  final String? prefilledMarca;
  final String? prefilledCategoria;
  final String? prefilledImageUrl;

  const ProductFormScreen({
    super.key,
    this.existingProduct,
    this.prefilledNome,
    this.prefilledMarca,
    this.prefilledCategoria,
    this.prefilledImageUrl,
  });

  @override
  State<ProductFormScreen> createState() => _ProductFormScreenState();
}

class _ProductFormScreenState extends State<ProductFormScreen> {
  late TextEditingController _nomeController;
  late TextEditingController _marcaController;
  late TextEditingController _quantitaController;

  String? _imagePath;
  String _categoria = ProductCategories.defaultLabel;
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
      _marcaController = TextEditingController(text: p.marca ?? '');
      _quantitaController = TextEditingController(
        text: p.quantita % 1 == 0 ? p.quantita.toInt().toString() : p.quantita.toString(),
      );
      _imagePath = p.imagePath;
      _categoria = p.categoria.isNotEmpty ? p.categoria : ProductCategories.defaultLabel;
      _posizione = p.posizione.isNotEmpty ? p.posizione : 'Dispensa';
      _unita = p.unita.isNotEmpty ? p.unita : 'pz';
      _dataAcquisto = p.dataAcquisto;
      _dataScadenza = p.dataScadenza;
    } else {
      _nomeController = TextEditingController(text: widget.prefilledNome ?? '');
      _marcaController = TextEditingController(text: widget.prefilledMarca ?? '');
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
    _marcaController.dispose();
    _quantitaController.dispose();
    super.dispose();
  }

  List<Product> _getCombinedSuggestions(
      List<Product> pantryProducts,
      List<dynamic> shoppingItems,
      String query,
      ) {
    final cleanQuery = query.trim().toLowerCase();
    if (cleanQuery.isEmpty) return [];

    final Map<String, Product> uniqueMatches = {};

    for (var p in pantryProducts) {
      final nome = p.nome.toLowerCase();
      final marca = p.marca?.toLowerCase() ?? '';
      if (nome.contains(cleanQuery) || marca.contains(cleanQuery)) {
        final key = '${nome}_$marca';
        uniqueMatches[key] = p;
      }
    }

    for (var item in shoppingItems) {
      if (item == null) continue;

      String nomeStr = '';
      String? marcaStr;
      String? img;

      try { nomeStr = (item.nome ?? '').toString(); } catch (_) {}
      try { marcaStr = item.marca?.toString(); } catch (_) {}
      try { img = item.imagePath?.toString(); } catch (_) {}

      if (nomeStr.trim().isEmpty) continue;

      final nomeClean = nomeStr.toLowerCase();
      final marcaClean = (marcaStr ?? '').toLowerCase();

      if (nomeClean.contains(cleanQuery) || marcaClean.contains(cleanQuery)) {
        final key = '${nomeClean}_$marcaClean';
        if (!uniqueMatches.containsKey(key)) {
          uniqueMatches[key] = Product(
            // Id generato con uuid solo per identità interna: questo
            // oggetto è "sintetico" (serve solo a popolare il suggerimento
            // in UI) e non viene mai salvato così com'è in Hive.
            id: const Uuid().v4(),
            nome: nomeStr,
            marca: marcaStr,
            quantita: 1.0,
            unita: 'pz',
            categoria: ProductCategories.defaultLabel,
            posizione: 'Dispensa',
            dataAcquisto: DateTime.now(),
            imagePath: img,
          );
        }
      }
    }

    return uniqueMatches.values.toList();
  }

  void _onSuggestionTap(Product suggestion) {
    setState(() {
      _nomeController.text = suggestion.nome;
      _marcaController.text = suggestion.marca ?? '';
      _imagePath = suggestion.imagePath;
      if (suggestion.categoria.isNotEmpty) _categoria = suggestion.categoria;
      if (suggestion.posizione.isNotEmpty) _posizione = suggestion.posizione;
      if (suggestion.unita.isNotEmpty) _unita = suggestion.unita;
    });
    FocusScope.of(context).unfocus();
  }

  Future<void> _pickScadenza() async {
    final now = DateTime.now();
    final tomorrow = DateTime(now.year, now.month, now.day + 1);

    final initialDate = (_dataScadenza != null && _dataScadenza!.isAfter(now))
        ? _dataScadenza!
        : tomorrow;

    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: tomorrow,
      lastDate: now.add(const Duration(days: 365 * 5)),
    );

    if (picked != null) {
      setState(() => _dataScadenza = picked);
    }
  }

  void _saveProduct() {
    final nomeInserito = _nomeController.text.trim();
    if (nomeInserito.isEmpty) return;

    final marcaInserita = _marcaController.text.trim();
    final pantryProvider = context.read<PantryProvider>();
    final quantitaNum = double.tryParse(_quantitaController.text.trim().replaceAll(',', '.')) ?? 1.0;

    if (widget.existingProduct != null) {
      final p = widget.existingProduct!;

      // Catturiamo il path dell'immagine PRIMA di sovrascrivere i campi:
      // `p` è lo stesso riferimento Hive che stiamo per mutare in-place,
      // quindi è l'unico momento in cui possiamo ancora leggere il valore
      // precedente. Lo passiamo al provider così può ripulire il vecchio
      // file locale se l'immagine è stata sostituita.
      final previousImagePath = p.imagePath;

      p.nome = nomeInserito;
      p.marca = marcaInserita.isEmpty ? null : marcaInserita;
      p.quantita = quantitaNum;
      p.unita = _unita;
      p.categoria = _categoria;
      p.posizione = _posizione;
      p.dataAcquisto = _dataAcquisto;
      p.dataScadenza = _dataScadenza;
      p.imagePath = _imagePath;

      pantryProvider.updateProduct(p, previousImagePath: previousImagePath);
    } else {
      final newProduct = Product(
        // Uuid invece di millisecondsSinceEpoch: uniforme con Location,
        // House e ShoppingItem, elimina il rischio di collisioni di id.
        id: const Uuid().v4(),
        nome: nomeInserito,
        marca: marcaInserita.isEmpty ? null : marcaInserita,
        quantita: quantitaNum,
        unita: _unita,
        categoria: _categoria,
        posizione: _posizione,
        dataAcquisto: _dataAcquisto,
        dataScadenza: _dataScadenza,
        imagePath: _imagePath,
      );
      pantryProvider.addProduct(newProduct);

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

  @override
  Widget build(BuildContext context) {
    final locationProvider = context.watch<LocationProvider>();
    final pantryProducts = context.watch<PantryProvider>().products;

    List<dynamic> shoppingItems = [];
    try {
      final shoppingProvider = context.watch<ShoppingListProvider>();
      shoppingItems = shoppingProvider.giaPreso;
    } catch (_) {}

    final isEditing = widget.existingProduct != null;
    final suggestions = isEditing
        ? <Product>[]
        : _getCombinedSuggestions(pantryProducts, shoppingItems, _nomeController.text);

    final locations = locationProvider.locations.map((l) => l.nome).toList();
    if (!locations.contains('Dispensa')) locations.add('Dispensa');
    if (!locations.contains(_posizione)) locations.add(_posizione);

    return Scaffold(
      backgroundColor: AppColors.pannaWarm,
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
            Center(
              child: ProductImagePicker(
                imagePath: _imagePath,
                onImagePicked: (path) => setState(() => _imagePath = path),
                size: 140,
              ),
            ),
            const SizedBox(height: 24),

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

            const SizedBox(height: 12),

            Container(
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.grey300, width: 1),
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: TextField(
                controller: _marcaController,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 14),
                decoration: const InputDecoration(
                  hintText: 'Marca (es. Barilla)',
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                ),
              ),
            ),

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
                    final hasMarca = item.marca != null && item.marca!.trim().isNotEmpty;
                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                      leading: _buildThumbnail(item.imagePath),
                      title: Text(item.nome, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      subtitle: hasMarca
                          ? Text(
                        item.marca!.toUpperCase(),
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.grey500),
                      )
                          : null,
                      onTap: () => _onSuggestionTap(item),
                    );
                  }).toList(),
                ),
              ),

            const SizedBox(height: 24),

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
                      // Lista generata da ProductCategory (vedi
                      // models/product_category.dart): prima era una lista
                      // di stringhe hardcoded, duplicata identicamente in
                      // pantry_filter_bottom_sheet.dart, con il rischio che
                      // le due liste si disallineassero nel tempo.
                      items: ProductCategories.labels.map((c) {
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

            InkWell(
              onTap: _saveProduct,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  color: AppColors.verdeSalvia,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                alignment: Alignment.center,
                child: Text(
                  isEditing ? 'SALVA MODIFICHE' : 'INSERISCI',
                  style: const TextStyle(color: AppColors.white, fontWeight: FontWeight.bold, fontSize: 16, letterSpacing: 1),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildThumbnail(String? path) {
    if (path == null || path.trim().isEmpty) {
      return Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(color: AppColors.grey200, borderRadius: BorderRadius.circular(AppRadius.md)),
        child: const Icon(Icons.image, color: AppColors.grey400, size: 22),
      );
    }

    final isNetwork = path.startsWith('http://') || path.startsWith('https://');
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: isNetwork
          ? Image.network(
        path,
        width: 42,
        height: 42,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Container(
          width: 42,
          height: 42,
          color: AppColors.grey200,
          child: const Icon(Icons.broken_image, color: AppColors.grey400, size: 20),
        ),
      )
          : Image.file(
        File(path),
        width: 42,
        height: 42,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Container(
          width: 42,
          height: 42,
          color: AppColors.grey200,
          child: const Icon(Icons.broken_image, color: AppColors.grey400, size: 20),
        ),
      ),
    );
  }
}