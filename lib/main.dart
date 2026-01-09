import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'theme/app_theme.dart';
import 'providers/theme_provider.dart';
import 'screens/splash_screen.dart';
import 'config/env_config.dart';
import 'services/auth_service.dart';
import 'services/room_service.dart';
import 'services/game_play_service.dart';
import 'services/authority_service.dart';
import 'services/chat_service.dart';

import 'package:firebase_core/firebase_core.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 환경 변수 로드
  await dotenv.load(fileName: '.env');

  // Firebase 초기화 (native config 사용)
  try {
    await Firebase.initializeApp();
  } catch (e) {
    print("Firebase initialization failed: $e");
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        Provider<AuthService>(create: (_) => FirebaseAuthService()),
        Provider<RoomService>(create: (_) => FirebaseRoomService()),
        ProxyProvider2<AuthService, RoomService, GamePlayService>(
          update: (context, authService, roomService, previous) =>
              FirebaseGamePlayService(
                authService: authService,
                roomService: roomService,
              ),
        ),
        Provider<AuthorityService>(create: (_) => AuthorityService()),
        Provider<ChatService>(create: (_) => ChatService()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return MaterialApp(
            title: '경찰과 도둑',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeProvider.themeMode,
            home: const SplashScreen(),
          );
        },
      ),
    );
  }
}
