import 'dart:async';
import 'dart:io';
import 'package:openfoodfacts/openfoodfacts.dart';
import '../models/product_category.dart';

/// Esito della ricerca di un barcode su Open Food Facts.
///
/// PRIMA: `BarcodeService.lookup` catturava ogni eccezione allo stesso
/// modo (`catch (_) {}`) e ritornava sempre `found: false`. Dal punto di
/// vista dell'utente, "il prodotto non è nel database di Open Food
/// Facts" e "non c'è connessione a internet" producevano lo stesso
/// messaggio ("Prodotto non trovato"), che è fuorviante nel secondo caso:
/// l'utente potrebbe pensare che il prodotto vada inserito manualmente,
/// quando in realtà basterebbe riprovare con la connessione attiva.
///
/// ORA: [networkError] permette a chi chiama questo servizio (gli screen
/// dello scanner) di distinguere i due casi e mostrare un messaggio
/// appropriato.
class BarcodeLookupResult {
  final bool found;

  /// true se la ricerca è fallita per un problema di rete/connessione
  /// (nessuna connessione, timeout) piuttosto che perché il prodotto non
  /// esiste nel database. Se true, [found] è sempre false.
  final bool networkError;

  final String? nome;
  final String? marca;
  final String? categoria;
  final String? imageUrl;

  BarcodeLookupResult({
    required this.found,
    this.networkError = false,
    this.nome,
    this.marca,
    this.categoria,
    this.imageUrl,
  });
}

class BarcodeService {
  Future<BarcodeLookupResult> lookup(String barcode) async {
    try {
      final ProductQueryConfiguration config = ProductQueryConfiguration(
        barcode,
        language: OpenFoodFactsLanguage.ITALIAN,
        fields: [
          ProductField.NAME,
          ProductField.BRANDS,
          ProductField.BRANDS_TAGS,
          ProductField.CATEGORIES_TAGS,
          ProductField.IMAGE_FRONT_URL,
        ],
        version: ProductQueryVersion.v3,
      );

      final ProductResultV3 result = await OpenFoodAPIClient.getProductV3(config);

      if (result.status == ProductResultV3.statusSuccess && result.product != null) {
        final p = result.product!;

        // Estrazione robusta della marca
        String? extractedBrand = p.brands;
        if ((extractedBrand == null || extractedBrand.trim().isEmpty) &&
            p.brandsTags != null &&
            p.brandsTags!.isNotEmpty) {
          extractedBrand = p.brandsTags!.first.replaceAll('it:', '').replaceAll('-', ' ');
        }

        // Pulizia eventuale virgola iniziale/finale
        if (extractedBrand != null) {
          extractedBrand = extractedBrand.split(',').first.trim();
        }

        return BarcodeLookupResult(
          found: true,
          nome: p.productName,
          marca: (extractedBrand != null && extractedBrand.isNotEmpty) ? extractedBrand : null,
          categoria: (p.categoriesTags != null && p.categoriesTags!.isNotEmpty)
              ? p.categoriesTags!.first.replaceAll('it:', '')
              : ProductCategories.defaultLabel,
          imageUrl: p.imageFrontUrl,
        );
      }

      // Risposta ricevuta correttamente dal server, ma il barcode non
      // corrisponde a nessun prodotto: questo è un "non trovato" genuino,
      // non un errore di rete.
      return BarcodeLookupResult(found: false);
    } on SocketException {
      // Nessuna connessione di rete disponibile.
      return BarcodeLookupResult(found: false, networkError: true);
    } on TimeoutException {
      // La richiesta ha impiegato troppo tempo (rete lenta/instabile).
      return BarcodeLookupResult(found: false, networkError: true);
    } catch (_) {
      // Altri errori imprevisti (es. risposta malformata): li trattiamo
      // come "non trovato" per non bloccare l'utente con un messaggio di
      // rete fuorviante quando in realtà non lo sappiamo con certezza.
      return BarcodeLookupResult(found: false);
    }
  }
}