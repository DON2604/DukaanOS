import 'package:shared_preferences/shared_preferences.dart';

import '../constants.dart';

class SessionStore {
  static Future<void> save({
    required String sessionId,
    required String accessToken,
  }) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(AppConstants.sessionIdKey, sessionId);
    await preferences.setString(AppConstants.accessTokenKey, accessToken);
  }

  static Future<String?> getSessionId() async {
    final preferences = await SharedPreferences.getInstance();
    return preferences.getString(AppConstants.sessionIdKey);
  }

  static Future<String?> getAccessToken() async {
    final preferences = await SharedPreferences.getInstance();
    return preferences.getString(AppConstants.accessTokenKey);
  }

  static Future<void> clear() async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.remove(AppConstants.sessionIdKey);
    await preferences.remove(AppConstants.accessTokenKey);
  }
}
