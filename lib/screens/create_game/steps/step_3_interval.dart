import 'package:flutter/material.dart';
import '../../../theme/app_theme.dart';

class Step3Interval extends StatelessWidget {
  final double initialInterval;
  final ValueChanged<double> onIntervalChanged;
  final bool policeCanSeeThieves;
  final ValueChanged<bool> onPoliceVisibilityChanged;
  final bool thievesCanSeePolice;
  final ValueChanged<bool> onThiefVisibilityChanged;

  const Step3Interval({
    super.key,
    required this.initialInterval,
    required this.onIntervalChanged,
    required this.policeCanSeeThieves,
    required this.onPoliceVisibilityChanged,
    required this.thievesCanSeePolice,
    required this.onThiefVisibilityChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bool isIntervalEnabled = policeCanSeeThieves || thievesCanSeePolice;

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // ... (keep header text same) ...
            const Text(
              '위치 공개 설정',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              '서로의 위치를 볼 수 있는지 설정하고,\n위치 갱신 주기를 정해주세요.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 32),

            // 1. Visibility Toggles
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.textHint.withOpacity(0.2)),
              ),
              child: Column(
                children: [
                  SwitchListTile(
                    title: const Text(
                      '경찰이 도둑 위치 확인',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: const Text('경찰 지도에 도둑이 표시됩니다.'),
                    value: policeCanSeeThieves,
                    onChanged: onPoliceVisibilityChanged,
                    activeColor: AppColors.police,
                  ),
                  const Divider(),
                  SwitchListTile(
                    title: const Text(
                      '도둑이 경찰 위치 확인',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: const Text('도둑 지도에 경찰이 표시됩니다.'),
                    value: thievesCanSeePolice,
                    onChanged: onThiefVisibilityChanged,
                    activeColor: AppColors.thief,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // 2. Interval Slider
            Opacity(
              opacity: isIntervalEnabled ? 1.0 : 0.5,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  vertical: 24,
                  horizontal: 20,
                ),
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
                    const Text(
                      '위치 공개 주기',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      !isIntervalEnabled
                          ? '공개 안함'
                          : initialInterval == 0
                          ? '실시간'
                          : '${initialInterval.toInt()}분',
                      style: TextStyle(
                        fontSize: 40,
                        fontWeight: FontWeight.bold,
                        color: isIntervalEnabled
                            ? AppColors.primary
                            : AppColors.textHint,
                      ),
                    ),
                    const SizedBox(height: 16),
                    SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        activeTrackColor: isIntervalEnabled
                            ? AppColors.primary
                            : AppColors.textHint,
                        inactiveTrackColor: isIntervalEnabled
                            ? AppColors.primary.withOpacity(0.2)
                            : AppColors.textHint.withOpacity(0.2),
                        thumbColor: isIntervalEnabled
                            ? AppColors.primary
                            : AppColors.textHint,
                        overlayColor: isIntervalEnabled
                            ? AppColors.primary.withOpacity(0.1)
                            : Colors.transparent,
                        trackHeight: 8,
                        thumbShape: const RoundSliderThumbShape(
                          enabledThumbRadius: 12,
                        ),
                      ),
                      child: Slider(
                        value: initialInterval,
                        min: 0,
                        max: 15, // Max 15 mins as requested
                        divisions: 15, // 1 min steps
                        onChanged: isIntervalEnabled ? onIntervalChanged : null,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '실시간',
                          style: TextStyle(color: AppColors.textHint),
                        ),
                        Text(
                          '15분',
                          style: TextStyle(color: AppColors.textHint),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
