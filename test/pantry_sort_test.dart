import 'package:flutter_test/flutter_test.dart';
import 'package:mealbase/models/pantry_sort_option.dart';
import 'package:mealbase/models/product.dart';
import 'package:mealbase/models/product_category.dart';

/// Replica dell'ordinamento applicato da `PantryProductList`.
///
/// La logica vive dentro il `build` del widget e non è invocabile da un
/// test unitario. Estrarla in una funzione pura sarebbe il passo
/// successivo: finché resta duplicata qui, una modifica al widget va
/// riportata anche in questo file, altrimenti il test verifica codice
/// diverso da quello in esecuzione.
void applySort(List<Product> products, PantrySortOption sort) {
  products.sort((a, b) {
    switch (sort) {
      case PantrySortOption.expirationAsc:
        // I prodotti senza scadenza finiscono in fondo: ordinando per
        // urgenza, ciò che non scade non è mai urgente.
        if (a.dataScadenza == null && b.dataScadenza == null) return 0;
        if (a.dataScadenza == null) return 1;
        if (b.dataScadenza == null) return -1;
        return a.dataScadenza!.compareTo(b.dataScadenza!);

      case PantrySortOption.insertionDesc:
        return b.dataAcquisto.compareTo(a.dataAcquisto);

      case PantrySortOption.insertionAsc:
        return a.dataAcquisto.compareTo(b.dataAcquisto);

      case PantrySortOption.category:
        final catComp =
            a.categoria.toLowerCase().compareTo(b.categoria.toLowerCase());
        if (catComp != 0) return catComp;
        return a.nome.toLowerCase().compareTo(b.nome.toLowerCase());
    }
  });
}

Product _p(
  String nome, {
  DateTime? scadenza,
  DateTime? acquisto,
  String? categoria,
}) =>
    Product(
      id: nome,
      nome: nome,
      quantita: 1,
      unita: 'pz',
      categoria: categoria ?? ProductCategories.defaultLabel,
      posizione: 'Dispensa',
      dataAcquisto: acquisto ?? DateTime(2026, 1, 1),
      dataScadenza: scadenza,
    );

void main() {
  group('ordinamento per scadenza', () {
    test('mette per prima la scadenza più vicina', () {
      final products = [
        _p('Tardi', scadenza: DateTime(2026, 12, 1)),
        _p('Presto', scadenza: DateTime(2026, 6, 1)),
      ];

      applySort(products, PantrySortOption.expirationAsc);

      expect(products.map((p) => p.nome), ['Presto', 'Tardi']);
    });

    test('sposta in fondo i prodotti senza scadenza', () {
      final products = [
        _p('SenzaData'),
        _p('ConData', scadenza: DateTime(2026, 6, 1)),
      ];

      applySort(products, PantrySortOption.expirationAsc);

      expect(products.map((p) => p.nome), ['ConData', 'SenzaData']);
    });

    test('non fallisce quando nessun prodotto ha una scadenza', () {
      final products = [_p('Sale'), _p('Pasta')];

      expect(
        () => applySort(products, PantrySortOption.expirationAsc),
        returnsNormally,
      );
      expect(products.length, 2);
    });
  });

  group('ordinamento per categoria', () {
    test('raggruppa per categoria e, a parità, ordina per nome', () {
      final products = [
        _p('Zucchine', categoria: 'Verdura'),
        _p('Mele', categoria: 'Frutta'),
        _p('Carote', categoria: 'Verdura'),
        _p('Banane', categoria: 'Frutta'),
      ];

      applySort(products, PantrySortOption.category);

      expect(
        products.map((p) => p.nome),
        ['Banane', 'Mele', 'Carote', 'Zucchine'],
      );
    });

    test('ignora maiuscole e minuscole nel nome', () {
      // Senza toLowerCase il confronto avverrebbe per codice carattere e
      // tutte le maiuscole precederebbero le minuscole.
      final products = [
        _p('banana', categoria: 'Frutta'),
        _p('Ananas', categoria: 'Frutta'),
      ];

      applySort(products, PantrySortOption.category);

      expect(products.map((p) => p.nome), ['Ananas', 'banana']);
    });
  });

  group('ordinamento per inserimento', () {
    test('decrescente: il più recente per primo', () {
      final products = [
        _p('Vecchio', acquisto: DateTime(2026, 1, 1)),
        _p('Nuovo', acquisto: DateTime(2026, 5, 1)),
      ];

      applySort(products, PantrySortOption.insertionDesc);

      expect(products.first.nome, 'Nuovo');
    });

    test('crescente: il più vecchio per primo', () {
      final products = [
        _p('Nuovo', acquisto: DateTime(2026, 5, 1)),
        _p('Vecchio', acquisto: DateTime(2026, 1, 1)),
      ];

      applySort(products, PantrySortOption.insertionAsc);

      expect(products.first.nome, 'Vecchio');
    });
  });
}
