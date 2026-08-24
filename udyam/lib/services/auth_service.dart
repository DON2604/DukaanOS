import 'dart:convert';

import 'package:http/http.dart' as http;

import '../constants.dart';

class AuthException implements Exception {
  AuthException(this.message);

  final String message;

  @override
  String toString() => message;
}

class AuthSession {
  static String? accessToken;
}

class AuthService {
  AuthService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;
  static const Duration _timeout = Duration(seconds: 15);

  Future<void> createAccount({
    required String name,
    required String phone,
    required int telegramChatId,
  }) async {
    final response = await _post(AppConstants.createAccount, {
      'name': name,
      'phone': phone,
      'telegram_chat_id': telegramChatId,
    });
    if (response.statusCode != 201) {
      throw AuthException(_messageFrom(response));
    }
  }

  Future<void> requestCreateAccountOtp(String phone) async {
    final response = await _post(AppConstants.createAccountRequestOtp, {
      'phone': phone,
    });
    if (response.statusCode != 200) {
      throw AuthException(_messageFrom(response));
    }
  }

  Future<String> verifyCreateAccountOtp({
    required String phone,
    required String otp,
  }) async {
    final response = await _post(AppConstants.createAccountVerifyOtp, {
      'phone': phone,
      'otp': otp,
    });
    if (response.statusCode != 200) {
      throw AuthException(_messageFrom(response));
    }

    final body = jsonDecode(response.body);
    final token = body is Map<String, dynamic>
        ? body['access_token'] as String?
        : null;
    if (token == null || token.isEmpty) {
      throw AuthException('Verification succeeded but no token was returned');
    }
    AuthSession.accessToken = token;
    return token;
  }

  Future<http.Response> _post(String path, Map<String, dynamic> body) {
    return _client
        .post(
          Uri.parse('${AppConstants.apiBaseUrl}$path'),
          headers: const {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
          body: jsonEncode(body),
        )
        .timeout(_timeout);
  }

  String _messageFrom(http.Response response) {
    try {
      final body = jsonDecode(response.body);
      if (body is Map && body['detail'] is String) {
        return body['detail'] as String;
      }
    } catch (_) {}
    return 'Something went wrong. Please try again.';
  }
}
