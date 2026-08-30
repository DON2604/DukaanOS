import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';

import '../../../constants.dart';
import '../../../services/session_store.dart';
import '../models/cart_item.dart';

enum PaymentType { cash, credit }

class CheckoutException implements Exception {
  const CheckoutException(this.message);
  final String message;
  @override
  String toString() => message;
}

class CheckoutService {
  CheckoutService({http.Client? client}) : _client = client ?? http.Client();
  final http.Client _client;

  Future<void> checkout({
    required List<CartItem> items,
    required double discount,
    required PaymentType paymentType,
    String? customerName,
  }) async {
    final token = await SessionStore.getAccessToken();
    if (token == null || token.isEmpty) {
      throw const CheckoutException('Please sign in again.');
    }
    final base = AppConstants.apiBaseUrl.trim().replaceAll(RegExp(r'/+$'), '');
    final inventoryIds = await _resolveInventoryIds(
      items,
      base: base,
      token: token,
    );
    final response = await _client
        .post(
          Uri.parse('$base${AppConstants.salesCheckout}'),
          headers: {
            'Accept': 'application/json',
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
          body: jsonEncode({
            'checkout_id': const Uuid().v4(),
            'items': items
                .map(
                  (item) => {
                    'inventory_item_id':
                        item.product.inventoryItemId ??
                        inventoryIds[_normalize(item.product.name)],
                    'quantity': item.quantity,
                    'unit_price': item.product.price,
                  },
                )
                .toList(),
            'discount': discount,
            'payment_type': paymentType.name,
            if (customerName?.trim().isNotEmpty == true)
              'customer': {'name': customerName!.trim()},
          }),
        )
        .timeout(const Duration(seconds: 20));
    if (response.statusCode >= 200 && response.statusCode < 300) return;
    try {
      final body = jsonDecode(response.body);
      if (body is Map && body['detail'] is String) {
        throw CheckoutException(body['detail'] as String);
      }
    } on CheckoutException {
      rethrow;
    } catch (_) {}
    throw const CheckoutException('Checkout failed. Your bill was preserved.');
  }

  /// Sends a bill receipt via Telegram without touching inventory.
  /// Silently ignores failures so the checkout UX is never blocked.
  Future<void> sendReceipt({
    required String receiptNumber,
    required List<CartItem> items,
    required double subtotal,
    required double discount,
    required double total,
    required PaymentType paymentType,
    String? customerName,
  }) async {
    try {
      final token = await SessionStore.getAccessToken();
      if (token == null || token.isEmpty) return;
      final base = AppConstants.apiBaseUrl.trim().replaceAll(
        RegExp(r'/+$'),
        '',
      );
      await _client
          .post(
            Uri.parse('$base${AppConstants.salesSendReceipt}'),
            headers: {
              'Accept': 'application/json',
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode({
              'receipt_number': receiptNumber,
              'items': items
                  .map(
                    (item) => {
                      'name': item.product.name,
                      'quantity': item.quantity,
                      'unit': item.product.unit,
                      'unit_price': item.product.price,
                      'line_total': item.totalPrice,
                    },
                  )
                  .toList(),
              'subtotal': subtotal,
              'discount': discount,
              'total': total,
              'payment_type': paymentType.name,
              if (customerName?.trim().isNotEmpty == true)
                'customer_name': customerName!.trim(),
            }),
          )
          .timeout(const Duration(seconds: 10));
    } catch (_) {
      // Receipt sending is best-effort — never block the checkout flow
    }
  }

  Future<Map<String, String>> _resolveInventoryIds(
    List<CartItem> items, {
    required String base,
    required String token,
  }) async {
    if (items.every((item) => item.product.inventoryItemId != null)) {
      return const {};
    }
    final response = await _client
        .get(
          Uri.parse('$base${AppConstants.inventory}'),
          headers: {
            'Accept': 'application/json',
            'Authorization': 'Bearer $token',
          },
        )
        .timeout(const Duration(seconds: 20));
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw const CheckoutException(
        'Inventory could not be checked. Your bill was preserved.',
      );
    }
    final decoded = jsonDecode(response.body);
    final ids = <String, String>{};
    if (decoded is List) {
      for (final row in decoded.whereType<Map>()) {
        final id = row['id']?.toString();
        final name = row['name']?.toString();
        if (id != null && name != null) ids[_normalize(name)] = id;
      }
    }
    final missing = items
        .where(
          (item) =>
              item.product.inventoryItemId == null &&
              !ids.containsKey(_normalize(item.product.name)),
        )
        .map((item) => item.product.name)
        .toSet();
    if (missing.isNotEmpty) {
      throw CheckoutException(
        'Add ${missing.join(', ')} to inventory before checkout.',
      );
    }
    return ids;
  }

  String _normalize(String value) =>
      value.trim().replaceAll(RegExp(r'\s+'), ' ').toLowerCase();
}
