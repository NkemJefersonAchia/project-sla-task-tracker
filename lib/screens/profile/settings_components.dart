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
