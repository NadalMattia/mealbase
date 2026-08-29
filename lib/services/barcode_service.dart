import 'dart:convert';
import 'package:http/http.dart' as http;

class BarcodeLookupResult {
  final bool found;
  final String? nome;
  final String? categoria;

  BarcodeLookupResult({required this.found, this.nome, this.categoria});
}

class BarcodeService {
  Future<BarcodeLookupResult> lookup(String barcode) async {
    final url = Uri.parse(
      'https://world.openfoodfacts.org/api/v2/product/$barcode.json',
    );

    try {
      final response = await http.get(url);

      if (response.statusCode != 200) {
        return BarcodeLookupResult(found: false);
      }

      final data = jsonDecode(response.body);

      if (data['status'] != 1 || data['product'] == null) {
        return BarcodeLookupResult(found: false);
      }

      final product = data['product'];
      final nome = product['product_name'] as String?;
      final categorie = product['categories'] as String?;

      if (nome == null || nome.isEmpty) {
        return BarcodeLookupResult(found: false);
      }

      return BarcodeLookupResult(
        found: true,
        nome: nome,
        categoria: categorie?.split(',').first.trim(),
      );
    } catch (e) {
      return BarcodeLookupResult(found: false);
    }
  }
}