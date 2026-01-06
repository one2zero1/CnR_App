import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'area_settings_screen.dart';

class GameSettingsScreen extends StatefulWidget {
  const GameSettingsScreen({super.key});

  @override
  State<GameSettingsScreen> createState() => _GameSettingsScreenState();
}

class _GameSettingsScreenState extends State<GameSettingsScreen> {
  final TextEditingController _gameNameController = TextEditingController();
  int _selectedPlayTime = 30;
  int _selectedLocationInterval = 3;
  int _selectedCaptureDistance = 5;

  @override
  void dispose() {
    _gameNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('새 게임 만들기'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildSection(
              title: '게임 이름',
              child: TextField(
                controller: _gameNameController,
                decoration: const InputDecoration(
                  hintText: '게임 이름을 입력하세요',
                  prefixIcon: Icon(Icons.games),
                ),
              ),
            ),
            const SizedBox(height: 24),
            _buildSection(
              title: '플레이 시간',
              child: _buildOptionGroup(
                options: [15, 30, 60],
                selectedValue: _selectedPlayTime,
                unit: '분',
                defaultValue: 30,
                onChanged: (value) {
                  setState(() => _selectedPlayTime = value);
                },
              ),
            ),
            const SizedBox(height: 24),
            _buildSection(
              title: '위치 공개 주기',
              description: '도둑 위치가 경찰에게 공개되는 간격',
              child: _buildOptionGroup(
                options: [1, 3, 5],
                selectedValue: _selectedLocationInterval,
                unit: '분',
                defaultValue: 3,
                onChanged: (value) {
                  setState(() => _selectedLocationInterval = value);
                },
              ),
            ),
            const SizedBox(height: 24),
            _buildSection(
              title: '포획 판정 거리',
              description: '경찰이 도둑을 잡을 수 있는 최대 거리',
              child: _buildOptionGroup(
                options: [3, 5, 10],
                selectedValue: _selectedCaptureDistance,
                unit: 'm',
                defaultValue: 5,
                onChanged: (value) {
                  setState(() => _selectedCaptureDistance = value);
                },
              ),
            ),
            const SizedBox(height: 48),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => AreaSettingsScreen(
                      gameName: _gameNameController.text.isEmpty
                          ? '새 게임'
                          : _gameNameController.text,
                      playTime: _selectedPlayTime,
                      locationInterval: _selectedLocationInterval,
                      captureDistance: _selectedCaptureDistance,
                    ),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('다음 단계', style: TextStyle(fontSize: 18)),
                  SizedBox(width: 8),
                  Icon(Icons.arrow_forward),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection({
    required String title,
    String? description,
    required Widget child,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        if (description != null) ...[
          const SizedBox(height: 4),
          Text(
            description,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
        ],
        const SizedBox(height: 12),
        child,
      ],
    );
  }

  Widget _buildOptionGroup({
    required List<int> options,
    required int selectedValue,
    required String unit,
    required int defaultValue,
    required ValueChanged<int> onChanged,
  }) {
    return Row(
      children: options.map((option) {
        final isSelected = option == selectedValue;
        final isDefault = option == defaultValue;
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(
              left: option == options.first ? 0 : 4,
              right: option == options.last ? 0 : 4,
            ),
            child: Material(
              color: isSelected ? AppColors.primary : Colors.white,
              borderRadius: BorderRadius.circular(12),
              elevation: isSelected ? 2 : 1,
              child: InkWell(
                onTap: () => onChanged(option),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Column(
                    children: [
                      Text(
                        '$option$unit',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isSelected ? Colors.white : AppColors.textPrimary,
                        ),
                      ),
                      if (isDefault) ...[
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? Colors.white.withOpacity(0.2)
                                : AppColors.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            '기본',
                            style: TextStyle(
                              fontSize: 10,
                              color: isSelected ? Colors.white : AppColors.primary,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
