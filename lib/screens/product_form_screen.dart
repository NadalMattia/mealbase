import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../models/product.dart';
import '../models/shopping_item.dart';
import '../providers/pantry_provider.dart';
import '../providers/location_provider.dart';
import '../providers/shopping_list_provider.dart';
import '../theme/app_theme.dart';
import '../utils/app_snackbar.dart';
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
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nomeController;
  late TextEditingController _quantitaController;
  String _unita = 'pz';
  String _categoria = 'Altro';
  String _posizione = 'Dispensa';
  DateTime? _dataScadenza;
  String? _imageUrl;

  // Rinominato da `_unita_options` (snake_case non idiomatico in Dart) a
  // `_unitaOptions` (lowerCamelCase, coerente con il resto del codice).
  final List<String> _unitaOptions = ['pz', 'g', 'kg', 'l'];
  final List<String> _categorie = ['Latticini', 'Verdura', 'Carne', 'Altro'];

  bool get _isEditing => widget.existingProduct != null;

  // Lista locale per i suggerimenti pescati dal carrello
  List<ShoppingItem> _suggestions = [];

  @override
  void initState() {
    super.initState();
    final p = widget.existingProduct;

    _nomeController = TextEditingController(
      text: p?.nome ?? widget.prefilledNome ?? '',
    );
    _quantitaController =
        TextEditingController(text: p?.quantita.toInt().toString() ?? '1');

    if (p != null) {
      _unita = p.unita;
      _categoria = p.categoria;
      _posizione = p.posizione;
      _dataScadenza = p.dataScadenza;
      _imageUrl = p.imagePath;
    } else if (widget.prefilledCategoria != null &&
        _categorie.contains(widget.prefilledCategoria)) {
      _categoria = widget.prefilledCategoria!;
    }

    _imageUrl ??= widget.prefilledImageUrl;

    _nomeController.addListener(_onNameChanged);
  }

  void _onNameChanged() {
    final query = _nomeController.text.trim().toLowerCase();
    if (query.isEmpty || _isEditing) {
      setState(() => _suggestions = []);
      return;
    }

    // Pescati direttamente dal carrello (elementi inCarrello == true)
    final shoppingProvider = context.read<ShoppingListProvider>();
    final cartItems = shoppingProvider.giaPreso;

    // Filtra gli elementi del carrello in base alle lettere digitate
    final matches = cartItems
        .where((item) => item.nome.toLowerCase().contains(query))
        .toList();

    setState(() {
      _suggestions = matches;
    });
  }

  @override
  void dispose() {
    _nomeController.removeListener(_onNameChanged);
    _nomeController.dispose();
    _quantitaController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dataScadenza ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 3)),
    );
    if (picked != null) {
      setState(() => _dataScadenza = picked);
    }
  }

  /// Restituisce la posizione da usare per il salvataggio: quella scelta
  /// dall'utente se ancora valida, altrimenti la prima disponibile.
  ///
  /// Prima questa correzione avveniva con un `setState` chiamato dentro
  /// `addPostFrameCallback` invocato *durante il build* del `Consumer`
  /// sottostante: un pattern fragile (side-effect nascosto nel ciclo di
  /// build, un frame di ritardo prima che l'interfaccia si aggiornasse).
  /// Ora il fallback è calcolato in modo puro sia nel form sia al momento
  /// del salvataggio, senza alcun effetto collaterale durante il build.
  String? _effettivaPosizione(List<String> posizioniDisponibili) {
    if (posizioniDisponibili.contains(_posizione)) return _posizione;
    return posizioniDisponibili.isNotEmpty ? posizioniDisponibili.first : null;
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;

    final pantryProvider = context.read<PantryProvider>();
    final shoppingProvider = context.read<ShoppingListProvider>();
    final locationProvider = context.read<LocationProvider>();

    final posizioniDisponibili = locationProvider.locations.map((l) => l.nome).toList();
    final posizioneDaSalvare = _effettivaPosizione(posizioniDisponibili) ?? _posizione;

    final insertedName = _nomeController.text.trim();

    if (_isEditing) {
      final p = widget.existingProduct!;
      p.nome = insertedName;
      p.quantita = double.parse(_quantitaController.text);
      p.unita = _unita;
      p.categoria = _categoria;
      p.posizione = posizioneDaSalvare;
      p.dataScadenza = _dataScadenza;
      p.imagePath = _imageUrl;
      pantryProvider.updateProduct(p);
    } else {
      // 1. Aggiunge il prodotto alla dispensa
      final newProduct = Product(
        id: const Uuid().v4(),
        nome: insertedName,
        quantita: double.parse(_quantitaController.text),
        unita: _unita,
        categoria: _categoria,
        posizione: posizioneDaSalvare,
        dataAcquisto: DateTime.now(),
        dataScadenza: _dataScadenza,
        imagePath: _imageUrl,
      );
      pantryProvider.addProduct(newProduct);

      // 2. Rimuove automaticamente il prodotto dal carrello se era presente
      final matchingCartItems = shoppingProvider.giaPreso
          .where((item) => item.nome.toLowerCase() == insertedName.toLowerCase())
          .toList();

      for (final cartItem in matchingCartItems) {
        shoppingProvider.deleteItem(cartItem.id);
      }
    }

    AppSnackbar.show(
      context,
      message: _isEditing ? 'Prodotto modificato' : 'Prodotto inserito in dispensa',
    );

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        leading: const SizedBox.shrink(),
        actions: [
          IconButton(
            icon: const Icon(Icons.close, color: AppColors.black),
            onPressed: () => Navigator.pop(context),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Immagine Prodotto e Fotocamera
              Center(
                child: ProductImagePicker(
                  imagePath: _imageUrl,
                  onImagePicked: (path) => setState(() => _imageUrl = path),
                ),
              ),
              const SizedBox(height: 40),

              // Sezione Nome Prodotto con menu a cascata dai prodotti del carrello
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextFormField(
                    controller: _nomeController,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2.0,
                      fontSize: 14,
                    ),
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
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Obbligatorio' : null,
                  ),

                  // Menu a cascata con i prodotti pescati dal carrello (Nome a sx, Immagine a dx)
                  if (_suggestions.isNotEmpty)
                    Container(
                      margin: const EdgeInsets.only(top: 4),
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        border: Border.all(color: Colors.black87, width: 1),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _suggestions.length,
                        itemBuilder: (context, index) {
                          final item = _suggestions[index];
                          return InkWell(
                            onTap: () {
                              setState(() {
                                _nomeController.text = item.nome;
                                _suggestions = []; // Chiude il menu a cascata
                              });
                            },
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  // Nome a sinistra
                                  Text(item.nome, style: AppTextStyles.cardTitle.copyWith(fontSize: 14)),
                                  // Immagine/Icona a destra
                                  Container(
                                    width: 32,
                                    height: 32,
                                    decoration: BoxDecoration(
                                      color: AppColors.grey100,
                                      borderRadius: BorderRadius.circular(AppRadius.sm),
                                    ),
                                    child: Icon(Icons.image, size: 16, color: AppColors.grey500),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 40),

              // Scadenza
              _buildFormRow(
                'SCADENZA',
                InkWell(
                  onTap: _pickDate,
                  child: Container(
                    height: 48,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.black87, width: 1),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      _formatDate(_dataScadenza),
                      style: const TextStyle(fontWeight: FontWeight.w500, letterSpacing: 1.5),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Quantità e Unità
              _buildFormRow(
                'QUANTITÀ',
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: TextFormField(
                        controller: _quantitaController,
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.center,
                        decoration: const InputDecoration(
                          contentPadding: EdgeInsets.symmetric(vertical: 14),
                          border: OutlineInputBorder(borderRadius: BorderRadius.zero),
                        ),
                        validator: (v) => (v == null || double.tryParse(v) == null) ? '!' : null,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 3,
                      child: DropdownButtonFormField<String>(
                        value: _unita,
                        icon: const Icon(Icons.keyboard_arrow_down, size: 18),
                        decoration: const InputDecoration(
                          contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                          border: OutlineInputBorder(borderRadius: BorderRadius.zero),
                        ),
                        items: _unitaOptions
                            .map((u) => DropdownMenuItem(value: u, child: Text(u)))
                            .toList(),
                        onChanged: (v) => setState(() => _unita = v!),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Categoria
              _buildFormRow(
                'CATEGORIA',
                DropdownButtonFormField<String>(
                  value: _categoria,
                  icon: const Icon(Icons.keyboard_arrow_down, size: 18),
                  decoration: const InputDecoration(
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    border: OutlineInputBorder(borderRadius: BorderRadius.zero),
                  ),
                  items: _categorie
                      .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                      .toList(),
                  onChanged: (v) => setState(() => _categoria = v!),
                ),
              ),
              const SizedBox(height: 24),

              // Alloca in (Posizione)
              Consumer<LocationProvider>(
                builder: (context, locationProvider, _) {
                  final posizioniDisponibili =
                      locationProvider.locations.map((l) => l.nome).toList();

                  // Calcolo puro, senza setState né side-effect durante il
                  // build: se `_posizione` non è più valida (es. la
                  // location è stata eliminata), il dropdown mostra
                  // semplicemente la prima disponibile finché l'utente non
                  // ne sceglie un'altra o salva il form.
                  final effettiva = _effettivaPosizione(posizioniDisponibili);

                  return _buildFormRow(
                    'ALLOCA IN',
                    DropdownButtonFormField<String>(
                      value: effettiva,
                      icon: const Icon(Icons.keyboard_arrow_down, size: 18),
                      decoration: const InputDecoration(
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        border: OutlineInputBorder(borderRadius: BorderRadius.zero),
                      ),
                      items: posizioniDisponibili
                          .map((p) => DropdownMenuItem(value: p, child: Text(p)))
                          .toList(),
                      onChanged: (v) {
                        if (v != null) setState(() => _posizione = v);
                      },
                    ),
                  );
                },
              ),
              const SizedBox(height: 48),

              // Tasto finale Modifica/Inserisci
              InkWell(
                onTap: _save,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.black87, width: 2),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    _isEditing ? 'MODIFICA' : 'INSERISCI',
                    style: AppTextStyles.primaryActionLabel,
                  ),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFormRow(String label, Widget inputWidget) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(label, style: AppTextStyles.fieldLabel),
        SizedBox(width: 160, child: inputWidget),
      ],
    );
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '- / - / -';
    return '${date.day.toString().padLeft(2, '0')} / ${date.month.toString().padLeft(2, '0')} / ${date.year.toString().substring(2)}';
  }
}
