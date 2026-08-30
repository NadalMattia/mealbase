import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';

/// Base comune per tutti i servizi Hive "per casa" dell'app.
///
/// Prima `HiveService`, `LocationService` e `ShoppingListService`
/// duplicavano ciascuno la stessa identica logica: un box con nome
/// dinamico `'<base>_<nomeCasa>'`, apertura lazy, getter di comodo e le
/// stesse operazioni CRUD generiche. Ora quella logica vive in un solo
/// posto e ogni servizio implementa solo ciò che gli è specifico (es. i
/// valori di default delle location).
abstract class HouseScopedHiveService<T extends HiveObject> {
  final String baseBoxName;

  HouseScopedHiveService(this.baseBoxName);

  String? _boxName;

  /// Passa da una casa all'altra aprendo (se necessario) il box dedicato.
  /// Le sottoclassi possono sovrascrivere [onHouseSwitched] per eseguire
  /// logica aggiuntiva dopo l'apertura (es. seed di valori di default).
  @mustCallSuper
  Future<void> switchHouse(String houseName) async {
    _boxName = '${baseBoxName}_$houseName';
    if (!Hive.isBoxOpen(_boxName!)) {
      await Hive.openBox<T>(_boxName!);
    }
    await onHouseSwitched();
  }

  /// Hook per le sottoclassi, chiamato subito dopo che il box della casa
  /// corrente è stato aperto. Di default non fa nulla.
  @protected
  Future<void> onHouseSwitched() async {}

  /// true se una casa è stata selezionata e il box relativo è aperto.
  bool get isReady => _boxName != null && Hive.isBoxOpen(_boxName!);

  @protected
  Box<T> get box {
    final name = _boxName;
    if (name == null) {
      throw StateError(
        'Nessuna casa selezionata: chiama switchHouse() prima di usare questo servizio.',
      );
    }
    return Hive.box<T>(name);
  }

  List<T> getAll() => isReady ? box.values.toList() : [];

  Future<void> put(String key, T value) async => await box.put(key, value);

  Future<void> delete(String key) async => await box.delete(key);
}
