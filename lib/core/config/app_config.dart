class AppConfig {
  AppConfig._();

  static const env = String.fromEnvironment('APP_ENV', defaultValue: 'dev');

  static bool get isProd => env == 'prod';
  static bool get isDev => !isProd;

  static String get driftDbName =>
      isProd ? 'salik_crm_local_prod' : 'salik_crm_local_dev';

  static String get envLabel => isProd ? 'PROD' : 'DEV';

  static String get envDisplayName => isProd ? 'Production App' : 'Dev App';

  static String get firebaseProjectId =>
      isProd ? 'salikeencms-prod' : 'salikeencms';

  static String get staffEmailDomain =>
      isProd ? '@cms.com' : '@dev.cms.com';

  /// Shared AES-256 field-crypto key (base64, 32 bytes). Same value for .NET.
  /// Override via `--dart-define=FIELD_CRYPTO_KEY_BASE64=...`
  static const fieldCryptoKeyBase64 = String.fromEnvironment(
    'FIELD_CRYPTO_KEY_BASE64',
    defaultValue: 'oseHVKBqsJE6twGWGPl4/51tjxNknNktqe1wU6vT1Ws=',
  );
}
