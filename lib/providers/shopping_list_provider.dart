import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../models/shopping_item.dart';
import '../services/shopping_list_service.dart';
import '../services/image_storage_service.dart';

/// Provider per la lista della spesa.
///
/// PRIMA: questo provider non usava `ShoppingListService` (che pure esiste
/// nel progetto): apriva e gestiva da solo un `Box<ShoppingItem>` di Hive,
/// con una convenzione di naming del box diversa da quella usata da
/// `HouseScopedHiveService` (la base comune già condivisa da `HiveService`
/// e `LocationService`). Questo creava due problemi:
///   1. Duplicazione della stessa logica CRUD "per casa" già scritta altrove.
///   2. Un servizio (`ShoppingListService`) presente nel codice ma "morto":
///      chiunque in futuro l'avesse usato per errore avrebbe letto un box
///      vuoto, perché i dati reali stavano nel box aperto qui.
///
/// ORA: il provider delega tutto a `ShoppingListService`, esattamente come
/// fanno `PantryProvider` (-> `HiveService`) e `LocationProvider` (->
/// `LocationService`). La migrazione dei dati già salvati dagli utenti nel
/// vecchio box è gestita in `ShoppingListService._migrateFromLegacyBoxIfNeeded()`,
/// quindi non deve essere gestita qui.
///
/// L'API pubblica (nomi dei metodi, getter, comportamento visibile) è
/// rimasta identica: gli screen che usano questo provider non richiedono
/// modifiche per continuare a funzionare come prima.
class ShoppingListProvider extends ChangeNotifier {
  final ShoppingListService _service = ShoppingListService();

  List<ShoppingItem> _items = [];
  final Set<String> _pendingDeleteIds = {};

  ShoppingListProvider();

  /// Passa alla lista della spesa di un'altra casa, aprendo (o migrando,
  /// se necessario) il box Hive dedicato.
  Future<void> switchHouse(String houseName) async {
    await _service.switchHouse(houseName);
    loadItems();
  }

  /// Ricarica la lista dalla sorgente dati e notifica la UI.
  void loadItems() {
    _items = _service.getAll();
    notifyListeners();
  }

  /// Elementi visibili, cioè non in attesa di conferma di eliminazione
  /// (pattern "swipe to delete con annulla", vedi [hideItem]).
  List<ShoppingItem> get items =>
      _items.where((item) => !_pendingDeleteIds.contains(item.id)).toList();

  List<ShoppingItem> get daAcquistare =>
      items.where((item) => !item.preso).toList();

  List<ShoppingItem> get giaPreso =>
      items.where((item) => item.preso).toList();

  /// Aggiunge un nuovo articolo alla lista della spesa.
  ///
  /// L'id viene generato con `uuid` invece che con
  /// `DateTime.now().millisecondsSinceEpoch`, per uniformità con `Location`
  /// (che già usava `uuid`) e per eliminare il rischio, seppur remoto, di
  /// collisioni tra id generati nello stesso millisecondo.
  Future<void> addItem(String nome, {String? marca, String? imagePath}) async {
    final newItem = ShoppingItem(
      id: const Uuid().v4(),
      nome: nome,
      marca: marca,
      imagePath: imagePath,
      preso: false,
    );

    await _service.addItem(newItem);
    loadItems();
  }

  /// Nasconde temporaneamente l'elemento (usato per l'animazione di
  /// eliminazione con snackbar "Annulla").
  void hideItem(String id) {
    _pendingDeleteIds.add(id);
    notifyListeners();
  }

  /// Annulla l'eliminazione rendendo di nuovo visibile l'elemento.
  void cancelDeleteItem(String id) {
    _pendingDeleteIds.remove(id);
    notifyListeners();
  }

  /// Elimina definitivamente l'articolo da Hive, dopo che la finestra per
  /// annullare l'operazione è scaduta. Se l'articolo aveva un'immagine
  /// locale (foto scattata dall'utente), viene ripulita anche quella per
  /// non lasciare file orfani sullo storage del device.
  Future<void> confirmDeleteItem(String id) async {
    _pendingDeleteIds.remove(id);
    final item = _findById(id);

    await _service.deleteItem(id);
    if (item != null) {
      await ImageStorageService.deleteImage(item.imagePath);
    }
    loadItems();
  }

  /// Aggiorna un articolo esistente (es. da `ShoppingItemEditScreen`).
  ///
  /// [previousImagePath] è opzionale: se lo screen chiamante passa il path
  /// dell'immagine precedente e questa è stata sostituita con una nuova,
  /// il vecchio file locale viene cancellato per evitare di accumulare
  /// immagini non più referenziate.
  Future<void> updateItem(ShoppingItem item, {String? previousImagePath}) async {
    await _service.updateItem(item);

    if (previousImagePath != null && previousImagePath != item.imagePath) {
      await ImageStorageService.deleteImage(previousImagePath);
    }
    loadItems();
  }

  /// Segna/desegna un articolo come "preso" (spostandolo tra le due
  /// sezioni della lista spesa). Non serve ricaricare l'intera lista da
  /// Hive: l'oggetto [item] è lo stesso riferimento già presente in
  /// [_items], quindi basta salvarlo e notificare la UI.
  Future<void> toggleItem(ShoppingItem item) async {
    item.preso = !item.preso;
    await _service.updateItem(item);
    notifyListeners();
  }

  /// Elimina un articolo senza passare dal flusso "nascondi + conferma"
  /// (usato per l'eliminazione multipla in `shopping_list_screen.dart` e
  /// per la rimozione automatica dal carrello quando un prodotto scansionato
  /// viene salvato in dispensa).
  Future<void> deleteItem(String id) async {
    final item = _findById(id);

    await _service.deleteItem(id);
    if (item != null) {
      await ImageStorageService.deleteImage(item.imagePath);
    }
    loadItems();
  }

  /// Cerca un articolo per id nella lista in memoria, usato per recuperare
  /// il vecchio `imagePath` prima di eliminare/aggiornare un elemento.
  ShoppingItem? _findById(String id) {
    try {
      return _items.firstWhere((item) => item.id == id);
    } catch (_) {
      return null;
    }
  }
}
