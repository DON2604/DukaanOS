import 'dart:convert';

import 'package:http/http.dart' as http;

import '../constants.dart';
import 'session_store.dart';

enum AuthFlow { signUp, signIn }

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
    required String shopName,
    required String shopType,
  }) async {
    final response = await _post(AppConstants.createAccount, {
      'name': name,
      'phone': phone,
      'telegram_chat_id': telegramChatId,
      'shop_name': shopName,
      'shop_type': shopType,
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

  Future<void> requestSignInOtp(String phone) async {
    final response = await _post(AppConstants.signInRequestOtp, {
      'phone': phone,
    });
    if (response.statusCode != 200) {
      throw AuthException(_messageFrom(response));
    }
  }

  Future<String> verifyOtp({
    required String phone,
    required String otp,
    required AuthFlow flow,
  }) async {
    final path = flow == AuthFlow.signUp
        ? AppConstants.createAccountVerifyOtp
        : AppConstants.signInVerifyOtp;
    final response = await _post(path, {'phone': phone, 'otp': otp});
    if (response.statusCode != 200) {
      throw AuthException(_messageFrom(response));
    }

    final body = jsonDecode(response.body);
    final token = body is Map<String, dynamic>
        ? body['access_token'] as String?
        : null;
    final sessionId = body is Map<String, dynamic>
        ? body['session_id'] as String?
        : null;
    if (token == null ||
        token.isEmpty ||
        sessionId == null ||
        sessionId.isEmpty) {
      throw AuthException('Verification succeeded but no session was returned');
    }
    AuthSession.accessToken = token;
    await SessionStore.save(sessionId: sessionId, accessToken: token);
    return sessionId;
  }

  Future<bool> verifySession(String sessionId) async {
    final response = await _client
        .get(
          Uri.parse(
            '${AppConstants.apiBaseUrl}${AppConstants.session}/$sessionId',
          ),
          headers: const {'Accept': 'application/json'},
        )
        .timeout(_timeout);
    if (response.statusCode == 404) return false;
    if (response.statusCode != 200) {
      throw AuthException(_messageFrom(response));
    }
    final body = jsonDecode(response.body);
    return body is Map<String, dynamic> && body['valid'] == true;
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
