import 'package:flutter/material.dart';

import '../../core/constants/app_routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/theme/status_colors.dart';
import '../../core/utils/date_formatting.dart';
import '../../models/sla_status.dart';
import '../../models/task.dart';
import '../../repositories/member_repository.dart';
import '../../repositories/session_repository.dart';
import '../../repositories/task_repository.dart';
import '../../services/sla_service.dart';
import '../../widgets/common/app_card.dart';
import '../../widgets/common/empty_state.dart';
import '../../widgets/common/member_avatar.dart';
import '../../widgets/common/section_header.dart';
import '../../widgets/dashboard/metric_tile.dart';
import '../../widgets/dashboard/sla_breakdown_bar.dart';
import '../../widgets/task/task_list_tile.dart';

/// The project dashboard - the first screen after signing in.
///
/// It answers three questions in order: how is the project doing overall,
/// what needs a decision today, and what changed recently. Everything on it
/// is derived from the task list; the dashboard stores nothing of its own.
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({
    super.key,
    required this.onDataChanged,
    required this.onOpenTasks,
  });

  /// Tells the shell that the underlying data changed so the other tabs
  /// re-read it too.
  final VoidCallback onDataChanged;

  /// Jumps to the task list, optionally pre-filtered to one SLA state.
  final void Function(SlaStatus? status) onOpenTasks;

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  /// How many rows each preview section shows before it defers to the full
  /// task list.
  static const int _previewCount = 3;

  Future<void> _openTask(String taskId) async {
    await Navigator.of(context).pushNamed(
      AppRoutes.taskDetail,
      arguments: TaskDetailArgs(taskId),
    );
    // The detail screen may have edited, completed or deleted the task, so we
    // re-read once we are back on screen.
    _refresh();
  }

  Future<void> _createTask() async {
    final created = await Navigator.of(context).pushNamed<bool>(
      AppRoutes.taskForm,
      arguments: const TaskFormArgs.create(),
    );
    if (created == true) _refresh();
  }

  void _refresh() {
    if (!mounted) return;
    setState(() {});
    widget.onDataChanged();
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);

    // Read straight from the repository: it is an in-memory list, so this is
    // cheap and always current. No local copy means no risk of showing stale
    // counts after an edit on another screen.
    final tasks = TaskRepository.instance.all;
    final counts = SlaService.summarise(tasks);
    final currentUser = SessionRepository.instance.currentUser;

    final needsAttention = tasks
        .where((task) => SlaService.statusOf(task).needsAttention)
        .toList()
      ..sort((a, b) => a.dueDate.compareTo(b.dueDate));

    final recentlyUpdated = [...tasks]
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

    return Scaffold(
      backgroundColor: c.canvas,
      floatingActionButton: FloatingActionButton(
        // The dashboard and the task list are both alive inside the shell's
        // IndexedStack, so their FABs need distinct hero tags - two heroes
        // sharing the default tag throws the moment a route is pushed.
        heroTag: 'dashboard-new-task',
        onPressed: _createTask,
        backgroundColor: c.accent,
        foregroundColor: c.canvas,
        elevation: 0,
        highlightElevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        tooltip: 'New task',
        child: const Icon(Icons.add_rounded),
      ),
      body: RefreshIndicator(
        // Pull-to-refresh is not fetching anything remote - it re-reads local
        // storage. It is here because a user who suspects the screen is stale
        // will try it, and it costs one line.
        onRefresh: () async => _refresh(),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.screenPadding,
            AppSpacing.lg,
            AppSpacing.screenPadding,
            // Leaves room for the floating action button at the end of the
            // scroll, so it never covers the last task.
            AppSpacing.xxl * 2.5,
          ),
          children: [
            _Greeting(
              name: currentUser?.name.split(' ').first ?? 'there',
              role: currentUser?.role ?? '',
              avatar: MemberAvatar(member: currentUser, size: 38),
            ),
            const SizedBox(height: AppSpacing.xl),
            _MetricGrid(counts: counts, onOpenTasks: widget.onOpenTasks),
            const SizedBox(height: AppSpacing.xl),
            SectionHeader(
              title: 'Task overview',
              action: SectionAction(
                label: 'Statistics',
                icon: Icons.arrow_forward_rounded,
                onPressed: () =>
                    Navigator.of(context).pushNamed(AppRoutes.statistics),
              ),
            ),
            AppCard(
              child: SlaBreakdownBar(
                counts: counts,
                onSegmentTap: widget.onOpenTasks,
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            SectionHeader(
              title: 'Needs attention (${needsAttention.length})',
              action: needsAttention.length > _previewCount
                  ? SectionAction(
                      label: 'See all',
                      onPressed: () => widget.onOpenTasks(null),
                    )
                  : null,
            ),
            if (needsAttention.isEmpty)
              AppCard(
                child: Row(
                  children: [
                    Icon(Icons.verified_outlined, size: 18, color: c.green),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Text(
                        'Nothing is overdue or at risk. The whole board is on '
                        'schedule.',
                        style: AppTypography.caption.copyWith(
                          color: c.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              )
            else
              for (final task in needsAttention.take(_previewCount))
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: TaskListTile(
                    task: task,
                    assignee: MemberRepository.instance.byId(task.assigneeId),
                    onTap: () => _openTask(task.id),
                  ),
                ),
            const SizedBox(height: AppSpacing.xl),
            SectionHeader(title: 'Recent activity'),
            if (recentlyUpdated.isEmpty)
              EmptyState(
                icon: Icons.inbox_outlined,
                title: 'No tasks yet',
                message: 'Create the first task to start tracking the project.',
              )
            else
              AppCard(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.xs,
                ),
                child: Column(
                  children: [
                    for (final task
                        in recentlyUpdated.take(_previewCount).toList())
                      _ActivityRow(
                        task: task,
                        isLast: task == recentlyUpdated
                            .take(_previewCount)
                            .toList()
                            .last,
                        onTap: () => _openTask(task.id),
                      ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// "Good morning, Amara" plus the signed-in member's avatar.
class _Greeting extends StatelessWidget {
  const _Greeting({
    required this.name,
    required this.role,
    required this.avatar,
  });

  final String name;
  final String role;
  final Widget avatar;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                DateFormatting.greeting(),
                style: AppTypography.caption.copyWith(color: c.textTertiary),
              ),
              const SizedBox(height: 2),
              Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.pageTitle.copyWith(color: c.textPrimary),
              ),
              if (role.isNotEmpty)
                Text(
                  role,
                  style: AppTypography.caption.copyWith(
                    color: c.textSecondary,
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        avatar,
      ],
    );
  }
}

/// The 2x2 block of counters.
///
/// A [GridView] would need its own scroll handling inside the page's
/// ListView, so two plain Rows are simpler here and give exact control over
/// the gaps.
///
/// Each row is wrapped in an [IntrinsicHeight] so its two tiles end up the
/// same height. `CrossAxisAlignment.stretch` on its own cannot do that here:
/// inside a scrolling ListView the vertical constraint is unbounded, and
/// stretching to an unbounded height throws.
class _MetricGrid extends StatelessWidget {
  const _MetricGrid({required this.counts, required this.onOpenTasks});

  final Map<SlaStatus, int> counts;
  final void Function(SlaStatus? status) onOpenTasks;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final total = counts.values.fold(0, (sum, value) => sum + value);

    // Describing the four tiles as data keeps the layout below to two
    // symmetrical rows instead of four near-identical blocks of widget code.
    final tiles = <Widget>[
      MetricTile(
        value: total,
        label: 'Total tasks',
        icon: Icons.layers_outlined,
        pair: ColorPair(c.textPrimary, c.surfaceMuted),
        onTap: () => onOpenTasks(null),
      ),
      for (final status in [
        SlaStatus.onTrack,
        SlaStatus.atRisk,
        SlaStatus.overdue,
      ])
        MetricTile(
          value: counts[status] ?? 0,
          label: status.label,
          icon: StatusColors.iconForSla(status),
          pair: StatusColors.forSla(context, status),
          onTap: () => onOpenTasks(status),
        ),
    ];

    return Column(
      children: [
        _MetricRow(left: tiles[0], right: tiles[1]),
        const SizedBox(height: AppSpacing.md),
        _MetricRow(left: tiles[2], right: tiles[3]),
      ],
    );
  }
}

class _MetricRow extends StatelessWidget {
  const _MetricRow({required this.left, required this.right});

  final Widget left;
  final Widget right;

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(child: left),
          const SizedBox(width: AppSpacing.md),
          Expanded(child: right),
        ],
      ),
    );
  }
}

/// A compact "X was updated N hours ago" row.
class _ActivityRow extends StatelessWidget {
  const _ActivityRow({
    required this.task,
    required this.isLast,
    required this.onTap,
  });

  final Task task;
  final bool isLast;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final assignee = MemberRepository.instance.byId(task.assigneeId);

    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
        decoration: BoxDecoration(
          border: isLast
              ? null
              : Border(bottom: BorderSide(color: c.border)),
        ),
        child: Row(
          children: [
            MemberAvatar(member: assignee, size: 26),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    task.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.caption.copyWith(
                      color: c.textPrimary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    '${assignee?.name.split(' ').first ?? 'Someone'} · '
                    '${task.status.label}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.caption.copyWith(
                      color: c.textTertiary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Text(
              DateFormatting.timeAgo(task.updatedAt),
              style: AppTypography.caption.copyWith(color: c.textTertiary),
            ),
          ],
        ),
      ),
    );
  }
}
