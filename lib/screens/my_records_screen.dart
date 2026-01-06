import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class MyRecordsScreen extends StatelessWidget {
  const MyRecordsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('내 기록'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildStatCard(
              title: '전체 통계',
              icon: Icons.bar_chart,
              children: [
                _buildStatRow('총 게임 수', '24게임'),
                _buildStatRow('승률', '58%'),
                _buildProgressBar(0.58),
              ],
            ),
            const SizedBox(height: 16),
            _buildStatCard(
              title: '경찰 모드',
              icon: Icons.local_police,
              iconColor: AppColors.police,
              children: [
                _buildStatRow('게임 수', '12게임'),
                _buildStatRow('승률', '67%'),
                _buildStatRow('평균 포획 수', '2.3명'),
                _buildStatRow('최다 포획 기록', '5명'),
              ],
            ),
            const SizedBox(height: 16),
            _buildStatCard(
              title: '도둑 모드',
              icon: Icons.directions_run,
              iconColor: AppColors.thief,
              children: [
                _buildStatRow('게임 수', '12게임'),
                _buildStatRow('승률', '50%'),
                _buildStatRow('평균 생존 시간', '18분 30초'),
                _buildStatRow('최장 생존 기록', '30분 (완주)'),
              ],
            ),
            const SizedBox(height: 24),
            const Text(
              '최근 게임',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            _buildGameHistoryItem(
              gameName: '한강 추격전',
              result: '승리',
              role: '경찰',
              date: '2025.01.05',
              isWin: true,
            ),
            _buildGameHistoryItem(
              gameName: '공원 도주',
              result: '패배',
              role: '도둑',
              date: '2025.01.04',
              isWin: false,
            ),
            _buildGameHistoryItem(
              gameName: '야간 작전',
              result: '승리',
              role: '도둑',
              date: '2025.01.03',
              isWin: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required IconData icon,
    Color iconColor = AppColors.primary,
    required List<Widget> children,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: iconColor, size: 24),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressBar(double value) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: LinearProgressIndicator(
          value: value,
          minHeight: 8,
          backgroundColor: AppColors.textHint.withOpacity(0.3),
          valueColor: const AlwaysStoppedAnimation<Color>(AppColors.success),
        ),
      ),
    );
  }

  Widget _buildGameHistoryItem({
    required String gameName,
    required String result,
    required String role,
    required String date,
    required bool isWin,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor:
              isWin ? AppColors.success.withOpacity(0.1) : AppColors.danger.withOpacity(0.1),
          child: Icon(
            isWin ? Icons.emoji_events : Icons.close,
            color: isWin ? AppColors.success : AppColors.danger,
          ),
        ),
        title: Text(
          gameName,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text('$role · $date'),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: isWin ? AppColors.success : AppColors.danger,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            result,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ),
        onTap: () {},
      ),
    );
  }
}
