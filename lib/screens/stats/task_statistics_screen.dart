import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../models/task_status.dart';
import '../../repositories/task_repository.dart';
import '../../services/sla_service.dart';
import '../../widgets/common/app_card.dart';
import '../../widgets/common/section_header.dart';
import '../../widgets/common/unbuilt_feature_notice.dart';
import '../../widgets/dashboard/sla_breakdown_bar.dart';

/// Project statistics.
///
/// ## Status: scaffolded, not finished - work stream A (see the README)
///
/// The screen exists, is routable and already renders the two things that
/// needed no new logic: the SLA split and the workflow counts. What is left
/// is the analysis the assignment brief asks for, and every input it needs is
/// already available:
///
///  * `SlaService.summarise(tasks)` - counts per SLA state
///  * `Task.completedAt` vs `Task.dueDate` - whether work landed on time
///  * `TaskRepository.byAssignee(id)` - per-member workload
///
/// The TODOs below say what to build with them. Nothing here needs a chart
/// package: `SlaBreakdownBar` shows how far plain layout widgets go.
class TaskStatisticsScreen extends StatelessWidget {
  const TaskStatisticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);

    final tasks = TaskRepository.instance.all;
    final slaCounts = SlaService.summarise(tasks);

    // Counts per workflow status. Built here rather than in a service because
    // this is the only screen that needs it - if a second screen ever does,
    // it moves into SlaService next to summarise().
    final statusCounts = {
      for (final status in TaskStatus.values)
        status: tasks.where((task) => task.status == status).length,
    };

    return Scaffold(
      backgroundColor: c.canvas,
      appBar: AppBar(title: const Text('Statistics')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.screenPadding,
          AppSpacing.md,
          AppSpacing.screenPadding,
          AppSpacing.xxl,
        ),
        children: [
          Text(
            'Project statistics',
            style: AppTypography.pageTitle.copyWith(color: c.textPrimary),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Across all ${tasks.length} tasks on the board.',
            style: AppTypography.caption.copyWith(color: c.textSecondary),
          ),
          const SizedBox(height: AppSpacing.xl),

          SectionHeader(title: 'SLA split'),
          AppCard(child: SlaBreakdownBar(counts: slaCounts)),
          const SizedBox(height: AppSpacing.xl),

          SectionHeader(title: 'Workflow'),
          AppCard(
            child: Column(
              children: [
                for (final entry in statusCounts.entries)
                  _StatusRow(
                    label: entry.key.label,
                    count: entry.value,
                    total: tasks.length,
                    isLast: entry.key == TaskStatus.values.last,
                  ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),

          SectionHeader(title: 'Still to build'),
          const UnbuiltFeatureNotice(
            title: 'This screen is a scaffold',
            message: 'Work stream A. The three analyses below are the '
                'remaining work; the data they need is already exposed by '
                'the repository and SlaService.',
          ),
          const SizedBox(height: AppSpacing.md),
          const _TodoCard(
            title: 'On-time delivery rate',
            detail: 'Of the tasks that are Done, what share had completedAt '
                'on or before dueDate. Show it as a percentage with the '
                'numerator and denominator underneath.',
          ),
          const SizedBox(height: AppSpacing.sm),
          const _TodoCard(
            title: 'Workload by member',
            detail: 'One horizontal bar per member using byAssignee(id), '
                'segmented by SLA state. SlaBreakdownBar can be reused '
                'almost as-is.',
          ),
          const SizedBox(height: AppSpacing.sm),
          const _TodoCard(
            title: 'Upcoming deadlines',
            detail: 'The next five incomplete tasks sorted by dueDate, each '
                'with its SLA badge. TaskListTile already renders the row.',
          ),
        ],
      ),
    );
  }
}

/// A label, a proportional bar and a count - the simplest honest chart.
class _StatusRow extends StatelessWidget {
  const _StatusRow({
    required this.label,
    required this.count,
    required this.total,
    required this.isLast,
  });

  final String label;
  final int count;
  final int total;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final fraction = total == 0 ? 0.0 : count / total;

    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : AppSpacing.md),
      child: Row(
        children: [
          SizedBox(
            width: 86,
            child: Text(
              label,
              style: AppTypography.caption.copyWith(color: c.textSecondary),
            ),
          ),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.pill),
              child: LinearProgressIndicator(
                // A progress bar used as a proportion bar: no animation, no
                // package, and it already handles the zero case.
                value: fraction,
                minHeight: 6,
                backgroundColor: c.surfaceMuted,
                valueColor: AlwaysStoppedAnimation(c.textSecondary),
              ),
            ),
          ),
          SizedBox(
            width: 32,
            child: Text(
              '$count',
              textAlign: TextAlign.right,
              style: AppTypography.caption.copyWith(
                color: c.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// A single outstanding piece of work, written out in the UI so the gap is
/// visible in the running app and not only in the source.
class _TodoCard extends StatelessWidget {
  const _TodoCard({required this.title, required this.detail});

  final String title;
  final String detail;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);

    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.crop_square_rounded, size: 16, color: c.textTertiary),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTypography.caption.copyWith(
                    color: c.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  detail,
                  style: AppTypography.caption.copyWith(
                    color: c.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
