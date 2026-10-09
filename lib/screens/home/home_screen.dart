import 'package:flutter/material.dart';

import '../../core/constants/app_routes.dart';
import '../../core/navigation/tasks_filter_bridge.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/theme/status_colors.dart';
import '../../core/utils/date_formatting.dart';
import '../../models/sla_status.dart';
import '../../models/task.dart';
import '../../repositories/session_repository.dart';
import '../../repositories/task_repository.dart';
import '../../services/sla_service.dart';
import '../../widgets/common/app_card.dart';
import '../../widgets/common/member_avatar.dart';
import '../../widgets/common/section_header.dart';
import 'widgets/agenda_section.dart';
import 'widgets/sla_health_strip.dart';

/// The Home tab: an agenda, not a scoreboard.
///
/// ## The shape of this screen, and why
///
/// The obvious dashboard is a grid of counters over a donut chart. We built
/// that first and then replaced it, for two reasons.
///
/// It did not answer the question. "3 at risk" tells you a number; it does
/// not tell you which tasks, so every reading ended in a trip to the task
/// list anyway. And four counter cards plus a ring filled a phone screen
/// entirely, so the work itself started below the fold - a dashboard you have
/// to scroll past to reach your tasks is in the way.
///
/// What replaced it:
///  * One headline number - how much needs you - with the whole project's SLA
///    split as a single band underneath. One card, one line of chart.
///  * The work itself, grouped by when it is due: Overdue, Today, This week.
///
/// The counts still exist, in the group headings, where they label something
/// you can act on rather than floating in a card of their own.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
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

    // Read from the repository on every build. The buckets are derived, never
    // stored, so completing a task anywhere moves them with no message
    // passing between tabs.
    final tasks = TaskRepository.instance.all;
    final counts = SlaService.summarise(tasks);
    final buckets = _AgendaBuckets.from(tasks);

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

            _HeadlineCard(
              needsAttention: buckets.needsAttentionCount,
              counts: counts,
              onSegmentTap: TasksFilterBridge.request,
            ),
            const SizedBox(height: AppSpacing.xl),

            SectionHeader(
              title: 'Your agenda',
              action: SectionAction(
                label: 'Statistics',
                icon: Icons.arrow_forward_rounded,
                onPressed: () =>
                    Navigator.of(context).pushNamed(AppRoutes.statistics),
              ),
            ),

            AgendaSection(
              title: 'Overdue',
              tasks: buckets.overdue,
              accent: StatusColors.forSla(context, SlaStatus.overdue)
                  .foreground,
              onTaskTap: _openTask,
            ),
            AgendaSection(
              title: 'Due today',
              tasks: buckets.today,
              accent: StatusColors.forSla(context, SlaStatus.atRisk)
                  .foreground,
              onTaskTap: _openTask,
              // Worth saying out loud - an empty day is good news, and a
              // silent gap would read as a rendering fault.
              emptyNote: 'Nothing due today.',
            ),
            AgendaSection(
              title: 'This week',
              tasks: buckets.thisWeek,
              accent: StatusColors.forSla(context, SlaStatus.onTrack)
                  .foreground,
              onTaskTap: _openTask,
            ),

            if (buckets.isEmpty) _AllClear(),
          ],
        ),
      ),
    );
  }
}

/// Splits unfinished work into the three buckets the agenda shows.
///
/// Kept as a small value object rather than three filters inline, so the
/// rules live in one place and the screen stays a layout.
class _AgendaBuckets {
  const _AgendaBuckets({
    required this.overdue,
    required this.today,
    required this.thisWeek,
  });

  final List<Task> overdue;
  final List<Task> today;
  final List<Task> thisWeek;

  int get needsAttentionCount => overdue.length + today.length;

  bool get isEmpty => overdue.isEmpty && today.isEmpty && thisWeek.isEmpty;

  factory _AgendaBuckets.from(List<Task> tasks, {DateTime? now}) {
    final today = Task.dateOnly(now ?? DateTime.now());

    final overdueList = <Task>[];
    final todayList = <Task>[];
    final weekList = <Task>[];

    for (final task in tasks) {
      // Finished work has no place on an agenda; it is history, and the
      // statistics screen is where history belongs.
      if (task.status.isComplete) continue;

      final days = Task.dateOnly(task.dueDate).difference(today).inDays;
      if (days < 0) {
        overdueList.add(task);
      } else if (days == 0) {
        todayList.add(task);
      } else if (days <= 7) {
        weekList.add(task);
      }
      // Anything past a week is not on this week's agenda. The Tasks tab has
      // the full list; this screen is deliberately the near horizon.
    }

    int byDueDate(Task a, Task b) => a.dueDate.compareTo(b.dueDate);
    overdueList.sort(byDueDate);
    todayList.sort(byDueDate);
    weekList.sort(byDueDate);

    return _AgendaBuckets(
      overdue: overdueList,
      today: todayList,
      thisWeek: weekList,
    );
  }
}

/// The one prominent number on the screen, with the SLA band under it.
///
/// A single headline rather than four competing tiles: if everything is
/// emphasised, nothing is. The other counts are still present in the band's
/// labels, one size down, which is where they belong.
class _HeadlineCard extends StatelessWidget {
  const _HeadlineCard({
    required this.needsAttention,
    required this.counts,
    required this.onSegmentTap,
  });

  final int needsAttention;
  final Map<SlaStatus, int> counts;
  final void Function(SlaStatus status) onSegmentTap;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final clear = needsAttention == 0;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                '$needsAttention',
                style: AppTypography.pageTitle.copyWith(
                  fontSize: 40,
                  color: clear ? c.green : c.textPrimary,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(
                  clear
                      ? 'Nothing needs you today.'
                      : needsAttention == 1
                          ? 'task needs you today'
                          : 'tasks need you today',
                  style: AppTypography.body.copyWith(color: c.textSecondary),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          SlaHealthStrip(counts: counts, onSegmentTap: onSegmentTap),
        ],
      ),
    );
  }
}

/// Shown when there is genuinely nothing on the near horizon.
class _AllClear extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);

    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.lg),
      child: Row(
        children: [
          Icon(Icons.wb_sunny_outlined, size: 18, color: c.green),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              'No unfinished work due in the next seven days.',
              style: AppTypography.caption.copyWith(color: c.textSecondary),
            ),
          ),
        ],
      ),
    );
  }
}

/// "Good afternoon / Amara / Project Manager", with the avatar on the right.
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
