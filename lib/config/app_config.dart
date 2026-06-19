class AppConfig {
  /// =========================
  /// 🌐 BASE URL
  /// =========================
  static const String baseUrl =
      'https://antoinekakawah.pythonanywhere.com';

  /// =========================
  /// 📡 API PUBLIQUES
  /// =========================
  static const String residencesEndpoint = '/api/residences/';
  static const String artisansEndpoint = '/api/artisans/';
  static const String adsEndpoint = '/api/publicites/';

  /// =========================
  /// 🔐 AUTHENTIFICATION (PROPRIÉTAIRES)
  /// =========================
  static const String loginEndpoint = '/api/login/';
  static const String meEndpoint = '/api/me/';

  /// =========================
  /// 🏠 PROPRIÉTAIRE (CRUD)
  /// =========================
  static const String createResidenceEndpoint =
      '/api/residences/ajouter/';

  /// =========================
  /// 💰 PAIEMENT ARTISAN
  /// =========================

  /// 👉 init paiement (POST)
  static String initArtisanPayment(int artisanId) =>
      '$baseUrl/api/artisans/$artisanId/payer/';

  /// 👉 vérification paiement (POST)
  static String verifyArtisanPayment(int artisanId) =>
      '$baseUrl/api/artisans/$artisanId/verify-payment/';

  /// 👉 check accès contact (GET)
  static String checkArtisanAccess(int artisanId, String email) =>
      '$baseUrl/api/artisans/$artisanId/check-access/?email=${Uri.encodeQueryComponent(email)}';

  // =========================
// 🔗 URL COMPLETES (OPTIONNEL)
// =========================

static String get residencesUrl =>
    '${AppConfig.baseUrl}${AppConfig.residencesEndpoint}';

static String get artisansUrl =>
    '${AppConfig.baseUrl}${AppConfig.artisansEndpoint}';

static String get adsUrl =>
    '${AppConfig.baseUrl}${AppConfig.adsEndpoint}';

static String get loginUrl =>
    '${AppConfig.baseUrl}${AppConfig.loginEndpoint}';

static String get meUrl =>
    '${AppConfig.baseUrl}${AppConfig.meEndpoint}';

static String get createResidenceUrl =>
    '${AppConfig.baseUrl}${AppConfig.createResidenceEndpoint}';
}