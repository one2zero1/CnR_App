import 'package:flutter/material.dart';
import '../../../theme/app_theme.dart';

class Step2Time extends StatelessWidget {
  final double initialTime;
  final ValueChanged<double> onTimeChanged;

  const Step2Time({
    super.key,
    required this.initialTime,
    required this.onTimeChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.timer, size: 60, color: AppColors.primary),
          ),
          const SizedBox(height: 32),
          Text(
            '플레이 시간 설정',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            '게임이 진행될 시간을 설정하세요.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: theme.textTheme.bodyMedium?.color,
            ),
          ),
          const SizedBox(height: 48),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
            decoration: BoxDecoration(
              color: theme.cardTheme.color,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                Text(
                  '${initialTime.toInt()}분',
                  style: const TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 24),
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    activeTrackColor: AppColors.primary,
                    inactiveTrackColor: AppColors.primary.withOpacity(0.2),
                    thumbColor: AppColors.primary,
                    overlayColor: AppColors.primary.withOpacity(0.1),
                    trackHeight: 8,
                    thumbShape: const RoundSliderThumbShape(
                      enabledThumbRadius: 12,
                    ),
                  ),
                  child: Slider(
                    value: initialTime,
                    min: 10,
                    max: 60,
                    divisions: 5,
                    onChanged: onTimeChanged,
                  ),
                ),
                const SizedBox(height: 8),
                const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('10분', style: TextStyle(color: AppColors.textHint)),
                    Text('60분', style: TextStyle(color: AppColors.textHint)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
