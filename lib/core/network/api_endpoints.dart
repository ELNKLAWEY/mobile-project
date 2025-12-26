class ApiEndpoints {
  static const String baseUrl = 'https://api.mohamed-osama.cloud/api/v1';

  // Auth
  static const String login = '/auth/login';
  static const String register = '/auth/register';
  static const String logout = '/auth/logout';
  static const String me = '/auth/me';
  static const String googleAuth = '/auth/google';
  static const String resetPasswordCheckPhone = '/auth/reset-password/check-phone';
  static const String resetPasswordVerifyOtp = '/auth/reset-password/verify-otp';
  static const String resetPasswordChange = '/auth/reset-password/change';

  // Products
  static const String products = '/products';

  // Cart
  static const String cart = '/cart';

  // Orders
  static const String orders = '/orders';

  // Brands
  static const String brands = '/brands';

  // Favorites
  static const String favorites = '/favorites';
}
