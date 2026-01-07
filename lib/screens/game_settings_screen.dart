import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/game_types.dart';
import 'area_settings_screen.dart';

class GameSettingsScreen extends StatefulWidget {
  const GameSettingsScreen({super.key});

  @override
  State<GameSettingsScreen> createState() => _GameSettingsScreenState();
}

class _GameSettingsScreenState extends State<GameSettingsScreen> {
  final TextEditingController _gameNameController = TextEditingController();
  double _playTime = 30;
  double _locationInterval = 3;
  RoleAssignmentMethod _roleMethod = RoleAssignmentMethod.manual;

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
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        '10분',
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                      Text(
                        '${_playTime.toInt()}분',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                      const Text(
                        '60분',
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                  Slider(
                    value: _playTime,
                    min: 10,
                    max: 60,
                    divisions: 10,
                    label: '${_playTime.toInt()}분',
                    activeColor: AppColors.primary,
                    onChanged: (value) {
                      setState(() => _playTime = value);
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            _buildSection(
              title: '위치 공개 주기',
              description: '도둑 위치가 경찰에게 공개되는 간격',
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        '실시간',
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                      Text(
                        _locationInterval == 0
                            ? '실시간'
                            : '${_locationInterval.toInt()}분',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                      const Text(
                        '10분',
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                  Slider(
                    value: _locationInterval,
                    min: 0,
                    max: 10,
                    divisions: 10,
                    label: _locationInterval == 0
                        ? '실시간'
                        : '${_locationInterval.toInt()}분',
                    activeColor: AppColors.primary,
                    onChanged: (value) {
                      setState(() => _locationInterval = value);
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            _buildSection(
              title: '역할 설정 방식',
              description: '플레이어 역할을 어떻게 정할지 선택하세요',
              child: Column(
                children: [
                  RadioListTile<RoleAssignmentMethod>(
                    title: const Text('자율 (플레이어가 직접 선택)'),
                    value: RoleAssignmentMethod.manual,
                    groupValue: _roleMethod,
                    onChanged: (value) => setState(() => _roleMethod = value!),
                    activeColor: AppColors.primary,
                  ),
                  RadioListTile<RoleAssignmentMethod>(
                    title: const Text('지정 (방장이 설정)'),
                    value: RoleAssignmentMethod.host,
                    groupValue: _roleMethod,
                    onChanged: (value) => setState(() => _roleMethod = value!),
                    activeColor: AppColors.primary,
                  ),
                  RadioListTile<RoleAssignmentMethod>(
                    title: const Text('랜덤 (게임 시작 시 자동 배정)'),
                    value: RoleAssignmentMethod.random,
                    groupValue: _roleMethod,
                    onChanged: (value) => setState(() => _roleMethod = value!),
                    activeColor: AppColors.primary,
                  ),
                ],
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
                      playTime: _playTime.toInt(),
                      locationInterval: _locationInterval.toInt(),
                      roleMethod: _roleMethod,
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
}
