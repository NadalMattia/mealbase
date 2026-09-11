import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mealbase/theme/app_theme.dart';
import 'package:mealbase/widgets/coming_soon_screen.dart';
import 'package:mealbase/widgets/pantry_empty_state.dart';
import 'package:mealbase/widgets/shopping_empty_state.dart';

/// Widget test sui componenti privi di dipendenze esterne.
///
/// Non viene montata l'intera app: `MyApp` richiede Hive inizializzato, i
/// box aperti e i quattro provider registrati, quindi servirebbe un setup
/// di integrazione. Questi test coprono invece i widget che ricevono tutto
/// dal costruttore e non leggono provider né persistenza — la maggior
/// parte di quelli in `lib/widgets`.
void main() {
  /// Monta [child] dentro il minimo indispensabile perché i widget
  /// Material funzionino.
  Widget wrap(Widget child) => MaterialApp(
        theme: buildAppTheme(),
        home: Scaffold(body: child),
      );

  group('PantryEmptyState', () {
    testWidgets('mostra l\'invito a popolare la dispensa', (tester) async {
      await tester.pumpWidget(wrap(const PantryEmptyState()));

      expect(find.text('La tua dispensa è vuota'), findsOneWidget);
      expect(find.byIcon(Icons.kitchen_outlined), findsOneWidget);
    });

    testWidgets('cita entrambe le azioni disponibili', (tester) async {
      // Il sottotitolo nomina i due pulsanti della barra. Se le etichette
      // cambiano, questo test lo segnala: sono stringhe indipendenti e
      // niente altro le tiene allineate.
      await tester.pumpWidget(wrap(const PantryEmptyState()));

      final testo = tester
          .widgetList<Text>(find.byType(Text))
          .map((t) => t.data ?? '')
          .join(' ');

      expect(testo, contains('Inserisci'));
      expect(testo, contains('Scansiona'));
    });
  });

  group('ShoppingEmptyState', () {
    testWidgets('viene renderizzato senza errori', (tester) async {
      await tester.pumpWidget(wrap(const ShoppingEmptyState()));

      expect(find.byType(ShoppingEmptyState), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('ComingSoonScreen', () {
    testWidgets('mostra titolo, messaggio e icona ricevuti', (tester) async {
      // ComingSoonScreen fornisce già il proprio Scaffold, quindi va
      // montata come home e non dentro wrap().
      await tester.pumpWidget(
        MaterialApp(
          theme: buildAppTheme(),
          home: const ComingSoonScreen(
            appBarTitle: 'Ricette',
            icon: Icons.restaurant_menu,
            title: 'Funzionalità in arrivo',
            message: 'Un messaggio di prova.',
          ),
        ),
      );

      expect(find.text('Funzionalità in arrivo'), findsOneWidget);
      expect(find.text('Un messaggio di prova.'), findsOneWidget);
      expect(find.byIcon(Icons.restaurant_menu), findsOneWidget);
    });
  });
}
