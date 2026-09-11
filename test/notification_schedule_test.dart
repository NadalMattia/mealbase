import 'package:flutter_test/flutter_test.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

/// Replica di `NotificationService._resolveScheduleTime`.
///
/// Il metodo originale è privato e dipende dal plugin delle notifiche, che
/// in un test unitario non è inizializzabile. Il calcolo è però la parte
/// con più casi limite dell'intero progetto - ed è quella che, sbagliata,
/// faceva sembrare le notifiche completamente non funzionanti - quindi
/// vale la pena verificarla in isolamento.
///
/// [now] è iniettato invece di leggere l'orologio di sistema: un test che
/// dipende dall'ora in cui viene eseguito fallisce a sorpresa.
tz.TZDateTime? resolveScheduleTime(
  DateTime expirationDate,
  tz.TZDateTime now, {
  int notifyHour = 9,
  Duration fallbackDelay = const Duration(minutes: 5),
}) {
  final notifyDay = expirationDate.subtract(const Duration(days: 1));
  final preferred = tz.TZDateTime.from(
    DateTime(notifyDay.year, notifyDay.month, notifyDay.day, notifyHour),
    tz.local,
  );

  if (preferred.isAfter(now)) return preferred;

  final expiration = tz.TZDateTime.from(expirationDate, tz.local);
  if (expiration.isAfter(now)) return now.add(fallbackDelay);

  return null;
}

void main() {
  setUpAll(() {
    tz.initializeTimeZones();
  });

  tz.TZDateTime at(int year, int month, int day, [int hour = 0, int min = 0]) =>
      tz.TZDateTime(tz.local, year, month, day, hour, min);

  group('caso normale', () {
    test('programma il giorno prima della scadenza alle 9:00', () {
      final now = at(2026, 6, 1, 10);
      final result = resolveScheduleTime(DateTime(2026, 6, 10), now);

      // Il confronto è sull'istante, non sui componenti dell'orario.
      // `TZDateTime.from` preserva l'istante assoluto e lo rappresenta in
      // `tz.local`: leggere `result.hour` restituirebbe l'ora in quel fuso,
      // che coincide con 9 solo se `tz.local` è il fuso di sistema. In un
      // test quella condizione dipende dalla macchina che lo esegue, e il
      // risultato cambierebbe fra il portatile e un runner in UTC.
      //
      // La garanzia che conta è un'altra: la notifica scatta nell'istante
      // corrispondente alle 9:00 di ora locale del giorno prima della
      // scadenza, ed è ciò che questa asserzione verifica.
      expect(result, isNotNull);
      expect(
        result!.millisecondsSinceEpoch,
        DateTime(2026, 6, 9, 9).millisecondsSinceEpoch,
      );
    });

    test('il giorno scelto è quello precedente alla scadenza', () {
      final now = at(2026, 6, 1, 10);
      final result = resolveScheduleTime(DateTime(2026, 6, 10), now);

      // `TZDateTime.toLocal()` non serve allo scopo: sovrascrive il metodo
      // di DateTime e restituisce un TZDateTime in `tz.local`, che qui è
      // UTC. Per ottenere l'ora di sistema bisogna passare per l'istante e
      // costruire un DateTime ordinario.
      final locale =
          DateTime.fromMillisecondsSinceEpoch(result!.millisecondsSinceEpoch);
      expect(locale.year, 2026);
      expect(locale.month, 6);
      expect(locale.day, 9);
      expect(locale.hour, 9);
    });

    test('funziona a cavallo di un cambio di mese', () {
      final now = at(2026, 5, 20, 10);
      final result = resolveScheduleTime(DateTime(2026, 6, 1), now);

      expect(
        result!.millisecondsSinceEpoch,
        DateTime(2026, 5, 31, 9).millisecondsSinceEpoch,
      );
    });
  });

  group('scadenza ravvicinata', () {
    test('prodotto che scade domani, ma le 9:00 di oggi sono passate', () {
      // È il caso con cui si prova la funzione appena scritta, e quello che
      // veniva scartato in silenzio: senza fallback l'utente non riceveva
      // nulla e concludeva che le notifiche non funzionassero.
      final now = at(2026, 6, 1, 14);
      final result = resolveScheduleTime(DateTime(2026, 6, 2), now);

      expect(result, isNotNull);
      expect(result, now.add(const Duration(minutes: 5)));
    });

    test('prodotto che scade oggi, più tardi', () {
      final now = at(2026, 6, 1, 8);
      final result = resolveScheduleTime(DateTime(2026, 6, 1, 20), now);

      expect(result, isNotNull);
      expect(result, now.add(const Duration(minutes: 5)));
    });

    test('il fallback non anticipa mai la notifica rispetto ad adesso', () {
      final now = at(2026, 6, 1, 23, 30);
      final result = resolveScheduleTime(DateTime(2026, 6, 2, 23, 59), now);

      expect(result!.isAfter(now), isTrue);
    });
  });

  group('prodotto già scaduto', () {
    test('non programma nulla', () {
      final now = at(2026, 6, 10);
      final result = resolveScheduleTime(DateTime(2026, 6, 1), now);

      expect(result, isNull);
    });

    test('non programma nulla nemmeno per una scadenza appena passata', () {
      final now = at(2026, 6, 1, 12);
      final result = resolveScheduleTime(DateTime(2026, 6, 1, 11), now);

      expect(result, isNull);
    });
  });

  group('istante programmato', () {
    test('è sempre nel futuro quando non è null', () {
      final now = at(2026, 6, 1, 14);

      for (final scadenza in [
        DateTime(2026, 6, 2),
        DateTime(2026, 6, 3),
        DateTime(2026, 12, 31),
        DateTime(2027, 1, 1),
      ]) {
        final result = resolveScheduleTime(scadenza, now);
        expect(result, isNotNull, reason: 'scadenza $scadenza');
        expect(result!.isAfter(now), isTrue, reason: 'scadenza $scadenza');
      }
    });
  });
}
