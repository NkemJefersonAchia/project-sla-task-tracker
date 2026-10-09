import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../repositories/member_repository.dart';
import '../../repositories/task_repository.dart';
import '../../services/task_statistics.dart';
import '../../widgets/common/app_card.dart';
import '../../widgets/common/section_header.dart';
import 'widgets/deadline_histogram.dart';
import 'widgets/workload_bars.dart';

/// Project statistics.
///
/// ## What this screen deliberately is not
///
/// The obvious version is a column chart of the four SLA states. We already
/// show that split on the dashboard as a band, so repeating it here as bars
/// would be the same fact drawn twice - and a four-bar chart is the stock
/// graphic every task app ships.
///
/// Instead this answers three questions the dashboard cannot:
///  * Do we actually hit our deadlines? (on-time delivery)
///  * How long does work take? (average days to finish)
///  * Who is carrying it, and is anyone drowning? (workload by member)
///
/// Plus the near-term shape of the backlog, which is forward-looking where
/// everything above it is a record of what already happened.
class TaskStatisticsScreen extends StatelessWidget {
  const TaskStatisticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);

    final tasks = TaskRepository.instance.all;
    final stats = TaskStatistics.from(tasks);
    final workload = TaskStatistics.workloadByMember(
      tasks,
      MemberRepository.instance.all.map((m) => m.id).toList(),
    );

    return Scaffold(
      backgroundColor: c.canvas,
      appBar: AppBar(title: const Text('Statistics')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.screenPadding,
          AppSpacing.sm,
          AppSpacing.screenPadding,
          AppSpacing.xxl,
        ),
        children: [
          Text(
            'Delivery',
            style: AppTypography.pageTitle.copyWith(color: c.textPrimary),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Across all ${stats.total} tasks on the board.',
            style: AppTypography.caption.copyWith(color: c.textSecondary),
          ),
          const SizedBox(height: AppSpacing.xl),

          AppCard(child: _OnTimeBlock(stats: stats)),
          const SizedBox(height: AppSpacing.xl),

          SectionHeader(title: 'Workload by member'),
          AppCard(child: WorkloadBars(rows: workload)),
          const SizedBox(height: AppSpacing.xl),

          SectionHeader(title: 'The next two weeks'),
          AppCard(child: DeadlineHistogram(tasks: tasks)),
        ],
      ),
    );
  }
}

/// On-time delivery, with the average turnaround beside it.
///
/// The rate is drawn as a single horizontal gauge rather than as a ring or a
/// pair of bars: it is one proportion, and a proportion of a line is the
/// least ink that can carry it.
class _OnTimeBlock extends StatelessWidget {
  const _OnTimeBlock({required this.stats});

  final TaskStatistics stats;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final rate = stats.onTimeRate;

    if (rate == null) {
      // No completed work yet. Saying "0%" here would claim the team always
      // misses, which is a different thing from having no record.
      return Row(
        children: [
          Icon(Icons.hourglass_empty_rounded, size: 18, color: c.textTertiary),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              'No completed tasks yet, so there is no delivery record to '
              'report.',
              style: AppTypography.caption.copyWith(color: c.textSecondary),
            ),
          ),
        ],
      );
    }

    final percent = (rate * 100).round();
    final good = rate >= 0.7;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '$percent%',
              style: AppTypography.pageTitle.copyWith(
                fontSize: 40,
                color: good ? c.green : c.yellow,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text(
                  'finished on time',
                  style: AppTypography.body.copyWith(color: c.textSecondary),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),

        // The gauge: one bar, filled to the rate.
        ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.sm),
          child: SizedBox(
            height: 8,
            child: Row(
              children: [
                Expanded(
                  flex: stats.onTimeCount,
                  child: ColoredBox(
                    color: good ? c.green : c.yellow,
                    child: const SizedBox.expand(),
                  ),
                ),
                if (stats.lateCount > 0)
                  Expanded(
                    flex: stats.lateCount,
                    child: Padding(
                      padding: const EdgeInsets.only(left: 2),
                      child: ColoredBox(
                        color: c.surfaceMuted,
                        child: const SizedBox.expand(),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),

        Text(
          // The numerator and denominator spelled out, because a percentage
          // from a handful of tasks is easy to over-read.
          '${stats.onTimeCount} of ${stats.completed} completed '
          '${stats.completed == 1 ? 'task' : 'tasks'} met its deadline.',
          style: AppTypography.caption.copyWith(color: c.textSecondary),
        ),
        if (stats.averageDaysToComplete != null) ...[
          const SizedBox(height: 4),
          Text(
            'Average turnaround: '
            '${stats.averageDaysToComplete!.toStringAsFixed(1)} days from '
            'created to done.',
            style: AppTypography.caption.copyWith(color: c.textTertiary),
          ),
        ],
      ],
    );
  }
}
