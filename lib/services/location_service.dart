import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';
import '../models/location.dart';
import 'house_scoped_hive_service.dart';

/// Accesso agli spazi della dispensa (Frigo, Freezer, ...) di una casa.
///
/// Gli spazi hanno un ordinamento manuale scelto dall'utente, conservato
/// nel campo `ordine` e applicato da [getAll].
class LocationService extends HouseScopedHiveService<Location> {
  LocationService()
      : super(
          'locations',
          cloneForMigration: (l) => Location(id: l.id, nome: l.nome, ordine: l.ordine),
        );

  static void registerAdapter() {
    if (!Hive.isAdapterRegistered(2)) {
      Hive.registerAdapter(LocationAdapter());
    }
  }

  @override
  Future<void> onHouseSwitched() async {
    await _seedDefaultsIfEmpty();
  }

  /// Popola una casa nuova con i tre spazi predefiniti, così che l'utente
  /// trovi una dispensa già utilizzabile senza doverla configurare.
  Future<void> _seedDefaultsIfEmpty() async {
    if (box.isNotEmpty) return;
    const defaults = ['Frigo', 'Dispensa', 'Freezer'];
    for (var i = 0; i < defaults.length; i++) {
      final loc = Location(id: const Uuid().v4(), nome: defaults[i], ordine: i);
      await put(loc.id, loc);
    }
  }

  /// Spazi della casa corrente, nell'ordine scelto dall'utente.
  @override
  List<Location> getAll() {
    final list = super.getAll();
    list.sort((a, b) => a.ordine.compareTo(b.ordine));
    return list;
  }

  /// Crea uno spazio in coda all'elenco.
  ///
  /// Ritorna `false` senza salvare nulla se esiste già uno spazio con lo
  /// stesso nome, confrontato ignorando maiuscole e spazi ai bordi: due
  /// spazi omonimi produrrebbero due tab identiche, popolate dagli stessi
  /// prodotti, dato che [Product.posizione] li referenzia per nome.
  Future<bool> addLocation(String nome) async {
    final trimmed = nome.trim();
    final existing = super.getAll();

    final isDuplicate = existing.any(
      (l) => l.nome.trim().toLowerCase() == trimmed.toLowerCase(),
    );
    if (isDuplicate) return false;

    final maxOrdine = existing.isEmpty
        ? -1
        : existing.map((l) => l.ordine).reduce((a, b) => a > b ? a : b);
    final loc = Location(id: const Uuid().v4(), nome: trimmed, ordine: maxOrdine + 1);
    await put(loc.id, loc);
    return true;
  }

  Future<void> deleteLocation(String id) async => await delete(id);

  /// Riscrive il campo `ordine` di tutti gli spazi in base alla loro
  /// posizione in [newOrder], dopo un riordino da drag & drop.
  Future<void> reorder(List<Location> newOrder) async {
    for (var i = 0; i < newOrder.length; i++) {
      newOrder[i].ordine = i;
      await newOrder[i].save();
    }
  }
}
