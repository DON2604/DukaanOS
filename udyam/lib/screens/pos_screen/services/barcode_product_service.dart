import 'dart:convert';

import 'package:http/http.dart' as http;

class BarcodeProductService {
  const BarcodeProductService();

  Future<Map<String, dynamic>> getProductInfoByBarcode(String barcode) async {
    final url = Uri.parse(
      'https://api.upcitemdb.com/prod/trial/lookup?upc=$barcode',
    );

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);

        if (data['items'] != null && (data['items'] as List).isNotEmpty) {
          final item = data['items'][0];

          final List offersList = item['offers'] ?? [];
          final List<double> prices = offersList
              .where((o) => o['price'] != null)
              .map<double>((o) => (o['price'] as num).toDouble())
              .toList();

          final List imagesList = item['images'] ?? [];
          final String? primaryImage = imagesList.isNotEmpty
              ? imagesList[0]
              : null;

          return {
            'barcode': barcode,
            'title': item['title'],
            'brand': item['brand'],
            'imageUrl': primaryImage,
            'lowestPrice': prices.isNotEmpty
                ? prices.reduce((a, b) => a < b ? a : b)
                : null,
            'offers': offersList
                .map((o) => {'merchant': o['merchant'], 'price': o['price']})
                .toList(),
          };
        }
      }
    } catch (e) {
      return {'barcode': barcode, 'error': e.toString()};
    }

    return {'barcode': barcode, 'message': 'Product not found'};
  }
}
