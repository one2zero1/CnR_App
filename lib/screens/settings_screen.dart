import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../theme/app_sizes.dart';
import '../config/app_strings.dart';
import '../providers/theme_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/auth_service.dart';
import 'tutorial_screen.dart'; // Import TutorialScreen
import '../config/legal_strings.dart';
import 'common_text_screen.dart';

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
  // String _mapStyle = 'normal'; // Removed
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
          Consumer<ThemeProvider>(
            builder: (context, themeProvider, child) {
              return _buildSwitchTile(
                title: AppStrings.visibilityMode,
                subtitle: AppStrings.visibilityModeSub,
                value: themeProvider.isVisibilityMode,
                onChanged: (value) => themeProvider.toggleVisibilityMode(value),
              );
            },
          ),
          // _buildSectionHeader(AppStrings.settingsMap), // Removed Map Style Selection
          Padding(
            padding: const EdgeInsets.all(AppSizes.paddingMedium),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      AppStrings.gpsAccuracy,
                      style: TextStyle(
                        fontSize: 16,
                        color: Theme.of(context).textTheme.bodyLarge?.color,
                      ),
                    ),
                    Text(
                      _gpsAccuracy < 0.3
                          ? AppStrings.gpsLow
                          : _gpsAccuracy > 0.7
                          ? AppStrings.gpsHigh
                          : AppStrings.gpsNormal,
                      style: TextStyle(
                        fontSize: 14,
                        color: Theme.of(context).textTheme.bodyMedium?.color,
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
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      AppStrings.battery,
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).hintColor,
                      ),
                    ),
                    Text(
                      AppStrings.accuracy,
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).hintColor,
                      ),
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
          ListTile(
            leading: Icon(Icons.info_outline),
            title: Text(AppStrings.version),
            trailing: Text(
              '1.0.0',
              style: TextStyle(
                color: Theme.of(context).textTheme.bodyMedium?.color,
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.help_outline),
            title: const Text(AppStrings.tutorialRestart),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const TutorialScreen()),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.description_outlined),
            title: const Text(AppStrings.terms),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const CommonTextScreen(
                    title: AppStrings.terms,
                    content: LegalStrings.termsOfService,
                  ),
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.privacy_tip_outlined),
            title: const Text(AppStrings.privacy),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const CommonTextScreen(
                    title: AppStrings.privacy,
                    content: LegalStrings.privacyPolicy,
                  ),
                ),
              );
            },
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
        style: TextStyle(
          fontSize: 12,
          color: Theme.of(context).textTheme.bodyMedium?.color,
        ),
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

  // _buildMapStyleButton removed

  void _showNicknameDialog() {
    final authService = context.read<AuthService>();
    final currentNickname = authService.currentUser?.nickname ?? '';
    final controller = TextEditingController(text: currentNickname);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        bool isLoading = false;
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text(AppStrings.changeNicknameTitle),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: controller,
                    enabled: !isLoading,
                    decoration: const InputDecoration(
                      hintText: AppStrings.newNicknameHint,
                    ),
                    maxLength: 8,
                  ),
                  if (isLoading)
                    const Padding(
                      padding: EdgeInsets.only(top: 16),
                      child: CircularProgressIndicator(),
                    ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: isLoading ? null : () => Navigator.pop(context),
                  child: const Text(AppStrings.cancel),
                ),
                ElevatedButton(
                  onPressed: isLoading
                      ? null
                      : () async {
                          final newNickname = controller.text.trim();
                          if (newNickname.isEmpty) return;

                          setState(() => isLoading = true);

                          try {
                            await authService.updateProfile(
                              nickname: newNickname,
                            );

                            // Save to SharedPreferences for auto-login
                            final prefs = await SharedPreferences.getInstance();
                            await prefs.setString('KEY_NICKNAME', newNickname);

                            if (context.mounted) {
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(AppStrings.nicknameChanged),
                                ),
                              );
                            }
                          } catch (e) {
                            setState(() => isLoading = false);
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    '${AppStrings.errorGeneric}: $e',
                                  ),
                                ),
                              );
                            }
                          }
                        },
                  child: const Text(AppStrings.change),
                ),
              ],
            );
          },
        );
      },
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
