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
  }

  Future<void> scheduleExpirationNotification({
    required String id,
    required String productName,
    required DateTime expirationDate,
  }) async {
    final notificationId = id.hashCode;

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
    await _plugin.cancel(id: id.hashCode);
  }
}