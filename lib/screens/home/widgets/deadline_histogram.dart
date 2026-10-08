import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/status_colors.dart';
import '../../../models/sla_status.dart';
import '../../../models/task.dart';

/// Unfinished work plotted against the next two weeks.
///
/// The counters say how much is late. This says what is *about* to be late,
/// which is the thing you can still do something about.
///
/// ## Why it is built out of layout rather than painted
///
/// Each bar is a Container inside an Expanded, with its height set as a
/// fraction of the tallest column. No canvas, no package, no axis maths - and
/// because it is real widgets, each bar gets a tooltip and a semantics label
/// for free, which a painted chart would not.
///
/// Everything overdue is collected into one column on the left rather than
/// being dropped. A backlog chart that silently omits the late work is
/// telling you the most comfortable version of the truth.
class DeadlineHistogram extends StatelessWidget {
  const DeadlineHistogram({
    super.key,
    required this.tasks,
    this.days = 14,
    this.now,
  });

  final List<Task> tasks;

  /// How far ahead to plot. Two weeks is far enough to plan around and short
  /// enough that each column is still wide enough to touch.
  final int days;

  /// Injectable so a test can pin "today" instead of using the real clock.
  final DateTime? now;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final today = Task.dateOnly(now ?? DateTime.now());

    // Bucket 0 is everything already overdue; buckets 1..days are the days
    // ahead, so index == "days from today".
    final buckets = List<int>.filled(days + 1, 0);

    for (final task in tasks) {
      if (task.status.isComplete) continue;
      final offset = Task.dateOnly(task.dueDate).difference(today).inDays;
      if (offset < 0) {
        buckets[0]++;
      } else if (offset <= days) {
        buckets[offset + 1]++;
      }
      // Anything beyond the window is genuinely not urgent, so it is left out
      // on purpose rather than squashed into the last column.
    }

    final tallest = buckets.fold(0, (a, b) => a > b ? a : b);
    final plotted = buckets.fold(0, (sum, v) => sum + v);

    if (plotted == 0) {
      return _Quiet(
        message: 'No unfinished work due in the next $days days.',
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 92,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              for (var i = 0; i < buckets.length; i++)
                Expanded(
                  child: _Bar(
                    count: buckets[i],
                    tallest: tallest,
                    isOverdueColumn: i == 0,
                    date: i == 0 ? null : today.add(Duration(days: i - 1)),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        // A single hairline doing the job of an axis. A full set of gridlines
        // would be more ink than the data itself.
        Container(height: 1, color: c.border),
        const SizedBox(height: 6),
        Row(
          children: [
            Expanded(
              child: Text(
                'Overdue',
                style: AppTypography.badge.copyWith(color: c.textTertiary),
              ),
            ),
            Text(
              'Today',
              style: AppTypography.badge.copyWith(color: c.textTertiary),
            ),
            const Spacer(),
            Text(
              'In $days days',
              style: AppTypography.badge.copyWith(color: c.textTertiary),
            ),
          ],
        ),
      ],
    );
  }
}

/// One column. Height is a share of the tallest bar, not an absolute scale -
/// the question here is "which day is worst", not "exactly how many".
class _Bar extends StatelessWidget {
  const _Bar({
    required this.count,
    required this.tallest,
    required this.isOverdueColumn,
    required this.date,
  });

  final int count;
  final int tallest;
  final bool isOverdueColumn;
  final DateTime? date;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);

    final pair = StatusColors.forSla(
      context,
      isOverdueColumn ? SlaStatus.overdue : SlaStatus.onTrack,
    );

    final fraction = tallest == 0 ? 0.0 : count / tallest;
    // A floor so a day with one task is still visibly a bar rather than a
    // smudge against the axis.
    final height = count == 0 ? 2.0 : 10 + (fraction * 72);

    final label = isOverdueColumn
        ? '$count overdue'
        : '$count due on ${date!.day}/${date!.month}';

    return Tooltip(
      message: label,
      child: Semantics(
        label: label,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 1.5),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (count > 0)
                Padding(
                  padding: const EdgeInsets.only(bottom: 3),
                  child: Text(
                    '$count',
                    style: AppTypography.badge.copyWith(
                      color: c.textTertiary,
                      fontSize: 9,
                    ),
                  ),
                ),
              Container(
                height: height,
                decoration: BoxDecoration(
                  // An empty day is a faint tick on the axis, not a gap -
                  // it keeps the day spacing honest and even.
                  color: count == 0 ? c.border : pair.foreground,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(2),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Quiet extends StatelessWidget {
  const _Quiet({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
      child: Row(
        children: [
          Icon(Icons.event_available_outlined, size: 18, color: c.green),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              message,
              style: AppTypography.caption.copyWith(color: c.textSecondary),
            ),
          ),
        ],
      ),
    );
  }
}
