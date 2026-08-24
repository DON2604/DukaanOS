import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

import '../../../constants.dart';
import '../../../services/session_store.dart';
import '../models/invoice.dart';

class InvoiceServiceException implements Exception {
  const InvoiceServiceException(this.message);

  final String message;

  @override
  String toString() => message;
}

class InvoiceService {
  InvoiceService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;
  static const _timeout = Duration(seconds: 45);

  Future<Invoice> analyzeImage(String imagePath) async {
    final token = await SessionStore.getAccessToken();
    if (token == null || token.isEmpty) {
      throw const InvoiceServiceException(
        'Please sign in again to scan invoices.',
      );
    }

    final request =
        http.MultipartRequest('POST', _uri(AppConstants.analyzeInvoice))
          ..headers['Accept'] = 'application/json'
          ..headers['Authorization'] = 'Bearer $token'
          ..files.add(
            await http.MultipartFile.fromPath(
              'image',
              imagePath,
              contentType: MediaType('image', 'jpeg'),
            ),
          );

    final streamed = await _client.send(request).timeout(_timeout);
    final response = await http.Response.fromStream(streamed);
    if (response.statusCode != 200) {
      throw InvoiceServiceException(_messageFrom(response));
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! Map) {
      throw const InvoiceServiceException(
        'Gemini returned an invalid invoice.',
      );
    }
    final body = Map<String, dynamic>.from(decoded);
    final rawInvoice = body['invoice'] is Map
        ? Map<String, dynamic>.from(body['invoice'] as Map)
        : body;
    final invoice = Invoice.fromJson(rawInvoice);
    if (invoice.items.isEmpty) {
      throw const InvoiceServiceException(
        'No invoice items were found. Try taking a clearer photo.',
      );
    }
    return invoice;
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
    return 'Could not analyze this invoice. Please try again.';
  }
}
