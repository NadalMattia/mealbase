import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';

/// Base comune per i servizi che gestiscono dati appartenenti a una singola
/// casa: prodotti, spazi e lista della spesa hanno ciascuno un [Box] Hive
/// separato per ogni casa dell'utente.
///
/// Il nome del box è `<baseBoxName>_<houseId>`. La chiave è [House.id], un
/// UUID stabile generato alla creazione della casa e mai esposto
/// nell'interfaccia: il nome della casa è testo libero che l'utente può
/// rinominare o duplicare, quindi non è utilizzabile come identificatore di
/// storage.
///
/// La classe si occupa di aprire il box giusto al cambio casa, migrare
/// eventuali dati salvati con schemi di naming precedenti ed esporre le
/// operazioni CRUD. Le sottoclassi aggiungono solo la logica del proprio
/// dominio, tipicamente tramite l'hook [onHouseSwitched].
abstract class HouseScopedHiveService<T extends HiveObject> {
  /// Prefisso del nome del box, uguale per tutte le case (es. `products`).
  final String baseBoxName;

  /// Costruisce una copia di [original] slegata dal box di provenienza.
  ///
  /// Un [HiveObject] mantiene un riferimento al box in cui è memorizzato:
  /// inserire la stessa istanza in un secondo box fa lanciare
  /// `HiveError: The same instance of HiveObject cannot be stored in two
  /// boxes`. Durante la migrazione ogni elemento va quindi ricostruito, e
  /// solo la sottoclasse conosce i campi del proprio tipo.
  final T Function(T original) cloneForMigration;

  HouseScopedHiveService(this.baseBoxName, {required this.cloneForMigration});

  String? _boxName;
  String? _houseId;

  /// Seleziona la casa [houseId] e apre il box corrispondente.
  ///
  /// [legacyName] è il nome attuale della casa. Serve unicamente a
  /// individuare box creati con schemi di naming precedenti quando c'è una
  /// migrazione da fare, e non entra mai a far parte della chiave del box.
  ///
  /// La migrazione viene tentata solo alla prima apertura del box e solo se
  /// questo risulta vuoto, così da non ripetere il lavoro a ogni cambio
  /// casa né sovrascrivere dati già presenti.
  @mustCallSuper
  Future<void> switchHouse(String houseId, {String? legacyName}) async {
    _houseId = houseId;
    _boxName = '${baseBoxName}_$houseId';

    final isNewlyOpened = !Hive.isBoxOpen(_boxName!);
    if (isNewlyOpened) {
      await Hive.openBox<T>(_boxName!);
    }

    if (isNewlyOpened && legacyName != null && box.isEmpty) {
      await migrateLegacyBoxesIfNeeded(legacyName);
    }

    await onHouseSwitched();
  }

  /// Id della casa attualmente selezionata, `null` prima del primo
  /// [switchHouse].
  @protected
  String? get houseId => _houseId;

  /// Migra i dati salvati con lo schema di naming basato sul nome della
  /// casa verso il box corrente, basato sull'id.
  ///
  /// Le sottoclassi con ulteriori schemi storici da controllare
  /// sovrascrivono questo metodo, richiamano `super` e poi cercano i
  /// propri.
  @protected
  Future<void> migrateLegacyBoxesIfNeeded(String legacyName) async {
    await migrateFromBoxNamed('${baseBoxName}_$legacyName');
  }

  /// Copia nel box corrente tutti gli elementi di [legacyBoxName],
  /// preservandone le chiavi, quindi elimina il box di origine dal disco.
  ///
  /// Non fa nulla se il box non esiste o coincide con quello corrente.
  @protected
  Future<void> migrateFromBoxNamed(String legacyBoxName) async {
    if (legacyBoxName == _boxName) return;
    if (!await Hive.boxExists(legacyBoxName)) return;

    final legacyBox = Hive.isBoxOpen(legacyBoxName)
        ? Hive.box<T>(legacyBoxName)
        : await Hive.openBox<T>(legacyBoxName);

    var migrated = 0;
    for (final key in legacyBox.keys) {
      final original = legacyBox.get(key);
      if (original == null) continue;
      await box.put(key, cloneForMigration(original));
      migrated++;
    }

    await legacyBox.deleteFromDisk();

    if (migrated > 0) {
      debugPrint('Migrati $migrated elementi da "$legacyBoxName" a "$_boxName".');
    }
  }

  /// Punto di estensione invocato al termine di [switchHouse], a box aperto
  /// ed eventualmente migrato. L'implementazione di base non fa nulla.
  @protected
  Future<void> onHouseSwitched() async {}

  /// `true` quando una casa è stata selezionata e il suo box è aperto.
  bool get isReady => _boxName != null && Hive.isBoxOpen(_boxName!);

  /// Box della casa corrente.
  ///
  /// Lancia [StateError] se invocato prima di [switchHouse]: segnala un
  /// errore di sequenza nel chiamante, non una condizione da gestire a
  /// runtime.
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

  /// Tutti gli elementi della casa corrente, o lista vuota se nessuna casa
  /// è ancora stata selezionata.
  List<T> getAll() => isReady ? box.values.toList() : [];

  Future<void> put(String key, T value) async => await box.put(key, value);

  Future<void> delete(String key) async => await box.delete(key);
}
