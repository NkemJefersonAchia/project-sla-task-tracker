import 'package:flutter/material.dart';

import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/theme/status_colors.dart';
import '../../models/sla_status.dart';

/// The pill that communicates a task's SLA state.
///
/// Every screen renders the SLA through this one widget, so "At Risk" is the
/// same yellow with the same icon on the dashboard, in the list and on the
/// detail page. [compact] drops the icon for tight rows.
class SlaBadge extends StatelessWidget {
  const SlaBadge({
    super.key,
    required this.status,
    this.compact = false,
  });

  final SlaStatus status;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final pair = StatusColors.forSla(context, status);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? AppSpacing.sm : AppSpacing.md - 2,
        vertical: compact ? 3 : 5,
      ),
      decoration: BoxDecoration(
        color: pair.background,
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!compact) ...[
            Icon(
              StatusColors.iconForSla(status),
              size: 13,
              color: pair.foreground,
            ),
            const SizedBox(width: 5),
          ],
          Text(
            status.label,
            style: AppTypography.badge.copyWith(color: pair.foreground),
          ),
        ],
      ),
    );
  }
}

/// Generic tinted label used for priority, workflow status and category.
///
/// It is the same shape as [SlaBadge] on purpose: one badge language across
/// the app rather than four slightly different chips.
class ToneBadge extends StatelessWidget {
  const ToneBadge({
    super.key,
    required this.label,
    required this.pair,
    this.icon,
  });

  final String label;
  final ColorPair pair;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 3),
      decoration: BoxDecoration(
        color: pair.background,
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: pair.foreground),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: AppTypography.badge.copyWith(color: pair.foreground),
          ),
        ],
      ),
    );
  }
}
