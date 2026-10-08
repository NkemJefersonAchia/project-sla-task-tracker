import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import 'notion_style.dart';

/// A single tappable row (icon + label + optional trailing widget).
class SettingsRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final Widget? trailing;
  final bool destructive;
  final bool showChevron;

  const SettingsRow({
    super.key,
    required this.icon,
    required this.label,
    this.onTap,
    this.trailing,
    this.destructive = false,
    this.showChevron = true,
  });

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final color = destructive ? c.red : c.textPrimary;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(width: 12),
            Expanded(
              child: Text(label, style: NotionText.body.copyWith(color: color)),
            ),
            ?trailing,
            if (trailing == null && showChevron && onTap != null)
              Icon(Icons.chevron_right, size: 20, color: c.textSecondary),
          ],
        ),
      ),
    );
  }
}

/// A switch row used on the App Settings page.
class SettingsSwitchRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? description;
  final bool value;
  final ValueChanged<bool> onChanged;

  const SettingsSwitchRow({
    super.key,
    required this.icon,
    required this.label,
    this.description,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Icon(icon, size: 20, color: c.textPrimary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: NotionText.body),
                if (description != null)
                  Text(
                    description!,
                    style: NotionText.subtitle.copyWith(fontSize: 12),
                  ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: Colors.white,
            activeTrackColor: c.accent,
          ),
        ],
      ),
    );
  }
}

/// Rounded, bordered group of rows separated by thin dividers.
class SettingsSection extends StatelessWidget {
  final String? title;
  final List<Widget> children;

  const SettingsSection({super.key, this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final items = <Widget>[];
    for (var i = 0; i < children.length; i++) {
      items.add(children[i]);
      if (i != children.length - 1) {
        items.add(Divider(height: 1, thickness: 1, color: c.border));
      }
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (title != null)
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 8),
            child: Text(title!, style: NotionText.section),
          ),
        Container(
          decoration: BoxDecoration(
            color: c.surface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: c.border),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(children: items),
        ),
      ],
    );
  }
}
