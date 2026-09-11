import 'package:flutter_test/flutter_test.dart';
import 'package:mealbase/models/product.dart';
import 'package:mealbase/models/product_category.dart';
import 'package:mealbase/models/shopping_item.dart';

void main() {
  group('ShoppingItem.quantita', () {
    test('vale 1 quando il campo persistito è nullo', () {
      // Gli articoli salvati prima dell'introduzione del campo hanno
      // quantitaRaw a null: devono restare leggibili con un valore
      // sensato invece di far fallire la lettura dell'intera lista.
      final item = ShoppingItem(id: 'a', nome: 'Latte')..quantitaRaw = null;
      expect(item.quantita, 1);
    });

    test('restituisce il valore persistito quando presente', () {
      final item = ShoppingItem(id: 'a', nome: 'Latte', quantita: 3);
      expect(item.quantita, 3);
    });

    test('il setter scrive sul campo persistito', () {
      final item = ShoppingItem(id: 'a', nome: 'Latte');
      item.quantita = 5;
      expect(item.quantitaRaw, 5);
    });
  });

  group('ProductCategories', () {
    test('labels contiene un elemento per ogni valore dell\'enum', () {
      expect(ProductCategories.labels.length, ProductCategory.values.length);
    });

    test('non esistono etichette duplicate', () {
      // Due categorie con la stessa etichetta romperebbero i DropdownButton,
      // che richiedono valori distinti fra gli items.
      final unique = ProductCategories.labels.toSet();
      expect(unique.length, ProductCategories.labels.length);
    });

    test('l\'etichetta predefinita è fra quelle disponibili', () {
      // ProductFormScreen usa defaultLabel come valore iniziale del
      // dropdown: se non fosse fra gli items, la schermata fallirebbe un
      // assert all'apertura.
      expect(ProductCategories.labels, contains(ProductCategories.defaultLabel));
    });
  });

  group('Product', () {
    test('conserva i campi passati al costruttore', () {
      final scadenza = DateTime(2026, 12, 31);
      final p = Product(
        id: 'p1',
        nome: 'Latte',
        quantita: 2,
        unita: 'l',
        categoria: ProductCategories.defaultLabel,
        posizione: 'Frigo',
        dataAcquisto: DateTime(2026, 1, 1),
        dataScadenza: scadenza,
      );

      expect(p.nome, 'Latte');
      expect(p.quantita, 2);
      expect(p.posizione, 'Frigo');
      expect(p.dataScadenza, scadenza);
    });

    test('la data di scadenza può essere assente', () {
      // I prodotti senza scadenza sono legittimi (pasta, scatolame) e
      // vengono esclusi dalla programmazione dei promemoria.
      final p = Product(
        id: 'p2',
        nome: 'Sale',
        quantita: 1,
        unita: 'pz',
        categoria: ProductCategories.defaultLabel,
        posizione: 'Dispensa',
        dataAcquisto: DateTime(2026, 1, 1),
      );

      expect(p.dataScadenza, isNull);
    });
  });
}
