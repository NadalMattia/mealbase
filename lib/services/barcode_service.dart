import 'package:openfoodfacts/openfoodfacts.dart';

class BarcodeLookupResult {
  final bool found;
  final String? nome;
  final String? categoria;
  final String? imageUrl;

  BarcodeLookupResult({
    required this.found,
    this.nome,
    this.categoria,
    this.imageUrl,
  });
}

/// Interroga Open Food Facts per recuperare i dati di un prodotto a
/// partire dal suo codice a barre.
///
/// Prima faceva una chiamata HTTP "a mano" verso l'endpoint REST v2 e
/// parsava il JSON manualmente. Ora usa il pacchetto ufficiale
/// `openfoodfacts` (https://github.com/openfoodfacts/openfoodfacts-dart),
/// che si occupa di endpoint, versioning dell'API e parsing, ed espone
/// anche il campo immagine del prodotto.
class BarcodeService {
  Future<BarcodeLookupResult> lookup(String barcode) async {
    try {
      final result = await OpenFoodAPIClient.getProductV3(
        ProductQueryConfiguration(
          barcode,
          language: OpenFoodFactsLanguage.ITALIAN,
          fields: [
            ProductField.NAME,
            ProductField.IMAGE_FRONT_URL,
            ProductField.CATEGORIES,
          ],
          version: ProductQueryVersion.v3,
        ),
      );

      if (result.status != ProductResultV3.statusSuccess || result.product == null) {
        return BarcodeLookupResult(found: false);
      }

      final product = result.product!;
      final nome = product.productName;

      if (nome == null || nome.isEmpty) {
        return BarcodeLookupResult(found: false);
      }

      return BarcodeLookupResult(
        found: true,
        nome: nome,
        categoria: product.categories?.split(',').first.trim(),
        imageUrl: product.imageFrontUrl,
      );
    } catch (e) {
      // Connessione assente, timeout, o barcode non censito: non blocchiamo
      // mai l'utente, restituiamo semplicemente "non trovato" così la
      // schermata chiamante può proporre l'inserimento manuale.
      return BarcodeLookupResult(found: false);
    }
  }
}
