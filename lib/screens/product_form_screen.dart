import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../models/product.dart';
import '../models/product_category.dart';
import '../models/shopping_item.dart';
import '../providers/pantry_provider.dart';
import '../providers/shopping_list_provider.dart';
import '../providers/location_provider.dart';
import '../theme/app_theme.dart';
import '../utils/app_snackbar.dart';
import '../widgets/product_image_picker.dart';
import '../widgets/smart_image.dart';

/// Form di inserimento e modifica di un prodotto.
///
/// Serve tre casi: creazione manuale, creazione precompilata da scanner o
/// carrello, e modifica di un prodotto esistente, distinta dalla presenza
/// di [existingProduct].
class ProductFormScreen extends StatefulWidget {
  final Product? existingProduct;
  final String? prefilledNome;
  final String? prefilledMarca;
  final String? prefilledCategoria;
  final String? prefilledImageUrl;
  final int? prefilledQuantita;

  const ProductFormScreen({
    super.key,
    this.existingProduct,
    this.prefilledNome,
    this.prefilledMarca,
    this.prefilledCategoria,
    this.prefilledImageUrl,
    this.prefilledQuantita,
  });

  @override
  State<ProductFormScreen> createState() => _ProductFormScreenState();
}

class _ProductFormScreenState extends State<ProductFormScreen> {
  late TextEditingController _nomeController;
  late TextEditingController _marcaController;
  late TextEditingController _quantitaController;
  final FocusNode _nomeFocusNode = FocusNode();

  String? _imagePath;
  String _categoria = ProductCategories.defaultLabel;
  String _posizione = 'Dispensa';
  String _unita = 'pz';
  late DateTime _dataAcquisto;
  DateTime? _dataScadenza;

  /// Segnala che si è tentato un salvataggio con il nome vuoto: colora di
  /// rosso il bordo del campo finché l'utente non ricomincia a digitare.
  bool _nomeError = false;

  /// Id dell'articolo del carrello da cui proviene il suggerimento
  /// selezionato, usato per rimuoverlo dalla lista della spesa quando il
  /// prodotto viene salvato in dispensa.
  ///
  /// Vale `null` se l'utente ha digitato il nome a mano: in quel caso
  /// [_saveProduct] ripiega su un confronto per nome.
  String? _sourceCartItemId;

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
      _quantitaController = TextEditingController(text: p.quantita.toString());
      _imagePath = p.imagePath;
      _categoria = p.categoria.isNotEmpty ? p.categoria : ProductCategories.defaultLabel;
      _posizione = p.posizione.isNotEmpty ? p.posizione : 'Dispensa';
      _unita = p.unita.isNotEmpty ? p.unita : 'pz';
      _dataAcquisto = p.dataAcquisto;
      _dataScadenza = p.dataScadenza;
    } else {
      _nomeController = TextEditingController(text: widget.prefilledNome ?? '');
      _marcaController = TextEditingController(text: widget.prefilledMarca ?? '');

      // Usa la quantità precompilata (se arriva dallo scanner/carrello), altrimenti imposta '1' di default
      _quantitaController = TextEditingController(
        text: (widget.prefilledQuantita ?? 1).toString(),
      );

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
    _nomeFocusNode.dispose();
    super.dispose();
  }

  /// Suggerimenti di autocompletamento ricavati dagli articoli del
  /// carrello che combaciano con [query], deduplicati per nome e marca.
  ///
  /// Restituisce oggetti [Product] sintetici, costruiti solo per popolare
  /// la tendina: non vengono mai salvati in questa forma. Il metodo è puro
  /// e privo di effetti collaterali, quindi è sicuro invocarlo da
  /// `build()`.
  List<Product> _getCombinedSuggestions(
      List<ShoppingItem> shoppingItems,
      String query,
      ) {
    final cleanQuery = query.trim().toLowerCase();
    if (cleanQuery.isEmpty) return [];

    final Map<String, Product> uniqueMatches = {};

    for (final item in shoppingItems) {
      final nomeStr = item.nome;
      final marcaStr = item.marca;
      final img = item.imagePath;

      if (nomeStr.trim().isEmpty) continue;

      final nomeClean = nomeStr.toLowerCase();
      final marcaClean = (marcaStr ?? '').toLowerCase();

      if (nomeClean.contains(cleanQuery) || marcaClean.contains(cleanQuery)) {
        final key = '${nomeClean}_$marcaClean';
        if (!uniqueMatches.containsKey(key)) {
          uniqueMatches[key] = Product(
            // L'id è quello reale dell'articolo di origine: resta stabile
            // tra un rebuild e l'altro e permette a [_onSuggestionTap] di
            // risalire all'articolo da rimuovere dal carrello.
            id: item.id,
            nome: nomeStr,
            marca: marcaStr,
            quantita: item.quantita,
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

  /// Compila il form con i dati del suggerimento scelto e memorizza
  /// l'articolo del carrello da cui proviene.
  void _onSuggestionTap(Product suggestion) {
    setState(() {
      _nomeController.text = suggestion.nome;
      _marcaController.text = suggestion.marca ?? '';
      _imagePath = suggestion.imagePath;
      _quantitaController.text = suggestion.quantita.toString();
      _sourceCartItemId = suggestion.id;
      if (suggestion.categoria.isNotEmpty) _categoria = suggestion.categoria;
      if (suggestion.posizione.isNotEmpty) _posizione = suggestion.posizione;
      if (suggestion.unita.isNotEmpty) _unita = suggestion.unita;
    });
    FocusScope.of(context).unfocus();
  }

  /// Apre il selettore della data di scadenza.
  ///
  /// Il minimo selezionabile è oggi, per poter registrare un prodotto
  /// acquistato in scadenza giornaliera. La data proposta è domani, salvo
  /// che il prodotto ne abbia già una non passata.
  Future<void> _pickScadenza() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));

    final initialDate = (_dataScadenza != null && !_dataScadenza!.isBefore(today))
        ? _dataScadenza!
        : tomorrow;

    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: today,
      lastDate: now.add(const Duration(days: 365 * 5)),
    );

    if (picked != null) {
      setState(() => _dataScadenza = picked);
    }
  }

  /// Salva il prodotto e chiude la schermata.
  ///
  /// In creazione, rimuove anche dalla lista della spesa l'articolo che ha
  /// dato origine al prodotto, così da non riproporlo come suggerimento.
  Future<void> _saveProduct() async {
    final nomeInserito = _nomeController.text.trim();
    if (nomeInserito.isEmpty) {
      setState(() => _nomeError = true);
      _nomeFocusNode.requestFocus();
      AppSnackbar.show(
        context,
        message: 'Inserisci il nome del prodotto',
        icon: Icons.error_outline,
      );
      return;
    }
    if (_nomeError) setState(() => _nomeError = false);

    final marcaInserita = _marcaController.text.trim();
    final pantryProvider = context.read<PantryProvider>();
    final quantitaNum = int.tryParse(_quantitaController.text.trim()) ?? 1;

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

      await pantryProvider.updateProduct(p, previousImagePath: previousImagePath);
    } else {
      final newProduct = Product(
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
      await pantryProvider.addProduct(newProduct);

      // Il context va riconvalidato dopo l'await: lo schermo potrebbe
      // essere stato smontato mentre il salvataggio era in corso.
      if (!mounted) return;

      final shoppingProvider = context.read<ShoppingListProvider>();

      if (_sourceCartItemId != null) {
        // L'utente ha scelto un suggerimento: si conosce l'articolo esatto
        // da rimuovere, senza ambiguità tra omonimi di marca diversa.
        await shoppingProvider.deleteItem(_sourceCartItemId!);
      } else {
        // Nome digitato a mano: il confronto per nome è l'unica
        // corrispondenza possibile.
        final cartItems = shoppingProvider.giaPreso;
        for (final item in cartItems) {
          if (item.nome.trim().toLowerCase() == nomeInserito.toLowerCase()) {
            await shoppingProvider.deleteItem(item.id);
            break;
          }
        }
      }
    }

    if (!mounted) return;
    Navigator.pop(context, true);
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '- / - / -';
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final locationProvider = context.watch<LocationProvider>();

    final shoppingItems = context.watch<ShoppingListProvider>().giaPreso;

    final isEditing = widget.existingProduct != null;
    final suggestions = isEditing
        ? <Product>[]
        : _getCombinedSuggestions(shoppingItems, _nomeController.text);

    final locations = locationProvider.locations.map((l) => l.nome).toList();
    if (!locations.contains('Dispensa')) locations.add('Dispensa');
    if (!locations.contains(_posizione)) locations.add(_posizione);

    // DropdownButton richiede che `value` sia presente tra gli `items`,
    // altrimenti solleva un assert all'apertura. Un prodotto salvato con
    // una categoria poi rinominata o rimossa avrebbe un valore orfano:
    // viene aggiunto alla lista così resta selezionabile e l'utente può
    // sostituirlo, invece di far fallire la schermata.
    final categorie = List<String>.from(ProductCategories.labels);
    if (!categorie.contains(_categoria)) categorie.add(_categoria);

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
                border: Border.all(
                  color: _nomeError ? Colors.red : AppColors.black,
                  width: 1.5,
                ),
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: TextField(
                controller: _nomeController,
                focusNode: _nomeFocusNode,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                decoration: const InputDecoration(
                  hintText: 'Nome prodotto',
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                ),
                onChanged: (_) => setState(() {
                  // Digitando a mano si perde il legame con l'articolo del
                  // carrello eventualmente scelto prima.
                  _sourceCartItemId = null;
                  _nomeError = false;
                }),
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
                        // La quantità è un intero e viene letta con
                        // int.tryParse: una tastiera decimale inviterebbe a
                        // digitare valori che verrebbero scartati.
                        keyboardType: TextInputType.number,
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
                      items: categorie.map((c) {
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

  /// Miniatura di un suggerimento di autocompletamento.
  Widget _buildThumbnail(String? path) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: SizedBox(
        width: 42,
        height: 42,
        child: SmartImage(
          path: path,
          fit: BoxFit.cover,
          placeholderBuilder: (_) => Container(
            color: AppColors.grey200,
            child: const Icon(Icons.image, color: AppColors.grey400, size: 22),
          ),
          errorBuilder: (_) => Container(
            color: AppColors.grey200,
            child: const Icon(Icons.broken_image, color: AppColors.grey400, size: 20),
          ),
        ),
      ),
    );
  }
}