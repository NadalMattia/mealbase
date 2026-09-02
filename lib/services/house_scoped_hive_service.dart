import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';

abstract class HouseScopedHiveService<T extends HiveObject> {
  final String baseBoxName;

  HouseScopedHiveService(this.baseBoxName);

  String? _boxName;
  String? _houseName;

  /// Passa da una casa all'altra aprendo (se necessario) il box dedicato.
  /// Le sottoclassi possono sovrascrivere [onHouseSwitched] per eseguire
  /// logica aggiuntiva dopo l'apertura (es. seed di valori di default,
  /// o una migrazione da un vecchio schema di naming del box).
  @mustCallSuper
  Future<void> switchHouse(String houseName) async {
    _houseName = houseName;
    _boxName = '${baseBoxName}_$houseName';
    if (!Hive.isBoxOpen(_boxName!)) {
      await Hive.openBox<T>(_boxName!);
    }
    await onHouseSwitched();
  }

  /// Nome della casa attualmente selezionata (quello passato a
  /// [switchHouse]), utile alle sottoclassi che devono ricostruire nomi di
  /// box "legacy" per operazioni di migrazione una tantum.
  @protected
  String? get houseName => _houseName;

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
