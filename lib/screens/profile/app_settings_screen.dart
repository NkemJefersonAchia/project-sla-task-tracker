import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/theme_controller.dart';
import 'notion_style.dart';
import 'settings_components.dart';

class AppSettingsScreen extends StatefulWidget {
  const AppSettingsScreen({super.key});

  @override
  State<AppSettingsScreen> createState() => _AppSettingsScreenState();
}

class _AppSettingsScreenState extends State<AppSettingsScreen> {
  bool _push = true;
  bool _email = false;
  bool _slaAlerts = true;
  bool _dueReminders = true;
  String _language = 'English';

  Future<void> _pickLanguage() async {
    final choice = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: AppColors.of(context).surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final l in ['English', 'Kinyarwanda', 'Français'])
              ListTile(
                title: Text(l, style: NotionText.body),
                trailing: l == _language
                    ? Icon(Icons.check, color: AppColors.of(context).accent)
                    : null,
                onTap: () => Navigator.pop(ctx, l),
              ),
          ],
        ),
      ),
    );
    if (choice != null) setState(() => _language = choice);
  }

  Future<void> _setTheme(ThemeMode mode) async {
    await ThemeController.instance.setMode(mode);
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Scaffold(
      backgroundColor: c.canvas,
      appBar: notionAppBar(context, title: 'App Settings'),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            SettingsSection(
              title: 'Appearance',
              children: [
                SettingsRow(
                  icon: Icons.light_mode_outlined,
                  label: 'Light mode',
                  showChevron: false,
                  onTap: () => _setTheme(ThemeMode.light),
                  trailing: ThemeController.instance.value == ThemeMode.light
                      ? Icon(Icons.check, color: c.accent)
                      : null,
                ),
                SettingsRow(
                  icon: Icons.dark_mode_outlined,
                  label: 'Dark mode',
                  showChevron: false,
                  onTap: () => _setTheme(ThemeMode.dark),
                  trailing: ThemeController.instance.value == ThemeMode.dark
                      ? Icon(Icons.check, color: c.accent)
                      : null,
                ),
              ],
            ),
            const SizedBox(height: 24),
            SettingsSection(
              title: 'Notifications',
              children: [
                SettingsSwitchRow(
                  icon: Icons.notifications_none,
                  label: 'Push notifications',
                  value: _push,
                  onChanged: (v) => setState(() => _push = v),
                ),
                SettingsSwitchRow(
                  icon: Icons.mail_outline,
                  label: 'Email notifications',
                  value: _email,
                  onChanged: (v) => setState(() => _email = v),
                ),
                SettingsSwitchRow(
                  icon: Icons.warning_amber_rounded,
                  label: 'SLA breach alerts',
                  description: 'Tell me when a task is about to breach',
                  value: _slaAlerts,
                  onChanged: (v) => setState(() => _slaAlerts = v),
                ),
                SettingsSwitchRow(
                  icon: Icons.event_outlined,
                  label: 'Due date reminders',
                  value: _dueReminders,
                  onChanged: (v) => setState(() => _dueReminders = v),
                ),
              ],
            ),
            const SizedBox(height: 24),
            SettingsSection(
              title: 'General',
              children: [
                SettingsRow(
                  icon: Icons.language,
                  label: 'Language',
                  onTap: _pickLanguage,
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _language,
                        style: NotionText.subtitle.copyWith(
                          color: c.textSecondary,
                        ),
                      ),
                      Icon(
                        Icons.chevron_right,
                        size: 20,
                        color: c.textSecondary,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
