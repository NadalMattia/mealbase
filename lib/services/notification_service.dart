import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();

  /// Inizializza il plugin di notifiche locali e richiede i permessi
  /// necessari.
  ///
  /// FIX: chiamato da `main.dart` con `await NotificationService().init()`
  /// PRIMA di `runApp()`. Questo significa che qualsiasi eccezione non
  /// gestita qui dentro (come è appena successo con l'icona
  /// `@mipmap/ic_launcher` non più esistente) impedisce all'intera app di
  /// avviarsi — anche se il problema riguarda solo una funzionalità
  /// secondaria come i promemoria di scadenza. L'app resta bloccata sulla
  /// schermata di apertura, o si chiude, senza che l'utente abbia modo di
  /// capire cosa sia successo.
  ///
  /// Ora tutta l'inizializzazione è avvolta in un try/catch: un problema
  /// con le notifiche (icona mancante, plugin non disponibile, permesso
  /// negato in modo anomalo, ecc.) può al massimo far sì che i
  /// promemoria di scadenza non funzionino, ma non deve MAI più poter
  /// impedire l'avvio dell'app.
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

  /// Programma una notifica il giorno prima della scadenza di un prodotto.
  ///
  /// FIX: prima veniva usato `AndroidScheduleMode.exactAllowWhileIdle`,
  /// che su Android 12+ richiede il permesso speciale
  /// `SCHEDULE_EXACT_ALARM` (o `USE_EXACT_ALARM`), NON dichiarato nel
  /// manifest dell'app. Senza quel permesso, il plugin lancia
  /// un'eccezione (`PlatformException: exact_alarms_not_permitted`) che
  /// non veniva intercettata da nessuna parte: risaliva fino a
  /// `_saveProduct()` in `product_form_screen.dart` e interrompeva
  /// silenziosamente tutto il salvataggio — da qui il "tasto Inserisci
  /// che sembra non fare nulla" ogni volta che si impostava una data di
  /// scadenza (l'unico caso in cui questo metodo viene chiamato).
  ///
  /// Per un promemoria "un giorno prima, alle 9" non serve una precisione
  /// al secondo: passiamo a `inexactAllowWhileIdle`, che su Android
  /// consegna la notifica con una tolleranza di qualche minuto ma NON
  /// richiede alcun permesso speciale. In più, avvolgiamo la chiamata in
  /// un try/catch: qualsiasi problema futuro con le notifiche (permesso
  /// negato dall'utente, plugin non disponibile, ecc.) non deve mai più
  /// poter bloccare il salvataggio del prodotto, che è la funzione
  /// principale di questo pulsante.
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