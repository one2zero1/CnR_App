import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'home_screen.dart';
import 'home_screen.dart';

class GameResultScreen extends StatefulWidget {
  final String gameName;
  final bool isHostEnded;
  final String? winnerTeam; // 'Police' or 'Thief'

  const GameResultScreen({
    super.key,
    required this.gameName,
    this.isHostEnded = false,
    this.winnerTeam,
  });

  @override
  State<GameResultScreen> createState() => _GameResultScreenState();
}

class _GameResultScreenState extends State<GameResultScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Spacer(),
            _buildHeader(),
            const Spacer(),
            _buildBottomButton(),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    String title = '게임 종료';
    String message = '결과를 확인하세요';
    Color iconColor = Colors.amber;
    IconData icon = Icons.emoji_events;

    if (widget.isHostEnded) {
      title = '게임 종료';
      message = '호스트가 게임을 종료했습니다.';
      icon = Icons.cancel;
      iconColor = Colors.redAccent;
    } else if (widget.winnerTeam != null) {
      final isPoliceWin = widget.winnerTeam == 'Police';
      title = isPoliceWin ? '👮 경찰 승리!' : '🏃 도둑 승리!';
      message = isPoliceWin ? '경찰이 승리 했습니다' : '도둑이 승리 했습니다';
      iconColor = isPoliceWin ? AppColors.police : AppColors.thief;
    }

    return Container(
      padding: const EdgeInsets.all(24),
      margin: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: iconColor, size: 80),
          const SizedBox(height: 24),
          Text(
            title,
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: const TextStyle(
              fontSize: 20,
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildBottomButton() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => const HomeScreen()),
            (route) => false,
          );
        },
        icon: const Icon(Icons.home),
        label: const Text('홈으로 이동'),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }
}
