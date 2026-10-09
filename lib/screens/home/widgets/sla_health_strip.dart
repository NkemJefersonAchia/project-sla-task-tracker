import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/status_colors.dart';
import '../../../models/sla_status.dart';

/// The whole project's SLA split as a single horizontal band.
///
/// ## Why a band and not a donut
///
/// A ring puts the proportions in a circle, which forces a separate legend
/// beside it to carry the numbers - and a ring plus a boxed legend is the
/// stock dashboard graphic every task app ships with.
///
/// A band reads left to right like a sentence, so the labels can sit directly
/// under the segment they describe and no legend is needed. It also costs one
/// line of vertical space instead of a 124px square, which on a phone is the
/// difference between seeing your tasks and scrolling to find them.
///
/// Each segment is an [Expanded] with the count as its flex factor, so the
/// widths are exact and there is no painting maths to get wrong.
class SlaHealthStrip extends StatelessWidget {
  const SlaHealthStrip({
    super.key,
    required this.counts,
    this.onSegmentTap,
  });

  /// Task count per state, from `SlaService.summarise`.
  final Map<SlaStatus, int> counts;

  /// Tapping a segment or its label opens the task list filtered to it.
  final void Function(SlaStatus status)? onSegmentTap;

  /// Worst first, so the band reads from trouble to safety.
  static const List<SlaStatus> _order = [
    SlaStatus.overdue,
    SlaStatus.atRisk,
    SlaStatus.onTrack,
    SlaStatus.completed,
  ];

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final total = counts.values.fold(0, (sum, value) => sum + value);
    final present = _order.where((s) => (counts[s] ?? 0) > 0).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.sm),
          child: SizedBox(
            height: 10,
            child: total == 0
                // An empty project still shows the band, so the card cannot
                // collapse and shift everything under it.
                ? ColoredBox(color: c.surfaceMuted, child: const SizedBox())
                : Row(
                    children: [
                      for (final status in present)
                        Expanded(
                          flex: counts[status]!,
                          child: Padding(
                            // A hairline of canvas between segments, so two
                            // adjacent colours stay separate without outlining
                            // every one of them.
                            padding: EdgeInsets.only(
                              right: status == present.last ? 0 : 2,
                            ),
                            child: ColoredBox(
                              color: StatusColors.forSla(context, status)
                                  .foreground,
                              child: const SizedBox.expand(),
                            ),
                          ),
                        ),
                    ],
                  ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        // Labels on one line under the band. Four of them fit across a phone
        // at this size, which is what lets the legend box disappear.
        Row(
          children: [
            for (final status in _order)
              Expanded(
                child: _Label(
                  status: status,
                  count: counts[status] ?? 0,
                  onTap: onSegmentTap == null
                      ? null
                      : () => onSegmentTap!(status),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _Label extends StatelessWidget {
  const _Label({required this.status, required this.count, this.onTap});

  final SlaStatus status;
  final int count;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final pair = StatusColors.forSla(context, status);
    final empty = count == 0;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.sm),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  height: 6,
                  width: 6,
                  decoration: BoxDecoration(
                    color: empty ? c.border : pair.foreground,
                    borderRadius: BorderRadius.circular(1.5),
                  ),
                ),
                const SizedBox(width: 5),
                Text(
                  '$count',
                  style: AppTypography.bodyStrong.copyWith(
                    color: empty ? c.textTertiary : c.textPrimary,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 1),
            Text(
              status.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.badge.copyWith(
                color: c.textTertiary,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
