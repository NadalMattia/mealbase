import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();

  /// Tutta l'inizializzazione è avvolta in un try/catch: un problema
  /// con le notifiche (icona mancante, plugin non disponibile, permesso
  /// negato in modo anomalo, ecc.) può al massimo far sì che i
  /// promemoria di scadenza non funzionino

  Future<void> init() async {
    try {
      tz.initializeTimeZones();
      const android = AndroidInitializationSettings('@mipmap/launcher_icon');
      const ios = DarwinInitializationSettings();

      await _plugin.initialize(
        settings: const InitializationSettings(android: android, iOS: ios),
      );

      // Richiesta esplicita del permesso di mostrare notifiche.
      //
      // PRIMA: questo passaggio mancava. Su Android 13+ (targetSdk >= 33)
      // il permesso POST_NOTIFICATIONS va richiesto esplicitamente a
      // runtime: senza questa chiamata, le notifiche di scadenza
      // programmate in `scheduleExpirationNotification` non venivano mai
      // mostrate su quei dispositivi, senza che l'app segnalasse alcun
      // errore (il "fallimento" era silenzioso e difficile da diagnosticare
      // per l'utente).
      //
      // `resolvePlatformSpecificImplementation` ritorna `null` sulla
      // piattaforma "sbagliata" (es. l'implementazione Android è null su
      // iOS), quindi le chiamate con `?.` sono sicure su ogni piattaforma.
      await _plugin
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();

      await _plugin
          .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(alert: true, badge: true, sound: true);
    } catch (e) {
      // Non blocchiamo mai l'avvio dell'app per un problema di notifiche.
      debugPrint('Impossibile inizializzare le notifiche: $e');
    }
  }

  int _notificationIdFor(String productId) => productId.hashCode & 0x7FFFFFFF;

  Future<void> scheduleExpirationNotification({
    required String id,
    required String productName,
    required DateTime expirationDate,
  }) async {
    final notificationId = _notificationIdFor(id);

    final notifyDate = expirationDate.subtract(const Duration(days: 1));
    final scheduledTz = tz.TZDateTime.from(
      DateTime(notifyDate.year, notifyDate.month, notifyDate.day, 9, 0),
      tz.local,
    );

    if (scheduledTz.isBefore(tz.TZDateTime.now(tz.local))) return;

    try {
      await _plugin.zonedSchedule(
        id: notificationId,
        title: 'Prodotto in scadenza!',
        body: '$productName scade domani. Ricordati di consumarlo!',
        scheduledDate: scheduledTz,
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            'pantry_expirations',
            'Scadenze Dispensa',
            channelDescription: 'Notifiche per i prodotti in scadenza',
            importance: Importance.high,
            priority: Priority.high,
          ),
          iOS: DarwinNotificationDetails(),
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      );
    } catch (e) {
      // Non blocchiamo mai il salvataggio del prodotto per un problema
      // di notifiche: al massimo il promemoria non verrà mostrato.
      debugPrint('Impossibile programmare la notifica di scadenza: $e');
    }
  }

  Future<void> cancelNotification(String id) async {
    // Stesso calcolo di scheduleExpirationNotification: fondamentale usare
    // sempre la stessa funzione per andare/venire dall'id numerico, o la
    // cancellazione rischierebbe di non trovare la notifica giusta.
    try {
      await _plugin.cancel(id: _notificationIdFor(id));
    } catch (e) {
      // Stessa logica di sicurezza di scheduleExpirationNotification: un
      // problema nel cancellare una notifica non deve mai bloccare
      // un'operazione come l'eliminazione di un prodotto.
      debugPrint('Impossibile cancellare la notifica: $e');
    }
  }
}