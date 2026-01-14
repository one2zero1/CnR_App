import 'package:flutter/material.dart';
import '../../../../theme/app_theme.dart';
import '../../../../models/game_types.dart';

class Step0GameMode extends StatelessWidget {
  final GameMode selectedMode;
  final ValueChanged<GameMode> onModeChanged;

  const Step0GameMode({
    super.key,
    required this.selectedMode,
    required this.onModeChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '어떤 게임을 하시겠습니까?',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            '원하는 게임 방식을 선택해주세요.',
            style: TextStyle(fontSize: 16, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 32),
          _buildModeCard(
            context,
            mode: GameMode.basic,
            title: '일반 모드 (추격전)',
            description: 'GPS와 무전만 사용하는\n순수한 추격전입니다.',
            icon: Icons.directions_run,
            color: Colors.blue,
          ),
          const SizedBox(height: 16),
          _buildModeCard(
            context,
            mode: GameMode.advanced,
            title: '고급 모드 (작전 모드)',
            description: '일반 모드 기능에 더해\nQR코드로 체포와 탈출을 할 수 있습니다.',
            icon: Icons.qr_code_scanner,
            color: Colors.purple,
          ),
        ],
      ),
    );
  }

  Widget _buildModeCard(
    BuildContext context, {
    required GameMode mode,
    required String title,
    required String description,
    required IconData icon,
    required Color color,
  }) {
    final isSelected = selectedMode == mode;
    return GestureDetector(
      onTap: () => onModeChanged(mode),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.1) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? color : AppColors.textHint.withOpacity(0.3),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: color.withOpacity(0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 32),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? color : AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected) Icon(Icons.check_circle, color: color, size: 24),
          ],
        ),
      ),
    );
  }
}
