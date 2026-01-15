import 'package:flutter/material.dart';
import '../../../theme/app_theme.dart';
import '../../../models/game_types.dart';

class Step4Roles extends StatelessWidget {
  final RoleAssignmentMethod initialMethod;
  final ValueChanged<RoleAssignmentMethod> onMethodChanged;

  const Step4Roles({
    super.key,
    required this.initialMethod,
    required this.onMethodChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.people, size: 60, color: AppColors.primary),
          ),
          const SizedBox(height: 32),
          Text(
            '역할 배정 방식',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            '플레이어들의 역할을 어떻게 정할지\n선택하세요.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: theme.textTheme.bodyMedium?.color,
            ),
          ),
          const SizedBox(height: 48),
          _buildRoleOption(
            context,
            title: '자율 선택',
            subtitle: '플레이어가 직접 경찰/도둑을 선택합니다.',
            icon: Icons.touch_app,
            value: RoleAssignmentMethod.manual,
          ),
          const SizedBox(height: 16),
          _buildRoleOption(
            context,
            title: '방장 지정',
            subtitle: '방장이 모든 플레이어의 역할을 정합니다.',
            icon: Icons.admin_panel_settings,
            value: RoleAssignmentMethod.host,
            isComingSoon:
                true, // Example: Mark Host method as coming soon in UI logic elsewhere
          ),
          const SizedBox(height: 16),
          _buildRoleOption(
            context,
            title: '랜덤 배정',
            subtitle: '게임 시작 시 무작위로 역할이 정해집니다.',
            icon: Icons.shuffle,
            value: RoleAssignmentMethod.random,
            isComingSoon: true,
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildRoleOption(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required RoleAssignmentMethod value,
    bool isComingSoon = false,
  }) {
    final theme = Theme.of(context);
    final isSelected = initialMethod == value;

    return InkWell(
      onTap: () => onMethodChanged(value),
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withOpacity(0.05)
              : theme.cardTheme.color,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? AppColors.primary
                : theme.disabledColor.withOpacity(0.2),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: [
            if (!isSelected)
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primary
                    : theme.scaffoldBackgroundColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: isSelected ? Colors.white : theme.iconTheme.color,
                size: 24,
              ),
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
                      color: isSelected
                          ? AppColors.primary
                          : theme.colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 14,
                      color: theme.textTheme.bodyMedium?.color,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              const Icon(Icons.check_circle, color: AppColors.primary),
            if (isComingSoon &&
                !isSelected) // Just visual indicator if needed, but logic currently allows selection
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Theme.of(context).disabledColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '준비중',
                  style: TextStyle(
                    fontSize: 10,
                    color: Theme.of(context).disabledColor,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
