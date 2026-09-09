import 'package:flutter/foundation.dart';
import '../models/house.dart';
import '../models/product.dart';
import '../services/hive_service.dart';
import '../services/notification_service.dart';
import '../services/image_storage_service.dart';

/// Stato della dispensa della casa attualmente selezionata.
///
/// Espone i prodotti alla UI e coordina i tre servizi coinvolti in ogni
/// modifica: persistenza su Hive, promemoria di scadenza e file immagine.
///
/// L'eliminazione segue un flusso in due tempi. [hideProduct] toglie subito
/// il prodotto dalla lista visibile senza scrivere su disco, dando alla UI
/// il tempo di offrire un annullamento; solo [confirmDeleteProduct] rende
/// l'operazione definitiva, mentre [cancelDeleteProduct] la annulla. Così
/// una cancellazione annullata non tocca mai Hive.
class PantryProvider extends ChangeNotifier {
  final HiveService _hiveService = HiveService();
  List<Product> _products = [];

  /// Prodotti eliminati dalla UI ma non ancora confermati.
  final Set<String> _pendingDeleteIds = {};

  PantryProvider();

  /// Prodotti da mostrare, esclusi quelli in attesa di conferma di
  /// eliminazione.
  List<Product> get products =>
      _products.where((p) => !_pendingDeleteIds.contains(p.id)).toList();

  /// Carica la dispensa di [house] e riallinea i promemoria di scadenza.
  ///
  /// Il box viene aperto per [House.id]; il nome serve solo alla migrazione
  /// di eventuali dati salvati con schemi di naming precedenti.
  Future<void> switchHouse(House house) async {
    await _hiveService.switchHouse(house.id, legacyName: house.nome);
    loadProducts();
    await _syncNotifications();
  }

  /// Riprogramma da zero i promemoria per i prodotti della casa corrente.
  ///
  /// I prodotti privi di data di scadenza sono esclusi: non c'è nulla da
  /// notificare.
  Future<void> _syncNotifications() async {
    await NotificationService().resyncAll(
      _products
          .where((p) => p.dataScadenza != null)
          .map((p) => (id: p.id, nome: p.nome, scadenza: p.dataScadenza!)),
    );
  }

  /// Rilegge i prodotti da Hive e notifica la UI.
  void loadProducts() {
    _products = _hiveService.getAllProducts();
    notifyListeners();
  }

  /// Prodotti di un singolo spazio, per le tab della dispensa.
  /// Il valore speciale `Tutto` restituisce l'intera dispensa.
  List<Product> byPosizione(String posizione) {
    final activeProducts = products;
    if (posizione == 'Tutto') return activeProducts;
    return activeProducts.where((p) => p.posizione == posizione).toList();
  }

  /// Prodotti il cui nome contiene [query], deduplicati per nome.
  ///
  /// A parità di nome viene tenuto quello con un'immagine, per lo stesso
  /// motivo descritto in [findByName].
  List<Product> searchProducts(String query) {
    if (query.trim().isEmpty) return [];

    final Map<String, Product> uniqueMatches = {};
    for (var p in products) {
      if (p.nome.toLowerCase().contains(query.toLowerCase())) {
        if (!uniqueMatches.containsKey(p.nome) || (p.imagePath != null && p.imagePath!.isNotEmpty)) {
          uniqueMatches[p.nome] = p;
        }
      }
    }
    return uniqueMatches.values.toList();
  }

  /// Cerca un prodotto per nome tra quelli visibili.
  ///
  /// A parità di nome ha la precedenza quello con un'immagine: è ciò che
  /// rende riconoscibile un suggerimento di autocompletamento.
  Product? findByName(String name) {
    final target = name.trim().toLowerCase();
    Product? matchWithoutImage;

    for (final p in products) {
      if (p.nome.toLowerCase() != target) continue;
      final hasImage = p.imagePath != null && p.imagePath!.isNotEmpty;
      if (hasImage) return p;
      matchWithoutImage ??= p;
    }
    return matchWithoutImage;
  }

  /// Salva un nuovo prodotto e ne programma il promemoria di scadenza.
  Future<void> addProduct(Product product) async {
    await _hiveService.addProduct(product);
    if (product.dataScadenza != null) {
      await NotificationService().scheduleExpirationNotification(
        id: product.id,
        productName: product.nome,
        expirationDate: product.dataScadenza!,
      );
    }
    loadProducts();
  }

  /// Persiste le modifiche a un prodotto, allineando promemoria e immagine.
  ///
  /// Il promemoria viene riprogrammato se il prodotto ha una scadenza,
  /// altrimenti annullato.
  ///
  /// [previousImagePath] è il path dell'immagine prima della modifica. Va
  /// letto dal chiamante prima di sovrascrivere i campi, dato che
  /// [product] è lo stesso riferimento mutato in-place: se l'immagine è
  /// cambiata, il vecchio file viene rimosso dallo storage.
  Future<void> updateProduct(Product product, {String? previousImagePath}) async {
    if (product.isInBox) {
      await product.save();
    } else {
      await _hiveService.addProduct(product);
    }

    if (previousImagePath != null && previousImagePath != product.imagePath) {
      await ImageStorageService.deleteImage(previousImagePath);
    }

    if (product.dataScadenza != null) {
      await NotificationService().scheduleExpirationNotification(
        id: product.id,
        productName: product.nome,
        expirationDate: product.dataScadenza!,
      );
    } else {
      await NotificationService().cancelNotification(product.id);
    }
    loadProducts();
  }

  /// Nasconde un prodotto dalla lista senza eliminarlo, in attesa che
  /// l'utente confermi o annulli.
  void hideProduct(String id) {
    _pendingDeleteIds.add(id);
    notifyListeners();
  }

  /// Sposta nello spazio [to] tutti i prodotti che si trovano in [from].
  ///
  /// Va invocato prima di eliminare uno spazio: [Product.posizione]
  /// referenzia lo spazio per nome, quindi i prodotti rimasti orfani
  /// sparirebbero da ogni tab tranne "Tutto" pur restando salvati.
  Future<void> reassignPosizione(String from, String to) async {
    final affected = _products.where((p) => p.posizione == from).toList();
    for (final product in affected) {
      product.posizione = to;
      if (product.isInBox) {
        await product.save();
      }
    }
    if (affected.isNotEmpty) loadProducts();
  }

  /// Annulla un'eliminazione in sospeso e rimette il prodotto in lista.
  void cancelDeleteProduct(String id) {
    _pendingDeleteIds.remove(id);
    notifyListeners();
  }

  /// Rende definitiva un'eliminazione messa in sospeso da [hideProduct],
  /// rimuovendo anche promemoria e immagine associati.
  Future<void> confirmDeleteProduct(String id) async {
    _pendingDeleteIds.remove(id);
    final product = _findById(id);

    await NotificationService().cancelNotification(id);
    await _hiveService.deleteProduct(id);
    if (product != null) {
      await ImageStorageService.deleteImage(product.imagePath);
    }
    loadProducts();
  }

  /// Elimina subito un prodotto, senza passare dal flusso di conferma.
  ///
  /// Usato dalla selezione multipla, dove la conferma è già avvenuta
  /// sull'intero gruppo. Rimuove anche promemoria e immagine.
  Future<void> deleteProduct(String id) async {
    final product = _findById(id);

    await NotificationService().cancelNotification(id);
    await _hiveService.deleteProduct(id);
    if (product != null) {
      await ImageStorageService.deleteImage(product.imagePath);
    }
    loadProducts();
  }

  /// Elimina in sequenza i prodotti indicati, per la selezione multipla.
  ///
  /// Ogni cancellazione comporta annullamento della notifica, scrittura su
  /// Hive, rimozione dell'immagine e ricarica della lista: eseguirle in
  /// parallelo renderebbe imprevedibile l'ordine di completamento e
  /// lascerebbe eventuali errori senza gestione.
  Future<void> deleteProducts(Iterable<String> ids) async {
    for (final id in ids) {
      await deleteProduct(id);
    }
  }

  /// Cerca un prodotto per id tra quelli in memoria, o `null`.
  ///
  /// Serve a leggere `imagePath` prima che il prodotto venga rimosso da
  /// Hive, per poter cancellare anche il file associato.
  Product? _findById(String id) {
    for (final p in _products) {
      if (p.id == id) return p;
    }
    return null;
  }
}