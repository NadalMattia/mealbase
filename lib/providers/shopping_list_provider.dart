import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../models/house.dart';
import '../models/shopping_item.dart';
import '../services/shopping_list_service.dart';
import '../services/image_storage_service.dart';

/// Stato della lista della spesa della casa attualmente selezionata.
///
/// La lista è divisa in due sezioni mostrate sulla stessa schermata:
/// [daAcquistare] e [giaPreso], distinte dal flag `preso` di ogni
/// articolo. [toggleItem] sposta un articolo dall'una all'altra.
///
/// L'eliminazione usa lo stesso flusso in due tempi di `PantryProvider`:
/// [hideItem] nasconde, [confirmDeleteItem] rende definitivo,
/// [cancelDeleteItem] annulla.
class ShoppingListProvider extends ChangeNotifier {
  final ShoppingListService _service = ShoppingListService();

  List<ShoppingItem> _items = [];
  final Set<String> _pendingDeleteIds = {};

  ShoppingListProvider();

  /// Carica la lista della spesa di [house].
  ///
  /// Il box viene aperto per [House.id]; il nome serve solo alla migrazione
  /// di eventuali dati salvati con schemi di naming precedenti.
  Future<void> switchHouse(House house) async {
    await _service.switchHouse(house.id, legacyName: house.nome);
    loadItems();
  }

  /// Rilegge gli articoli da Hive e notifica la UI.
  void loadItems() {
    _items = _service.getAll();
    notifyListeners();
  }

  /// Articoli da mostrare, esclusi quelli in attesa di conferma di
  /// eliminazione.
  List<ShoppingItem> get items =>
      _items.where((item) => !_pendingDeleteIds.contains(item.id)).toList();

  List<ShoppingItem> get daAcquistare =>
      items.where((item) => !item.preso).toList();

  List<ShoppingItem> get giaPreso =>
      items.where((item) => item.preso).toList();

  /// Crea un articolo nella sezione "da acquistare".
  Future<void> addItem(String nome, {String? marca, String? imagePath, int quantita = 1}) async {
    final newItem = ShoppingItem(
      id: const Uuid().v4(),
      nome: nome,
      marca: marca,
      imagePath: imagePath,
      quantita: quantita,
      preso: false,
    );

    await _service.addItem(newItem);
    loadItems();
  }

  /// Nasconde un articolo dalla lista senza eliminarlo, in attesa che
  /// l'utente confermi o annulli.
  void hideItem(String id) {
    _pendingDeleteIds.add(id);
    notifyListeners();
  }

  /// Annulla un'eliminazione in sospeso e rimette l'articolo in lista.
  void cancelDeleteItem(String id) {
    _pendingDeleteIds.remove(id);
    notifyListeners();
  }

  /// Rende definitiva un'eliminazione messa in sospeso da [hideItem],
  /// rimuovendo anche l'eventuale immagine associata.
  Future<void> confirmDeleteItem(String id) async {
    _pendingDeleteIds.remove(id);
    final item = _findById(id);

    await _service.deleteItem(id);
    if (item != null) {
      await ImageStorageService.deleteImage(item.imagePath);
    }
    loadItems();
  }

  /// Persiste le modifiche a un articolo.
  ///
  /// [previousImagePath] è il path dell'immagine prima della modifica: se
  /// è cambiata, il vecchio file viene rimosso dallo storage.
  Future<void> updateItem(ShoppingItem item, {String? previousImagePath}) async {
    await _service.updateItem(item);

    if (previousImagePath != null && previousImagePath != item.imagePath) {
      await ImageStorageService.deleteImage(previousImagePath);
    }
    loadItems();
  }

  /// Sposta un articolo tra "da acquistare" e "nel carrello".
  ///
  /// [item] è lo stesso riferimento già presente in memoria, quindi basta
  /// salvarlo e notificare: non serve rileggere la lista da Hive.
  Future<void> toggleItem(ShoppingItem item) async {
    item.preso = !item.preso;
    await _service.updateItem(item);
    notifyListeners();
  }

  /// Elimina subito un articolo, senza passare dal flusso di conferma.
  ///
  /// Usato dalla selezione multipla e dalla rimozione automatica dal
  /// carrello quando l'articolo diventa un prodotto in dispensa.
  Future<void> deleteItem(String id) async {
    final item = _findById(id);

    await _service.deleteItem(id);
    if (item != null) {
      await ImageStorageService.deleteImage(item.imagePath);
    }
    loadItems();
  }

  /// Elimina in sequenza gli articoli indicati, per la selezione multipla.
  ///
  /// Come in `PantryProvider.deleteProducts`, la sequenzialità evita che
  /// più cancellazioni concorrenti rendano imprevedibile l'ordine di
  /// completamento.
  Future<void> deleteItems(Iterable<String> ids) async {
    for (final id in ids) {
      await deleteItem(id);
    }
  }

  /// Cerca un articolo per id tra quelli in memoria, o `null`.
  ///
  /// Serve a leggere `imagePath` prima che l'articolo venga rimosso da
  /// Hive, per poter cancellare anche il file associato.
  ShoppingItem? _findById(String id) {
    for (final item in _items) {
      if (item.id == id) return item;
    }
    return null;
  }
}
