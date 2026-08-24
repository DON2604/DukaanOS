import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../constants.dart';
import '../../../services/session_store.dart';
import '../models/khata_models.dart';

class KhataServiceException implements Exception {
  const KhataServiceException(this.message);
  final String message;
  @override
  String toString() => message;
}

class KhataService {
  KhataService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;
  static const _timeout = Duration(seconds: 20);

  Future<KhataDashboard> fetchDashboard() async {
    final response = await _client
        .get(_uri(AppConstants.khataDashboard), headers: await _headers())
        .timeout(_timeout);
    _requireSuccess(response);
    final decoded = jsonDecode(response.body);
    if (decoded is! Map) {
      throw const KhataServiceException('The Khata response was not valid.');
    }
    return KhataDashboard.fromJson(Map<String, dynamic>.from(decoded));
  }

  Future<KhataEntry> updateEntry(
    String id, {
    required String description,
    required double amount,
  }) async {
    final response = await _client
        .patch(
          _uri('${AppConstants.khataEntries}/$id'),
          headers: await _headers(json: true),
          body: jsonEncode({'description': description, 'amount': amount}),
        )
        .timeout(_timeout);
    _requireSuccess(response);
    final decoded = jsonDecode(response.body);
    return KhataEntry.fromJson(
      decoded is Map
          ? Map<String, dynamic>.from(decoded)
          : {'id': id, 'description': description, 'amount': amount},
    );
  }

  Future<void> deleteEntry(String id) async {
    final response = await _client
        .delete(
          _uri('${AppConstants.khataEntries}/$id'),
          headers: await _headers(),
        )
        .timeout(_timeout);
    _requireSuccess(response);
  }

  Future<Map<String, String>> _headers({bool json = false}) async {
    final token = await SessionStore.getAccessToken();
    if (token == null || token.isEmpty) {
      throw const KhataServiceException('Please sign in again.');
    }
    return {
      'Accept': 'application/json',
      'Authorization': 'Bearer $token',
      if (json) 'Content-Type': 'application/json',
    };
  }

  Uri _uri(String path) {
    final base = AppConstants.apiBaseUrl.trim().replaceAll(RegExp(r'/+$'), '');
    return Uri.parse('$base$path');
  }

  void _requireSuccess(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) return;
    try {
      final body = jsonDecode(response.body);
      if (body is Map && body['detail'] is String) {
        throw KhataServiceException(body['detail'] as String);
      }
    } on KhataServiceException {
      rethrow;
    } catch (_) {}
    throw const KhataServiceException(
      'Khata could not be updated. Please try again.',
    );
  }
}
