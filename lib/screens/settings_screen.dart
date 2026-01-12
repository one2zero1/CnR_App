import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../theme/app_sizes.dart';
import '../config/app_strings.dart';
import '../providers/theme_provider.dart';

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
        title: const Text(AppStrings.settingsTitle),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView(
        children: [
          _buildSectionHeader(AppStrings.settingsScreen),
          Consumer<ThemeProvider>(
            builder: (context, themeProvider, child) {
              return Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSizes.paddingMedium,
                ),
                child: Column(
                  children: [
                    RadioListTile<ThemeMode>(
                      title: const Text(AppStrings.settingsSystem),
                      value: ThemeMode.system,
                      groupValue: themeProvider.themeMode,
                      onChanged: (value) => themeProvider.setThemeMode(value!),
                      contentPadding: EdgeInsets.zero,
                    ),
                    RadioListTile<ThemeMode>(
                      title: const Text(AppStrings.settingsLight),
                      value: ThemeMode.light,
                      groupValue: themeProvider.themeMode,
                      onChanged: (value) => themeProvider.setThemeMode(value!),
                      contentPadding: EdgeInsets.zero,
                    ),
                    RadioListTile<ThemeMode>(
                      title: const Text(AppStrings.settingsDark),
                      value: ThemeMode.dark,
                      groupValue: themeProvider.themeMode,
                      onChanged: (value) => themeProvider.setThemeMode(value!),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ],
                ),
              );
            },
          ),
          const Divider(),
          _buildSectionHeader(AppStrings.settingsNotifications),
          _buildSwitchTile(
            title: AppStrings.notifLocationTitle,
            subtitle: AppStrings.notifLocationSub,
            value: _locationNotification,
            onChanged: (value) {
              setState(() => _locationNotification = value);
            },
          ),
          _buildSwitchTile(
            title: AppStrings.notifCaptureTitle,
            subtitle: AppStrings.notifCaptureSub,
            value: _captureNotification,
            onChanged: (value) {
              setState(() => _captureNotification = value);
            },
          ),
          _buildSwitchTile(
            title: AppStrings.notifChatTitle,
            subtitle: AppStrings.notifChatSub,
            value: _chatNotification,
            onChanged: (value) {
              setState(() => _chatNotification = value);
            },
          ),
          const Divider(),
          _buildSectionHeader(AppStrings.settingsMap),
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSizes.paddingMedium,
              vertical: AppSizes.paddingSmall,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  AppStrings.mapStyle,
                  style: TextStyle(fontSize: 16, color: AppColors.textPrimary),
                ),
                const SizedBox(height: AppSizes.spaceMedium),
                Row(
                  children: [
                    _buildMapStyleButton(AppStrings.mapStyleNormal, 'normal'),
                    const SizedBox(width: AppSizes.spaceMedium),
                    _buildMapStyleButton(
                      AppStrings.mapStyleSatellite,
                      'satellite',
                    ),
                  ],
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(AppSizes.paddingMedium),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      AppStrings.gpsAccuracy,
                      style: TextStyle(
                        fontSize: 16,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      _gpsAccuracy < 0.3
                          ? AppStrings.gpsLow
                          : _gpsAccuracy > 0.7
                          ? AppStrings.gpsHigh
                          : AppStrings.gpsNormal,
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
                    Text(
                      AppStrings.battery,
                      style: TextStyle(fontSize: 12, color: AppColors.textHint),
                    ),
                    Text(
                      AppStrings.accuracy,
                      style: TextStyle(fontSize: 12, color: AppColors.textHint),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(),
          _buildSectionHeader(AppStrings.settingsBattery),
          _buildSwitchTile(
            title: AppStrings.powerSave,
            subtitle: AppStrings.powerSaveSub,
            value: _powerSaveMode,
            onChanged: (value) {
              setState(() => _powerSaveMode = value);
            },
          ),
          const Divider(),
          _buildSectionHeader(AppStrings.settingsAccount),
          ListTile(
            leading: const Icon(Icons.edit),
            title: const Text(AppStrings.changeNickname),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () => _showNicknameDialog(),
          ),
          ListTile(
            leading: const Icon(Icons.logout, color: AppColors.danger),
            title: const Text(
              AppStrings.logout,
              style: TextStyle(color: AppColors.danger),
            ),
            onTap: () => _showLogoutDialog(),
          ),
          const Divider(),
          _buildSectionHeader(AppStrings.settingsAppInfo),
          const ListTile(
            leading: Icon(Icons.info_outline),
            title: Text(AppStrings.version),
            trailing: Text(
              '1.0.0',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.help_outline),
            title: const Text(AppStrings.tutorialRestart),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {},
          ),
          ListTile(
            leading: const Icon(Icons.description_outlined),
            title: const Text(AppStrings.terms),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {},
          ),
          ListTile(
            leading: const Icon(Icons.privacy_tip_outlined),
            title: const Text(AppStrings.privacy),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {},
          ),
          const SizedBox(height: AppSizes.spaceXLarge),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSizes.paddingMedium,
        AppSizes.paddingMedium,
        AppSizes.paddingMedium,
        AppSizes.paddingSmall,
      ),
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
        color: isSelected ? AppColors.primary : AppColors.surface,
        borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
        elevation: isSelected ? 2 : 1,
        child: InkWell(
          onTap: () {
            setState(() => _mapStyle = value);
          },
          borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
          child: Container(
            padding: const EdgeInsets.symmetric(
              vertical: AppSizes.paddingMedium,
            ), // Was 12, closest is medium 16 or small 8. 12 is AppSizes.spaceMedium. Using spaceMedium for padding is fine or use paddingMedium. Original was 12. Let's use paddingMedium (16) or create padding12? I'll use spaceMedium (12) for padding here or define a new one. AppSizes.spaceMedium is 12.0.
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isSelected ? AppColors.surface : AppColors.textPrimary,
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
        title: const Text(AppStrings.changeNicknameTitle),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: AppStrings.newNicknameHint,
          ),
          maxLength: 8,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(AppStrings.cancel),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text(AppStrings.nicknameChanged)),
              );
            },
            child: const Text(AppStrings.change),
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(AppStrings.logoutTitle),
        content: const Text(AppStrings.logoutContent),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(AppStrings.cancel),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
            child: const Text(AppStrings.logoutTitle),
          ),
        ],
      ),
    );
  }
}
