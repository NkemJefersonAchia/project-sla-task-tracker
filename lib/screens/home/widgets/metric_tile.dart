import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/status_colors.dart';

/// One counter on the dashboard: a number, a label, and a quiet icon.
///
/// Tinted with the SLA pair it represents, so the four tiles carry the same
/// colour language as every badge in the app. Tapping one is a shortcut into
/// the task list already filtered to that state - a dashboard that reports
/// three overdue tasks without helping you reach them is half a feature.
class MetricTile extends StatelessWidget {
  const MetricTile({
    super.key,
    required this.value,
    required this.label,
    required this.icon,
    required this.pair,
    this.onTap,
  });

  final int value;
  final String label;
  final IconData icon;
  final ColorPair pair;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);

    return Material(
      color: pair.background,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md + 2),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 18, color: pair.foreground),
              const SizedBox(height: AppSpacing.md),
              Text(
                '$value',
                style: AppTypography.metric.copyWith(color: pair.foreground),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.caption.copyWith(
                  color: c.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
