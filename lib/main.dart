import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'theme/app_theme.dart';
import 'screens/splash_screen.dart';
import 'config/env_config.dart';
import 'services/auth_service.dart';
import 'services/room_service.dart';
import 'services/game_play_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 환경 변수 로드
  await dotenv.load(fileName: '.env');

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<AuthService>(create: (_) => MockAuthService()),
        Provider<RoomService>(create: (_) => HttpRoomService()),
        Provider<GamePlayService>(create: (_) => HttpGamePlayService()),
      ],
      child: MaterialApp(
        title: '경찰과 도둑',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        home: const SplashScreen(),
      ),
    );
  }
}
