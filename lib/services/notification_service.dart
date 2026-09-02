import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    tz.initializeTimeZones();
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
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
  }

  /// Converte l'id (stringa) di un prodotto nell'id numerico richiesto
  /// dal plugin di notifiche.
  ///
  /// PRIMA: si usava direttamente `id.hashCode`. Su Dart nativo
  /// `String.hashCode` può restituire un intero a 64 bit, mentre
  /// l'implementazione Android delle notifiche si aspetta un intero a 32
  /// bit con segno: un valore troppo grande rischia di essere troncato in
  /// modo diverso da qui a lì, aumentando il rischio (comunque basso, ma
  /// non nullo) che due prodotti diversi finiscano per condividere lo
  /// stesso id di notifica e si sovrascrivano a vicenda.
  ///
  /// ORA: mascheriamo esplicitamente il risultato a 31 bit (sempre
  /// positivo, sempre nel range di un int32 con segno), così il valore
  /// usato qui è esattamente quello che verrà interpretato dal plugin,
  /// senza troncamenti impliciti.
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
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );
  }

  Future<void> cancelNotification(String id) async {
    // Stesso calcolo di scheduleExpirationNotification: fondamentale usare
    // sempre la stessa funzione per andare/venire dall'id numerico, o la
    // cancellazione rischierebbe di non trovare la notifica giusta.
    await _plugin.cancel(id: _notificationIdFor(id));
  }
}