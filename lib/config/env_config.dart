import 'package:flutter_dotenv/flutter_dotenv.dart';

class EnvConfig {
  // Naver Maps
  static String get naverMapClientId => dotenv.env['NAVER_MAP_CLIENT_ID'] ?? '';

  // Firebase
  static String get firebaseApiKey => dotenv.env['FIREBASE_API_KEY'] ?? '';

  static String get firebaseProjectId =>
      dotenv.env['FIREBASE_PROJECT_ID'] ?? '';

  static String get firebaseMessagingSenderId =>
      dotenv.env['FIREBASE_MESSAGING_SENDER_ID'] ?? '';

  static String get firebaseAppId => dotenv.env['FIREBASE_APP_ID'] ?? '';

  // API
  static String get apiBaseUrl =>
      dotenv.env['API_BASE_URL'] ?? 'http://10.0.2.2:8080';

  static String get apiVersion =>
      dotenv.env['API_VERSION'] ??
      ''; // Versioning might be empty based on docs

  static String get apiUrl => apiVersion.isEmpty ? apiBaseUrl : '$apiBaseUrl';

  // App Settings
  static String get appEnv => dotenv.env['APP_ENV'] ?? 'development';

  static bool get isProduction => appEnv == 'production';

  static bool get isDevelopment => appEnv == 'development';

  static bool get debugMode =>
      dotenv.env['DEBUG_MODE']?.toLowerCase() == 'true';

  static void validate() {
    if (isProduction) {
      final requiredKeys = [
        'NAVER_MAP_CLIENT_ID',
        'FIREBASE_API_KEY',
        'FIREBASE_PROJECT_ID',
        'FIREBASE_MESSAGING_SENDER_ID',
        'FIREBASE_APP_ID',
        'API_BASE_URL',
      ];

      for (var key in requiredKeys) {
        if (dotenv.env[key] == null || dotenv.env[key]!.isEmpty) {
          throw Exception(
            'Missing required environment variable in production: $key',
          );
        }
      }
    }
  }
}
