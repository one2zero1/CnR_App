import 'package:flutter_dotenv/flutter_dotenv.dart';

class EnvConfig {
  // Naver Maps
  static String get naverMapClientId =>
      dotenv.env['NAVER_MAP_CLIENT_ID'] ?? '';

  // Firebase
  static String get firebaseApiKey =>
      dotenv.env['FIREBASE_API_KEY'] ?? '';

  static String get firebaseProjectId =>
      dotenv.env['FIREBASE_PROJECT_ID'] ?? '';

  static String get firebaseMessagingSenderId =>
      dotenv.env['FIREBASE_MESSAGING_SENDER_ID'] ?? '';

  static String get firebaseAppId =>
      dotenv.env['FIREBASE_APP_ID'] ?? '';

  // API
  static String get apiBaseUrl =>
      dotenv.env['API_BASE_URL'] ?? 'https://api.example.com';

  static String get apiVersion =>
      dotenv.env['API_VERSION'] ?? 'v1';

  static String get apiUrl => '$apiBaseUrl/$apiVersion';

  // App Settings
  static String get appEnv =>
      dotenv.env['APP_ENV'] ?? 'development';

  static bool get isProduction => appEnv == 'production';

  static bool get isDevelopment => appEnv == 'development';

  static bool get debugMode =>
      dotenv.env['DEBUG_MODE']?.toLowerCase() == 'true';
}
