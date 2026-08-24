class AppConstants {
  /// Change this host/port when the backend moves. Route paths stay the same.

  static const String apiBaseUrl = 'http://192.168.1.249:8000';

  static const String createAccount = '/api/auth/create-account';
  static const String createAccountRequestOtp =
      '/api/auth/create-account/request-otp';
  static const String createAccountVerifyOtp =
      '/api/auth/create-account/verify-otp';
  static const String signInRequestOtp = '/api/auth/sign-in/request-otp';
  static const String signInVerifyOtp = '/api/auth/sign-in/verify-otp';
  static const String session = '/api/auth/session';
  static const String analyzeInvoice = '/api/invoices/analyze';
  static const String inventory = '/api/inventory';
  static const String inventoryBulk = '/api/inventory/bulk';

  static const String sessionIdKey = 'session_id';
  static const String accessTokenKey = 'access_token';
}
