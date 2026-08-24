class AppConstants {
  /// Change this host/port when the backend moves. Route paths stay the same.
  static const String apiBaseUrl = 'http://192.168.1.249:8000';

  static const String createAccount = '/api/auth/create-account';
  static const String createAccountRequestOtp =
      '/api/auth/create-account/request-otp';
  static const String createAccountVerifyOtp =
      '/api/auth/create-account/verify-otp';
}
