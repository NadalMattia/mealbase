import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

/// Promemoria locali per i prodotti in scadenza.
///
/// Singleton: il plugin sottostante mantiene stato nativo e va
/// inizializzato una sola volta per processo.
///
/// La consegna di una notifica pianificata dipende anche da configurazione
/// nativa che non vive in questo file: `AndroidManifest.xml` deve
/// dichiarare `ScheduledNotificationReceiver` e
/// `ScheduledNotificationBootReceiver`, altrimenti l'allarme viene
/// registrato senza che nessun componente lo riceva e la notifica non
/// compare, senza alcun errore lato Dart.
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();

  static const String _channelId = 'pantry_expirations';
  static const String _channelName = 'Scadenze Dispensa';
  static const String _channelDescription = 'Notifiche per i prodotti in scadenza';

  /// Ora del giorno in cui inviare il promemoria (il giorno prima della
  /// scadenza).
  static const int _notifyHour = 9;

  /// Quando il promemoria "canonico" è già passato, la notifica viene
  /// spostata a questo margine da adesso invece di essere scartata.
  static const Duration _fallbackDelay = Duration(minutes: 5);

  bool _initialized = false;
  bool _permissionGranted = false;

  bool get isInitialized => _initialized;
  bool get isPermissionGranted => _permissionGranted;

  AndroidFlutterLocalNotificationsPlugin? get _android =>
      _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();

  IOSFlutterLocalNotificationsPlugin? get _ios =>
      _plugin.resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();

  /// Inizializza plugin, database dei fusi orari, canale Android e
  /// permessi.
  ///
  /// Non lancia mai: un problema con le notifiche non deve impedire
  /// l'avvio dell'app. L'esito resta leggibile da [isInitialized] e
  /// [isPermissionGranted], così la UI può avvisare l'utente o proporre
  /// [openNotificationSettings].
  Future<void> init() async {
    try {
      tz.initializeTimeZones();

      const android = AndroidInitializationSettings('@mipmap/launcher_icon');
      const ios = DarwinInitializationSettings();

      await _plugin.initialize(
        settings: const InitializationSettings(android: android, iOS: ios),
      );
      _initialized = true;

      // Il canale va creato esplicitamente. Lasciandolo creare dalla prima
      // notifica, importanza e descrizione verrebbero da quella chiamata e
      // Android non permette più di modificarle in seguito.
      await _android?.createNotificationChannel(
        const AndroidNotificationChannel(
          _channelId,
          _channelName,
          description: _channelDescription,
          importance: Importance.high,
        ),
      );

      await _requestPermissions();
    } catch (e, s) {
      _initialized = false;
      debugPrint('Impossibile inizializzare le notifiche: $e\n$s');
    }
  }

  Future<void> _requestPermissions() async {
    // `resolvePlatformSpecificImplementation` ritorna null sulla piattaforma
    // "sbagliata", quindi le chiamate con `?.` sono sicure ovunque.
    final androidGranted = await _android?.requestNotificationsPermission();
    final iosGranted = await _ios?.requestPermissions(alert: true, badge: true, sound: true);

    _permissionGranted = androidGranted ?? iosGranted ?? false;

    if (!_permissionGranted) {
      debugPrint(
        'Permesso notifiche non concesso: i promemoria di scadenza non '
        'verranno mostrati finché non viene abilitato dalle impostazioni.',
      );
    }
  }

  /// Richiede di nuovo il permesso (utile da un pulsante in impostazioni).
  Future<bool> requestPermissionAgain() async {
    await _requestPermissions();
    return _permissionGranted;
  }

  /// Apre la schermata di sistema per gestire le notifiche dell'app.
  Future<void> openNotificationSettings() async {
    try {
      await _plugin.openAppNotificationSettings();
    } catch (e) {
      debugPrint('Impossibile aprire le impostazioni notifiche: $e');
    }
  }

  int _notificationIdFor(String productId) => productId.hashCode & 0x7FFFFFFF;

  /// Calcola l'istante in cui mostrare il promemoria.
  ///
  /// L'orario preferito è il giorno prima della scadenza alle
  /// [_notifyHour]. Quando quel momento è già trascorso ma il prodotto non
  /// è ancora scaduto - il caso di un acquisto con scadenza ravvicinata -
  /// la notifica viene spostata a [_fallbackDelay] da adesso anziché
  /// essere scartata. Ritorna `null` solo per un prodotto già scaduto.
  tz.TZDateTime? _resolveScheduleTime(DateTime expirationDate) {
    final now = tz.TZDateTime.now(tz.local);

    final notifyDay = expirationDate.subtract(const Duration(days: 1));
    final preferred = tz.TZDateTime.from(
      DateTime(notifyDay.year, notifyDay.month, notifyDay.day, _notifyHour),
      tz.local,
    );

    if (preferred.isAfter(now)) return preferred;

    // Il momento preferito è passato. Se il prodotto scade ancora in
    // futuro, avvisiamo comunque, a breve.
    final expiration = tz.TZDateTime.from(expirationDate, tz.local);
    if (expiration.isAfter(now)) return now.add(_fallbackDelay);

    return null;
  }

  Future<void> scheduleExpirationNotification({
    required String id,
    required String productName,
    required DateTime expirationDate,
  }) async {
    if (!_initialized) {
      debugPrint('Notifiche non inizializzate: schedulazione saltata.');
      return;
    }

    final scheduledTz = _resolveScheduleTime(expirationDate);
    if (scheduledTz == null) return; // prodotto già scaduto

    try {
      await _plugin.zonedSchedule(
        id: _notificationIdFor(id),
        title: 'Prodotto in scadenza!',
        body: '$productName scade domani. Ricordati di consumarlo!',
        scheduledDate: scheduledTz,
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            _channelId,
            _channelName,
            channelDescription: _channelDescription,
            importance: Importance.high,
            priority: Priority.high,
          ),
          iOS: DarwinNotificationDetails(),
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        payload: id,
      );
    } catch (e) {
      // Il chiamante sta salvando un prodotto: un promemoria non
      // programmato è preferibile a un salvataggio interrotto.
      debugPrint('Impossibile programmare la notifica di scadenza: $e');
    }
  }

  /// Rimuove il promemoria associato al prodotto [id].
  ///
  /// L'id numerico è ricavato con [_notificationIdFor], la stessa funzione
  /// usata in fase di programmazione: sono i due punti che devono restare
  /// allineati perché la cancellazione colpisca la notifica giusta.
  Future<void> cancelNotification(String id) async {
    try {
      await _plugin.cancel(id: _notificationIdFor(id));
    } catch (e) {
      debugPrint('Impossibile cancellare la notifica: $e');
    }
  }

  /// Cancella tutte le notifiche pianificate.
  Future<void> cancelAll() async {
    try {
      await _plugin.cancelAll();
    } catch (e) {
      debugPrint('Impossibile cancellare le notifiche: $e');
    }
  }

  /// Cancella tutti i promemoria e li riprogramma per [prodotti].
  ///
  /// Programmare le notifiche solo al salvataggio di un prodotto lascia
  /// scoperti i casi in cui la dispensa cambia senza passare da lì: cambio
  /// casa, permesso concesso dopo l'inserimento, reinstallazione.
  /// `PantryProvider` invoca questo metodo dopo ogni `switchHouse` per
  /// riallineare le notifiche allo stato reale della casa selezionata.
  Future<void> resyncAll(
    Iterable<({String id, String nome, DateTime scadenza})> prodotti,
  ) async {
    if (!_initialized) return;

    await cancelAll();
    for (final p in prodotti) {
      await scheduleExpirationNotification(
        id: p.id,
        productName: p.nome,
        expirationDate: p.scadenza,
      );
    }
  }

  // --- Diagnostica ---

  /// Indica se il sistema operativo ha le notifiche abilitate per l'app.
  Future<bool?> isEnabled() async {
    try {
      return await _android?.areNotificationsEnabled();
    } catch (e) {
      debugPrint('Impossibile leggere lo stato delle notifiche: $e');
      return null;
    }
  }

  /// Numero di notifiche effettivamente in coda nel sistema.
  Future<int> pendingCount() async {
    try {
      final pending = await _plugin.pendingNotificationRequests();
      return pending.length;
    } catch (e) {
      debugPrint('Impossibile leggere le notifiche pendenti: $e');
      return 0;
    }
  }

  /// Mostra subito una notifica di prova: verifica canale, icona e
  /// permessi senza attendere una scadenza reale.
  Future<void> showTestNotification() async {
    try {
      await _plugin.show(
        id: 999999,
        title: 'MealBase',
        body: 'Le notifiche funzionano correttamente.',
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            _channelId,
            _channelName,
            channelDescription: _channelDescription,
            importance: Importance.high,
            priority: Priority.high,
          ),
          iOS: DarwinNotificationDetails(),
        ),
      );
    } catch (e) {
      debugPrint('Impossibile mostrare la notifica di test: $e');
    }
  }

  /// Stampa lo stato dei singoli anelli della catena, per isolare il punto
  /// in cui una notifica non arriva.
  Future<void> debugStato() async {
    debugPrint('--- Stato notifiche ---');
    debugPrint('Inizializzato: $_initialized');
    debugPrint('Permesso concesso: $_permissionGranted');
    debugPrint('Abilitate dal sistema: ${await isEnabled()}');
    debugPrint('In coda: ${await pendingCount()}');
    debugPrint('Fuso orario locale: ${tz.local.name}');
  }
}
