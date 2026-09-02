import 'package:hive_flutter/hive_flutter.dart';

/// Servizio minimale per ricordare se l'utente ha già visto gli aiuti
/// mostrati una sola volta nel ciclo di vita dell'app.
///
/// Non è un vero e proprio "sistema di onboarding": non c'è nessuna
/// sequenza di schermate né stato complesso da gestire. C'è un solo
/// flag persistito (in un piccolo box Hive dedicato), usato dal tip
/// contestuale sullo scanner barcode (vedi [ScanTipBubble] in
/// pantry_screen.dart). Se in futuro servissero altri tip "mostra una
/// volta sola", si aggiungono altre chiavi allo stesso box.
class OnboardingService {
  static const String _boxName = 'onboarding_flags';
  static const String _scanTipKey = 'scan_tip_seen';
  static const String _cartTipKey = 'cart_tip_seen';

  /// Va chiamato una volta in main.dart, come per gli altri box Hive
  /// dell'app.
  static Future<void> openBox() async {
    if (!Hive.isBoxOpen(_boxName)) {
      await Hive.openBox<bool>(_boxName);
    }
  }

  /// true se l'utente ha già chiuso/visto il tip dello scanner.
  /// Ritorna true anche se il box non è ancora pronto: in quel caso
  /// meglio non mostrare nulla piuttosto che rischiare un errore.
  static bool get hasSeenScanTip {
    if (!Hive.isBoxOpen(_boxName)) return true;
    return Hive.box<bool>(_boxName).get(_scanTipKey, defaultValue: false) ?? false;
  }

  /// Segna il tip come visto: non ricomparirà più.
  static Future<void> markScanTipSeen() async {
    if (!Hive.isBoxOpen(_boxName)) return;
    await Hive.box<bool>(_boxName).put(_scanTipKey, true);
  }

  /// true se l'utente ha già chiuso/visto il tip "tocca per spostare
  /// nel carrello" nella schermata Spesa.
  static bool get hasSeenCartTip {
    if (!Hive.isBoxOpen(_boxName)) return true;
    return Hive.box<bool>(_boxName).get(_cartTipKey, defaultValue: false) ?? false;
  }

  /// Segna il tip del carrello come visto: non ricomparirà più.
  static Future<void> markCartTipSeen() async {
    if (!Hive.isBoxOpen(_boxName)) return;
    await Hive.box<bool>(_boxName).put(_cartTipKey, true);
  }
}
