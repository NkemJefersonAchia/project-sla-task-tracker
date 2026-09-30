import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/theme/status_colors.dart';
import '../../models/sla_status.dart';

/// Proportional breakdown of every task by SLA state.
///
/// A segmented bar rather than a pie: it reads correctly at phone width, it
/// needs no chart package, and each segment is sized with [Expanded] using the
/// count as the flex factor - so the widget is pure layout, with no painting
/// maths to get wrong.
class SlaBreakdownBar extends StatelessWidget {
  const SlaBreakdownBar({
    super.key,
    required this.counts,
    this.onSegmentTap,
  });

  /// How many tasks sit in each SLA state.
  final Map<SlaStatus, int> counts;

  final void Function(SlaStatus status)? onSegmentTap;

  int get _total => counts.values.fold(0, (sum, value) => sum + value);

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final total = _total;

    // The order the states are shown in: worst first, so the eye lands on the
    // problem before the reassurance.
    const order = [
      SlaStatus.overdue,
      SlaStatus.atRisk,
      SlaStatus.onTrack,
      SlaStatus.completed,
    ];

    final present = order.where((status) => (counts[status] ?? 0) > 0).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.pill),
          child: SizedBox(
            height: 8,
            child: total == 0
                // An empty project still needs a bar, otherwise the card
                // collapses and the layout jumps once the first task is added.
                ? ColoredBox(color: c.surfaceMuted, child: const SizedBox())
                : Row(
                    children: [
                      for (final status in present)
                        Expanded(
                          flex: counts[status]!,
                          child: Padding(
                            // A hairline gap between segments keeps adjacent
                            // colours from blending into one another.
                            padding: EdgeInsets.only(
                              right: status == present.last ? 0 : 2,
                            ),
                            child: ColoredBox(
                              color:
                                  StatusColors.forSla(context, status).foreground,
                              child: const SizedBox.expand(),
                            ),
                          ),
                        ),
                    ],
                  ),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        // Legend. Wrap keeps all four entries readable even on a narrow phone.
        Wrap(
          spacing: AppSpacing.lg,
          runSpacing: AppSpacing.md,
          children: [
            for (final status in order)
              _LegendEntry(
                status: status,
                count: counts[status] ?? 0,
                total: total,
                onTap: onSegmentTap == null
                    ? null
                    : () => onSegmentTap!(status),
              ),
          ],
        ),
      ],
    );
  }
}

class _LegendEntry extends StatelessWidget {
  const _LegendEntry({
    required this.status,
    required this.count,
    required this.total,
    this.onTap,
  });

  final SlaStatus status;
  final int count;
  final int total;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final pair = StatusColors.forSla(context, status);
    final percent = total == 0 ? 0 : ((count / total) * 100).round();

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.sm),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            height: 8,
            width: 8,
            decoration: BoxDecoration(
              color: pair.foreground,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Text(
            status.label,
            style: AppTypography.caption.copyWith(color: c.textSecondary),
          ),
          const SizedBox(width: 6),
          Text(
            '$count',
            style: AppTypography.caption.copyWith(
              color: c.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 3),
          Text(
            '($percent%)',
            style: AppTypography.caption.copyWith(color: c.textTertiary),
          ),
        ],
      ),
    );
  }
}
