import 'package:flutter/material.dart';
import '../../../theme/app_theme.dart';

class Step3Interval extends StatelessWidget {
  final double initialInterval;
  final ValueChanged<double> onIntervalChanged;

  const Step3Interval({
    super.key,
    required this.initialInterval,
    required this.onIntervalChanged,
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
            child: const Icon(
              Icons.location_on,
              size: 60,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 32),
          Text(
            '위치 공개 주기 설정',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            '도둑의 위치가 경찰에게 공개되는\n간격을 설정하세요.',
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
                  initialInterval == 0 ? '실시간' : '${initialInterval.toInt()}분',
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
                    value: initialInterval,
                    min: 0,
                    max: 10,
                    divisions: 10,
                    onChanged: onIntervalChanged,
                  ),
                ),
                const SizedBox(height: 8),
                const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('실시간', style: TextStyle(color: AppColors.textHint)),
                    Text('10분', style: TextStyle(color: AppColors.textHint)),
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
