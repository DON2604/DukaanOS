class AppConstants {
  /// Change this host/port when the backend moves. Route paths stay the same.

  static const String apiBaseUrl = 'http://10.194.206.22:8000';

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
  static const String inventoryDeduct = '/api/inventory/deduct';
  static const String imageRecognitionAnalyze =
      '/api/image-recognition/analyze';
  static const String imageRecognitionMatch =
      '/api/image-recognition/match-inventory';
  static const String khataDashboard = '/api/khata/dashboard';
  static const String khataTranscriptAnalyze = '/api/khata/transcripts/analyze';
  static const String khataEntries = '/api/khata/entries';
  static const String salesCheckout = '/api/sales/checkout';
  static const String salesSendReceipt = '/api/sales/send-receipt';

  static const String sessionIdKey = 'session_id';
  static const String accessTokenKey = 'access_token';
}
