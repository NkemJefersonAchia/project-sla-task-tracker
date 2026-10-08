import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import 'notion_style.dart';
import 'settings_components.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Scaffold(
      backgroundColor: c.canvas,
      appBar: notionAppBar(context, title: 'About'),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const SizedBox(height: 8),
            Center(
              child: Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: c.grayBg,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(Icons.task_alt, size: 36, color: c.textPrimary),
              ),
            ),
            const SizedBox(height: 16),
            Center(
              child: Text(
                'Project & SLA Task Tracker',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: c.textPrimary,
                ),
              ),
            ),
            const SizedBox(height: 4),
            Center(child: Text('Version 1.0.0', style: NotionText.subtitle)),
            const SizedBox(height: 24),
            Text(
              'A mobile task tracker for small software development teams. '
              'Manage project tasks, assign responsibilities, set deadlines, '
              'track progress, and spot tasks that need attention before '
              'they breach their SLA.',
              style: TextStyle(fontSize: 15, height: 1.5, color: c.textPrimary),
            ),
            const SizedBox(height: 28),
            SettingsSection(
              children: [
                SettingsRow(
                  icon: Icons.description_outlined,
                  label: 'Open source licenses',
                  onTap: () => showLicensePage(
                    context: context,
                    applicationName: 'Project & SLA Task Tracker',
                    applicationVersion: '1.0.0',
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
