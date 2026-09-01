/// Categorie merceologiche disponibili per un [Product].
///
/// PRIMA: la stessa lista di stringhe ('Altro', 'Frutta/Verdura', ...) era
/// duplicata sia in `product_form_screen.dart` (dropdown di scelta
/// categoria) sia in `pantry_filter_bottom_sheet.dart` (filtro per
/// categoria). Le due liste potevano disallinearsi silenziosamente: una
/// categoria rinominata/aggiunta in un punto e non nell'altro avrebbe
/// prodotto un dropdown e un filtro con opzioni diverse, senza che nessun
/// errore lo segnalasse.
///
/// ORA: esiste un'unica fonte di verità (questo enum). Chi ha bisogno
/// dell'elenco delle etichette da mostrare in UI usa [ProductCategory.labels].
///
/// NOTA IMPORTANTE SULLA COMPATIBILITÀ DATI: il campo `Product.categoria`
/// resta un `String` esattamente come prima (nessuna modifica al modello
/// Hive, quindi nessuna necessità di rigenerare gli adapter o migrare i
/// dati già salvati). Questo enum viene usato solo lato UI per costruire le
/// opzioni e viene sempre convertito da/verso la stessa stringa italiana
/// già in uso (`label`), quindi i prodotti salvati in precedenza restano
/// perfettamente leggibili.
enum ProductCategory {
  altro,
  fruttaVerdura,
  latticini,
  carnePesce,
  dispensa,
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
      case ProductCategory.fruttaVerdura:
        return 'Frutta/Verdura';
      case ProductCategory.latticini:
        return 'Latticini';
      case ProductCategory.carnePesce:
        return 'Carne/Pesce';
      case ProductCategory.dispensa:
        return 'Dispensa';
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
