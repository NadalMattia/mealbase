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
import '../widgets/product_image_picker.dart';
import '../widgets/smart_image.dart';

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

  String? _imagePath;
  String _categoria = ProductCategories.defaultLabel;
  String _posizione = 'Dispensa';
  String _unita = 'pz';
  late DateTime _dataAcquisto;
  DateTime? _dataScadenza;

  // FIX: quando un suggerimento nasce da un articolo del carrello
  // (ShoppingItem), qui teniamo traccia di QUALE articolo esatto è
  // (il suo `id`), così al salvataggio possiamo rimuoverlo dal carrello
  // in modo affidabile. Prima la rimozione avveniva cercando di nuovo
  // nel carrello un articolo con lo stesso *nome* del prodotto salvato:
  // se in carrello c'erano due articoli con lo stesso nome ma marca
  // diversa, poteva cancellare quello sbagliato, lasciando l'altro
  // "a ricomparire" come suggerimento la volta successiva.
  //
  // `_cartSuggestionOrigin` mappa l'id (sintetico, generato in
  // `_getCombinedSuggestions`) di ogni suggerimento-da-carrello all'id
  // reale dell'articolo di origine in `ShoppingListProvider`. Viene
  // ripopolata ad ogni build (i suggerimenti sono comunque rigenerati
  // ad ogni build in base al testo digitato), quindi resta sempre
  // coerente con quello che l'utente vede a schermo in quel momento.
  final Map<String, String> _cartSuggestionOrigin = {};

  // Id dell'articolo del carrello da cui proviene il suggerimento
  // attualmente selezionato (null se non è stato selezionato nessun
  // suggerimento, o se il suggerimento selezionato veniva dalla
  // dispensa invece che dal carrello).
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
      // Converte la quantità del prodotto esistente in intero per il controller
      _quantitaController = TextEditingController(
        text: p.quantita.toInt().toString(),
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
    super.dispose();
  }

  /// Suggerimenti di autocomplete presi dagli articoli ancora presenti nel
  /// carrello della lista della spesa.
  ///
  /// PRIMA: [shoppingItems] era tipizzato `List<dynamic>` e ogni accesso
  /// ai campi (`item.nome`, `item.marca`, `item.imagePath`) era avvolto
  /// in un try/catch silenzioso "per sicurezza". In realtà l'oggetto è
  /// sempre un `ShoppingItem` (viene da `ShoppingListProvider.giaPreso`,
  /// che ritorna `List<ShoppingItem>`): usare `dynamic` non aggiungeva
  /// flessibilità reale, toglieva solo il controllo del compilatore e
  /// nascondeva silenziosamente eventuali bug veri.
  ///
  /// FIX: prima i suggerimenti includevano anche i prodotti già presenti
  /// in dispensa (`pantryProducts`), con priorità sulla dispensa quando
  /// lo stesso nome+marca esisteva in entrambi. Risultato: un prodotto
  /// appena inserito in dispensa (e correttamente rimosso dal carrello)
  /// continuava a "ricomparire" come suggerimento — non più come articolo
  /// del carrello, ma come voce già esistente in dispensa, con la sua
  /// quantità attuale precompilata. Per l'utente sembrava lo stesso
  /// identico problema di prima, solo con una causa diversa.
  /// Ora i suggerimenti vengono SOLO dal carrello: un prodotto smette di
  /// essere suggerito nel momento stesso in cui non c'è (più) nulla che
  /// lo riguarda nel carrello, indipendentemente dal fatto che esista già
  /// in dispensa.
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
          final suggestionId = const Uuid().v4();
          uniqueMatches[key] = Product(
            // Id generato con uuid solo per identità interna: questo
            // oggetto è "sintetico" (serve solo a popolare il suggerimento
            // in UI) e non viene mai salvato così com'è in Hive.
            id: suggestionId,
            nome: nomeStr,
            marca: marcaStr,
            // FIX: prima qui c'era `quantita: 1` fisso, che ignorava la
            // quantità reale impostata sull'articolo della lista spesa
            // (`item.quantita`). Siccome il campo quantità del form parte
            // già da "1" di default, il risultato era indistinguibile da
            // "non si compila": selezionando un suggerimento dal
            // carrello, la quantità restava sempre "1" anche se
            // l'articolo ne aveva un'altra.
            quantita: item.quantita,
            unita: 'pz',
            categoria: ProductCategories.defaultLabel,
            posizione: 'Dispensa',
            dataAcquisto: DateTime.now(),
            imagePath: img,
          );
          // Ricorda da quale articolo del carrello (id reale, non
          // rigenerato) proviene questo suggerimento: vedi commento su
          // `_cartSuggestionOrigin` più sopra.
          _cartSuggestionOrigin[suggestionId] = item.id;
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
      _quantitaController.text = suggestion.quantita.toInt().toString();
      // Se questo suggerimento veniva dal carrello, ricordiamo l'id
      // esatto dell'articolo di origine per poterlo rimuovere in modo
      // affidabile al salvataggio (vedi _saveProduct). Se invece veniva
      // dalla dispensa, `_cartSuggestionOrigin` non contiene la sua
      // chiave e questo resta `null`: non c'è nessun articolo del
      // carrello da rimuovere in quel caso.
      _sourceCartItemId = _cartSuggestionOrigin[suggestion.id];
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

  Future<void> _saveProduct() async {
    final nomeInserito = _nomeController.text.trim();
    if (nomeInserito.isEmpty) return;

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

      // FIX: prima questa chiamata non veniva aspettata (`await`), quindi
      // `Navigator.pop` più sotto poteva eseguire PRIMA che il
      // salvataggio su Hive (e l'eventuale programmazione della notifica
      // di scadenza) fosse davvero completato. Risultato: tornando sulla
      // dispensa, il prodotto poteva non comparire subito, perché
      // `notifyListeners()` scattava con un istante di ritardo rispetto
      // alla chiusura dello schermo.
      await pantryProvider.updateProduct(p, previousImagePath: previousImagePath);
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
      // FIX: vedi commento analogo nel ramo di update qui sopra — senza
      // `await`, il prodotto poteva non comparire subito in dispensa
      // dopo il salvataggio.
      await pantryProvider.addProduct(newProduct);

      // Rimuoviamo dal carrello l'articolo che ha dato origine a questo
      // prodotto, così non ricompare più come suggerimento la volta
      // successiva che si digita lo stesso nome.
      final shoppingProvider = context.read<ShoppingListProvider>();

      if (_sourceCartItemId != null) {
        // Via primaria e affidabile: sappiamo esattamente da quale
        // articolo del carrello proveniva il suggerimento selezionato
        // (id reale, non un confronto di stringhe). Corregge il bug per
        // cui, con due articoli dello stesso nome ma marca diversa in
        // carrello, poteva venire cancellato quello sbagliato lasciando
        // l'altro a "ricomparire" come suggerimento.
        await shoppingProvider.deleteItem(_sourceCartItemId!);
      } else {
        // Fallback: l'utente ha digitato il nome a mano (senza
        // selezionare un suggerimento) e questo combacia comunque con
        // qualcosa già presente in carrello. Confronto per nome, unica
        // informazione disponibile in questo caso.
        final cartItems = shoppingProvider.giaPreso;
        for (final item in cartItems) {
          if (item.nome.trim().toLowerCase() == nomeInserito.toLowerCase()) {
            await shoppingProvider.deleteItem(item.id);
            break;
          }
        }
      }
    }

    // Controllo di sicurezza dopo gli `await` qui sopra: se per qualche
    // motivo lo schermo fosse già stato smontato nel frattempo (es.
    // l'utente ha navigato via in altro modo), `context` non sarebbe più
    // valido da usare.
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

    // ShoppingListProvider è sempre disponibile: è registrato nel
    // MultiProvider di main.dart insieme a tutti gli altri provider
    // dell'app, quindi non serve avvolgere questa lettura in un
    // try/catch difensivo (che in precedenza nascondeva silenziosamente
    // anche eventuali errori reali).
    final shoppingItems = context.watch<ShoppingListProvider>().giaPreso;

    final isEditing = widget.existingProduct != null;
    final suggestions = isEditing
        ? <Product>[]
        : _getCombinedSuggestions(shoppingItems, _nomeController.text);

    final locations = locationProvider.locations.map((l) => l.nome).toList();
    if (!locations.contains('Dispensa')) locations.add('Dispensa');
    if (!locations.contains(_posizione)) locations.add(_posizione);

    // FIX: le categorie disponibili sono state riorganizzate (es.
    // 'Carne/Pesce' è diventata 'Carne' + 'Pesce' separate). Un prodotto
    // salvato PRIMA di quella riorganizzazione può avere `categoria`
    // valorizzata con un'etichetta che oggi non esiste più tra
    // `ProductCategories.labels`. `DropdownButton` richiede che `value`
    // corrisponda esattamente a uno degli `items`, altrimenti lancia
    // un'eccezione di assert appena si apre lo screen: crashava
    // l'editing di qualsiasi prodotto con una categoria "vecchio stile".
    // Stesso pattern già usato sopra per `locations`: se il valore
    // corrente non è tra quelli noti, lo aggiungiamo comunque alla lista
    // (l'utente lo vedrà come opzione, potendo scegliere consapevolmente
    // una categoria aggiornata, invece di un crash o di una sostituzione
    // silenziosa).
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
                onChanged: (_) => setState(() {
                  // L'utente sta digitando/modificando a mano: qualsiasi
                  // collegamento con un articolo del carrello selezionato
                  // in precedenza non è più valido.
                  _sourceCartItemId = null;
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
                        // FIX: `quantita` sul modello è `int`, e più sotto
                        // viene fatto `int.tryParse(...)`. Prima qui la
                        // tastiera era `numberWithOptions(decimal: true)`:
                        // mostrava il tasto virgola/punto invitando a
                        // scrivere quantità come "0,5" (per unità come
                        // g/kg/ml/l), ma quel valore veniva scartato in
                        // silenzio dal parsing intero e sostituito con 1,
                        // senza nessun avviso per l'utente. Usare una
                        // tastiera solo numerica intera rende impossibile
                        // scrivere qualcosa che poi verrebbe comunque
                        // ignorato.
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
                      // Lista generata da ProductCategory (vedi
                      // models/product_category.dart) più, se presente,
                      // il valore "orfano" del prodotto corrente (vedi
                      // commento sopra su `categorie`).
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

  /// Thumbnail per un suggerimento di autocomplete.
  ///
  /// Prima duplicava (con dimensioni fisse 42x42) la stessa logica
  /// locale/remoto già vista in `ProductImagePicker`, `ProductCard` e
  /// `house_list_screen.dart` — la quarta copia della stessa cosa. Ora usa
  /// `SmartImage` come tutte le altre.
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