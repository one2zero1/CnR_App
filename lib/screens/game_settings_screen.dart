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
    final theme = Theme.of(context);

    return Scaffold(
      // backgroundColor: const Color(0xFFF5F5F5), // Removed
      appBar: AppBar(
        title: Text(
          '새 게임 만들기',
          style: TextStyle(color: theme.colorScheme.onSurface),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: theme.colorScheme.onSurface),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildSectionCard(
              title: '게임 이름',
              icon: Icons.games,
              child: TextField(
                controller: _gameNameController,
                decoration: InputDecoration(
                  hintText: '게임 이름을 입력하세요',
                  filled: true,
                  fillColor:
                      theme.inputDecorationTheme.fillColor ?? Colors.grey[100],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            _buildSectionCard(
              title: '플레이 시간',
              icon: Icons.timer,
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('10분', style: TextStyle(color: Colors.grey)),
                      Text(
                        '${_playTime.toInt()}분',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                      const Text('60분', style: TextStyle(color: Colors.grey)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      activeTrackColor: AppColors.primary,
                      inactiveTrackColor: AppColors.primary.withOpacity(0.2),
                      thumbColor: AppColors.primary,
                      overlayColor: AppColors.primary.withOpacity(0.1),
                      trackHeight: 6,
                      thumbShape: const RoundSliderThumbShape(
                        enabledThumbRadius: 10,
                      ),
                    ),
                    child: Slider(
                      value: _playTime,
                      min: 10,
                      max: 60,
                      divisions: 5,
                      onChanged: (value) => setState(() => _playTime = value),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            _buildSectionCard(
              title: '위치 공개 주기',
              icon: Icons.location_on,
              description: '도둑의 위치가 경찰에게 공개되는 간격입니다.',
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('실시간', style: TextStyle(color: Colors.grey)),
                      Text(
                        _locationInterval == 0
                            ? '실시간'
                            : '${_locationInterval.toInt()}분',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                      const Text('10분', style: TextStyle(color: Colors.grey)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      activeTrackColor: AppColors.primary,
                      inactiveTrackColor: AppColors.primary.withOpacity(0.2),
                      thumbColor: AppColors.primary,
                      overlayColor: AppColors.primary.withOpacity(0.1),
                      trackHeight: 6,
                      thumbShape: const RoundSliderThumbShape(
                        enabledThumbRadius: 10,
                      ),
                    ),
                    child: Slider(
                      value: _locationInterval,
                      min: 0,
                      max: 10,
                      divisions: 10,
                      onChanged: (value) =>
                          setState(() => _locationInterval = value),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            _buildSectionCard(
              title: '역할 배정 방식',
              icon: Icons.person_search,
              description: '플레이어의 역할을 어떻게 정할지 선택하세요.',
              child: Column(
                children: [
                  _buildRoleSelectionCard(
                    title: '자율 선택',
                    subtitle: '플레이어가 경찰/도둑을 직접 선택합니다.',
                    value: RoleAssignmentMethod.manual,
                    icon: Icons.touch_app,
                  ),
                  const SizedBox(height: 12),
                  _buildRoleSelectionCard(
                    title: '방장 지정',
                    subtitle: '방장이 모든 플레이어의 역할을 지정합니다.',
                    value: RoleAssignmentMethod.host,
                    icon: Icons.admin_panel_settings,
                  ),
                  const SizedBox(height: 12),
                  _buildRoleSelectionCard(
                    title: '랜덤 배정',
                    subtitle: '게임 시작 시 무작위로 역할이 배정됩니다.',
                    value: RoleAssignmentMethod.random,
                    icon: Icons.shuffle,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: const LinearGradient(
                  colors: [AppColors.primary, AppColors.primaryDark],
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: ElevatedButton(
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
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '다음 단계로 이동',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(width: 8),
                    Icon(Icons.arrow_forward_rounded, color: Colors.white),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    String? description,
    required Widget child,
  }) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: AppColors.primary, size: 24),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ],
          ),
          if (description != null) ...[
            const SizedBox(height: 8),
            Text(
              description,
              style: TextStyle(
                fontSize: 14,
                color: theme.textTheme.bodyMedium?.color ?? Colors.grey[600],
              ),
            ),
          ],
          const SizedBox(height: 20),
          child,
        ],
      ),
    );
  }

  Widget _buildRoleSelectionCard({
    required String title,
    required String subtitle,
    required RoleAssignmentMethod value,
    required IconData icon,
  }) {
    final theme = Theme.of(context);
    final isSelected = _roleMethod == value;
    return InkWell(
      onTap: () => setState(() => _roleMethod = value),
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withOpacity(0.05)
              : theme.cardTheme.color ?? Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? AppColors.primary
                : theme.disabledColor.withOpacity(0.3),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected
                  ? AppColors.primary
                  : theme.iconTheme.color?.withOpacity(0.5) ?? Colors.grey,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: isSelected
                          ? AppColors.primary
                          : theme.colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color:
                          theme.textTheme.bodyMedium?.color ?? Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              const Icon(Icons.check_circle, color: AppColors.primary),
          ],
        ),
      ),
    );
  }
}
