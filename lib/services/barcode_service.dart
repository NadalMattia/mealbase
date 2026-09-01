import 'package:openfoodfacts/openfoodfacts.dart';

class BarcodeLookupResult {
  final bool found;
  final String? nome;
  final String? marca;
  final String? categoria;
  final String? imageUrl;

  BarcodeLookupResult({
    required this.found,
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
              : 'Altro',
          imageUrl: p.imageFrontUrl,
        );
      }
    } catch (_) {}

    return BarcodeLookupResult(found: false);
  }
}