import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'nickname_screen.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  void _onGuestLogin(BuildContext context) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const NicknameScreen()),
    );
  }

  void _onGoogleLogin(BuildContext context) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('구글 로그인은 준비 중입니다.')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              // Logo or Title Area
              const Icon(
                Icons.security, // Placeholder icon
                size: 100,
                color: AppColors.primary,
              ),
              const SizedBox(height: 24),
              const Text(
                '경찰과 도둑',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                '실시간 추격전의 시작',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: AppColors.textSecondary),
              ),
              const Spacer(),
              // Actions Area
              ElevatedButton.icon(
                onPressed: () => _onGuestLogin(context),
                icon: const Icon(Icons.person_outline),
                label: const Text('게스트로 시작하기'),
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      AppColors.textSecondary, // Distinct color for guest
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  textStyle: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () => _onGoogleLogin(context),
                icon: const Icon(Icons.g_mobiledata), // Or custom asset
                label: const Text('Google로 시작하기'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black87,
                  side: const BorderSide(color: Colors.grey),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  textStyle: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 48),
            ],
          ),
        ),
      ),
    );
  }
}
