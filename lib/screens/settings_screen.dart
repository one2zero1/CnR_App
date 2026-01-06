import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _locationNotification = true;
  bool _captureNotification = true;
  bool _chatNotification = true;
  bool _powerSaveMode = false;
  String _mapStyle = 'normal';
  double _gpsAccuracy = 0.5;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('설정'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView(
        children: [
          _buildSectionHeader('알림'),
          _buildSwitchTile(
            title: '위치 공개 알림',
            subtitle: '도둑 위치가 공개될 때 알림',
            value: _locationNotification,
            onChanged: (value) {
              setState(() => _locationNotification = value);
            },
          ),
          _buildSwitchTile(
            title: '포획 알림',
            subtitle: '도둑이 잡혔을 때 알림',
            value: _captureNotification,
            onChanged: (value) {
              setState(() => _captureNotification = value);
            },
          ),
          _buildSwitchTile(
            title: '채팅 알림',
            subtitle: '새로운 채팅 메시지 알림',
            value: _chatNotification,
            onChanged: (value) {
              setState(() => _chatNotification = value);
            },
          ),
          const Divider(),
          _buildSectionHeader('지도'),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '지도 스타일',
                  style: TextStyle(
                    fontSize: 16,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _buildMapStyleButton('일반', 'normal'),
                    const SizedBox(width: 12),
                    _buildMapStyleButton('위성', 'satellite'),
                  ],
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'GPS 정확도',
                      style: TextStyle(
                        fontSize: 16,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      _gpsAccuracy < 0.3
                          ? '낮음 (배터리 절약)'
                          : _gpsAccuracy > 0.7
                              ? '높음 (정확도 우선)'
                              : '보통',
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                Slider(
                  value: _gpsAccuracy,
                  onChanged: (value) {
                    setState(() => _gpsAccuracy = value);
                  },
                  activeColor: AppColors.primary,
                ),
                const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('배터리', style: TextStyle(fontSize: 12, color: AppColors.textHint)),
                    Text('정확도', style: TextStyle(fontSize: 12, color: AppColors.textHint)),
                  ],
                ),
              ],
            ),
          ),
          const Divider(),
          _buildSectionHeader('배터리'),
          _buildSwitchTile(
            title: '절전 모드',
            subtitle: 'GPS 업데이트 주기를 줄여 배터리 절약',
            value: _powerSaveMode,
            onChanged: (value) {
              setState(() => _powerSaveMode = value);
            },
          ),
          const Divider(),
          _buildSectionHeader('계정'),
          ListTile(
            leading: const Icon(Icons.edit),
            title: const Text('닉네임 변경'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () => _showNicknameDialog(),
          ),
          ListTile(
            leading: const Icon(Icons.logout, color: AppColors.danger),
            title: const Text(
              '로그아웃',
              style: TextStyle(color: AppColors.danger),
            ),
            onTap: () => _showLogoutDialog(),
          ),
          const Divider(),
          _buildSectionHeader('앱 정보'),
          const ListTile(
            leading: Icon(Icons.info_outline),
            title: Text('버전'),
            trailing: Text('1.0.0', style: TextStyle(color: AppColors.textSecondary)),
          ),
          ListTile(
            leading: const Icon(Icons.help_outline),
            title: const Text('튜토리얼 다시 보기'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {},
          ),
          ListTile(
            leading: const Icon(Icons.description_outlined),
            title: const Text('이용약관'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {},
          ),
          ListTile(
            leading: const Icon(Icons.privacy_tip_outlined),
            title: const Text('개인정보 처리방침'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {},
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: AppColors.primary,
        ),
      ),
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return SwitchListTile(
      title: Text(title),
      subtitle: Text(
        subtitle,
        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
      ),
      value: value,
      onChanged: onChanged,
      activeTrackColor: AppColors.primary.withOpacity(0.5),
      thumbColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return AppColors.primary;
        }
        return null;
      }),
    );
  }

  Widget _buildMapStyleButton(String label, String value) {
    final isSelected = _mapStyle == value;
    return Expanded(
      child: Material(
        color: isSelected ? AppColors.primary : Colors.white,
        borderRadius: BorderRadius.circular(8),
        elevation: isSelected ? 2 : 1,
        child: InkWell(
          onTap: () {
            setState(() => _mapStyle = value);
          },
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isSelected ? Colors.white : AppColors.textPrimary,
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showNicknameDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('닉네임 변경'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: '새 닉네임 입력',
          ),
          maxLength: 8,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('닉네임이 변경되었습니다')),
              );
            },
            child: const Text('변경'),
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('로그아웃'),
        content: const Text('정말 로그아웃 하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.danger,
            ),
            child: const Text('로그아웃'),
          ),
        ],
      ),
    );
  }
}
