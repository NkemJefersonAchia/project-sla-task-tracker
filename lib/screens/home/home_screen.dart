import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/theme/status_colors.dart';
import '../../core/utils/date_formatting.dart';
import '../../models/sla_status.dart';
import '../../core/constants/app_routes.dart';
import '../../core/navigation/tasks_filter_bridge.dart';
import '../../repositories/member_repository.dart';
import '../../repositories/session_repository.dart';
import '../../repositories/task_repository.dart';
import '../../services/sla_service.dart';
import '../../widgets/common/app_card.dart';
import '../../widgets/common/member_avatar.dart';
import '../../widgets/common/section_header.dart';
import 'widgets/deadline_histogram.dart';
import 'widgets/metric_tile.dart';
import '../tasks/widgets/task_row.dart';
import 'widgets/sla_ring_chart.dart';

/// The Home tab: the dashboard.
///
/// It answers one question the moment the app opens - is this project in
/// trouble, and if so where. It is the only screen that looks across every
/// task at once, so it is a summary and a way in, not another task list.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  /// How many rows the attention list shows before deferring to the Tasks
  /// tab. This is a summary; a fifth row would make it a second task list.
  static const int _previewCount = 3;

  Future<void> _openTask(String taskId) async {
    await Navigator.of(context).pushNamed(
      AppRoutes.taskDetail,
      arguments: TaskDetailArgs(taskId),
    );
    // The detail screen can edit or delete, so re-read on the way back.
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final me = SessionRepository.instance.currentUser;

    // Read straight from the repository on every build. The counts are
    // derived, never stored, so completing a task on another tab moves them
    // without this screen being told anything.
    final tasks = TaskRepository.instance.all;
    final counts = SlaService.summarise(tasks);

    // Overdue and at-risk work, soonest deadline first.
    final needsAttention =
        tasks.where((t) => SlaService.statusOf(t).needsAttention).toList()
          ..sort((a, b) => a.dueDate.compareTo(b.dueDate));

    return Scaffold(
      backgroundColor: c.canvas,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.screenPadding,
            AppSpacing.lg,
            AppSpacing.screenPadding,
            AppSpacing.xxl,
          ),
          children: [
            _Greeting(
              name: me?.name.split(' ').first ?? 'there',
              role: me?.role ?? '',
              avatar: MemberAvatar(member: me, size: 38),
            ),
            const SizedBox(height: AppSpacing.xl),
            _MetricGrid(total: tasks.length, counts: counts),
            const SizedBox(height: AppSpacing.xl),
            SectionHeader(title: 'Project health'),
            AppCard(child: SlaRingChart(counts: counts)),
            const SizedBox(height: AppSpacing.xl),
            SectionHeader(title: 'The next two weeks'),
            AppCard(child: DeadlineHistogram(tasks: tasks)),
            const SizedBox(height: AppSpacing.xl),
            SectionHeader(title: 'Needs attention (${needsAttention.length})'),
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
                  child: TaskRow(
                    task: task,
                    assignee: MemberRepository.instance.byId(task.assigneeId),
                    onTap: () => _openTask(task.id),
                  ),
                ),
          ],
        ),
      ),
    );
  }
}

/// The 2x2 block of counters.
///
/// Two plain Rows rather than a GridView, which would need its own scroll
/// handling inside the page's ListView. Each row is wrapped in an
/// IntrinsicHeight so its two tiles match height - `CrossAxisAlignment.stretch`
/// alone cannot do that here, because a ListView gives its children unbounded
/// vertical space and stretching to infinity throws.
class _MetricGrid extends StatelessWidget {
  const _MetricGrid({required this.total, required this.counts});

  final int total;
  final Map<SlaStatus, int> counts;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);

    final tiles = <Widget>[
      MetricTile(
        value: total,
        label: 'Total tasks',
        icon: Icons.layers_outlined,
        pair: ColorPair(c.textPrimary, c.surfaceMuted),
        onTap: () => TasksFilterBridge.request(null),
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
          onTap: () => TasksFilterBridge.request(status),
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

/// "Good afternoon / Amara / Project Manager", with the avatar on the right.
///
/// The time-of-day greeting is the one piece of warmth on an otherwise
/// factual screen, and it doubles as confirmation of who you are signed in
/// as - which matters on a shared demo device.
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
