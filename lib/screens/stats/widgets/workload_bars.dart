import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/status_colors.dart';
import '../../../models/sla_status.dart';
import '../../../repositories/member_repository.dart';
import '../../../widgets/common/member_avatar.dart';

/// Who is carrying what, one row per person.
///
/// ## Why rows and not a grouped column chart
///
/// A grouped bar chart would put four bars per member side by side and need
/// a legend to say which is which - on a phone that is sixteen bars and a
/// key, for five people.
///
/// One horizontal bar per person, segmented by SLA state, reads top to
/// bottom like a list of names, which is how you actually scan a team. Rows
/// are ordered by pressure rather than alphabetically, so whoever is most
/// overloaded is the first thing you see.
///
/// Built from Expanded flex factors rather than a canvas, so the widths are
/// exact and each row stays a normal widget with real text in it.
class WorkloadBars extends StatelessWidget {
  const WorkloadBars({super.key, required this.rows});

  /// (memberId, counts per SLA state), already ordered.
  final List<MapEntry<String, Map<SlaStatus, int>>> rows;

  /// Completed work is deliberately absent. This chart answers "how much is
  /// on each person's plate right now", and finished tasks are not on it -
  /// including them made every bar the same length, because everybody had
  /// the same lifetime total.
  static const List<SlaStatus> _order = [
    SlaStatus.overdue,
    SlaStatus.atRisk,
    SlaStatus.onTrack,
  ];

  /// Open tasks only, which is what the bars are scaled against.
  static int openCount(Map<SlaStatus, int> counts) =>
      _order.fold(0, (sum, s) => sum + (counts[s] ?? 0));

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);

    if (rows.isEmpty) {
      return Text(
        'No team members yet.',
        style: AppTypography.caption.copyWith(color: c.textTertiary),
      );
    }

    // Every row is scaled against the busiest person's open load, so bar
    // length compares across people instead of each row filling its width.
    final busiest = rows.fold<int>(0, (max, row) {
      final open = openCount(row.value);
      return open > max ? open : max;
    });

    return Column(
      children: [
        for (var i = 0; i < rows.length; i++)
          _Row(
            memberId: rows[i].key,
            counts: rows[i].value,
            busiest: busiest,
            isLast: i == rows.length - 1,
          ),
      ],
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({
    required this.memberId,
    required this.counts,
    required this.busiest,
    required this.isLast,
  });

  final String memberId;
  final Map<SlaStatus, int> counts;
  final int busiest;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final member = MemberRepository.instance.byId(memberId);

    final open = WorkloadBars.openCount(counts);
    final present =
        WorkloadBars._order.where((s) => (counts[s] ?? 0) > 0).toList();

    // The share of the row's width this person's bar should occupy.
    final share = busiest == 0 ? 0.0 : open / busiest;

    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              MemberAvatar(member: member, size: 22),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  member?.name ?? 'Unassigned',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.caption.copyWith(color: c.textPrimary),
                ),
              ),
              Text(
                open == 1 ? '1 open' : '$open open',
                style: AppTypography.badge.copyWith(
                  color: c.textTertiary,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          // LayoutBuilder so the bar can be a true fraction of the row width;
          // a FractionallySizedBox inside a Row would need a fixed parent.
          LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth * share;

              return Stack(
                children: [
                  // The full-width track shows what "busiest" looks like, so
                  // a short bar reads as light load rather than as a bug.
                  Container(
                    height: 8,
                    decoration: BoxDecoration(
                      color: c.surfaceMuted,
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                    ),
                  ),
                  if (open > 0)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                      child: SizedBox(
                        height: 8,
                        width: width,
                        child: Row(
                          children: [
                            for (final status in present)
                              Expanded(
                                flex: counts[status]!,
                                child: Padding(
                                  padding: EdgeInsets.only(
                                    right: status == present.last ? 0 : 1.5,
                                  ),
                                  child: ColoredBox(
                                    color: StatusColors.forSla(
                                      context,
                                      status,
                                    ).foreground,
                                    child: const SizedBox.expand(),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}
