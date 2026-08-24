import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../constants.dart';
import '../../../services/session_store.dart';
import '../../scan_invoice_screen/models/invoice.dart';
import '../models/inventory_item.dart';

class InventoryServiceException implements Exception {
  const InventoryServiceException(this.message);

  final String message;

  @override
  String toString() => message;
}

class InventoryService {
  InventoryService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;
  static const _timeout = Duration(seconds: 20);

  Future<List<InventoryItem>> fetchItems() async {
    final response = await _client
        .get(_uri(AppConstants.inventory), headers: await _headers())
        .timeout(_timeout);
    if (response.statusCode != 200) {
      throw InventoryServiceException(_messageFrom(response));
    }
    final decoded = jsonDecode(response.body);
    final rawItems = decoded is List
        ? decoded
        : decoded is Map && decoded['items'] is List
        ? decoded['items'] as List
        : const [];
    return rawItems
        .whereType<Map>()
        .map((item) => InventoryItem.fromJson(Map<String, dynamic>.from(item)))
        .toList();
  }

  Future<List<InventoryItem>> addInvoiceItems(Invoice invoice) async {
    final response = await _client
        .post(
          _uri(AppConstants.inventoryBulk),
          headers: await _headers(contentType: true),
          body: jsonEncode({
            'items': invoice.items
                .map(
                  (item) => item.toInventoryJson(
                    supplierName: invoice.supplier.name,
                    invoiceNumber: invoice.invoiceNumber,
                  ),
                )
                .toList(),
          }),
        )
        .timeout(_timeout);
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw InventoryServiceException(_messageFrom(response));
    }
    final decoded = jsonDecode(response.body);
    final rawItems = decoded is List
        ? decoded
        : decoded is Map && decoded['items'] is List
        ? decoded['items'] as List
        : const [];
    return rawItems
        .whereType<Map>()
        .map((item) => InventoryItem.fromJson(Map<String, dynamic>.from(item)))
        .toList();
  }

  Future<Map<String, String>> _headers({bool contentType = false}) async {
    final token = await SessionStore.getAccessToken();
    if (token == null || token.isEmpty) {
      throw const InventoryServiceException('Please sign in again.');
    }
    return {
      'Accept': 'application/json',
      'Authorization': 'Bearer $token',
      if (contentType) 'Content-Type': 'application/json',
    };
  }

  Uri _uri(String path) {
    final base = AppConstants.apiBaseUrl.trim().replaceAll(RegExp(r'/+$'), '');
    return Uri.parse('$base$path');
  }

  String _messageFrom(http.Response response) {
    try {
      final body = jsonDecode(response.body);
      if (body is Map && body['detail'] is String) {
        return body['detail'] as String;
      }
    } catch (_) {}
    return 'Inventory could not be updated. Please try again.';
  }
}
