/// Categorie merceologiche disponibili per un [Product].
///
/// esiste un'unica fonte di verità (questo enum). Chi ha bisogno
/// dell'elenco delle etichette da mostrare in UI usa [ProductCategory.labels].
///
/// NOTA IMPORTANTE SULLA COMPATIBILITÀ DATI: il campo `Product.categoria`
/// resta un `String` esattamente come prima (nessuna modifica al modello
/// Hive, quindi nessuna necessità di rigenerare gli adapter o migrare i
/// dati già salvati).
///
/// Questo enum viene usato solo lato UI per costruire le
/// opzioni e viene sempre convertito da/verso la stessa stringa italiana
/// già in uso (`label`), quindi i prodotti salvati in precedenza restano
/// perfettamente leggibili.
enum ProductCategory {
  altro,
  frutta,
  verdura,
  latticini,
  carne,
  pesce,
  bevande,
  surgelati,
}

/// Etichette testuali (in italiano) mostrate all'utente e salvate come
/// `Product.categoria`. Ordine invariato rispetto alle liste originali.
extension ProductCategoryLabel on ProductCategory {
  String get label {
    switch (this) {
      case ProductCategory.altro:
        return 'Altro';
      case ProductCategory.frutta:
        return 'Frutta';
      case ProductCategory.verdura:
        return 'Verdura';
      case ProductCategory.latticini:
        return 'Latticini';
      case ProductCategory.carne:
        return 'Carne';
      case ProductCategory.pesce:
        return 'Pesce';
      case ProductCategory.bevande:
        return 'Bevande';
      case ProductCategory.surgelati:
        return 'Surgelati';
    }
  }
}

/// Helper statici di comodo per chi deve popolare dropdown/filtri.
class ProductCategories {
  ProductCategories._();

  /// Tutte le etichette, nello stesso ordine dell'enum.
  /// Equivalente alla vecchia lista hardcoded, ma generata da un'unica
  /// fonte di verità.
  static List<String> get labels =>
      ProductCategory.values.map((c) => c.label).toList();

  /// Etichetta di default usata quando un prodotto non ha ancora una
  /// categoria assegnata (comportamento invariato rispetto a prima: 'Altro').
  static const String defaultLabel = 'Altro';
}
