import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/theme/status_colors.dart';
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

/// Called when the user taps a counter. [filter] is the SLA state to show on
/// the Tasks tab, or null for "all tasks".
typedef OpenTasksCallback = void Function(SlaStatus? filter);

/// The Home tab - the project dashboard.
///
/// Answers one question the moment the app opens: is this project in trouble,
/// and if so where. It is a summary plus a way in, not another task list:
///  * a greeting for the signed-in member,
///  * four counters (total, On Track, At Risk, Overdue) that each open the
///    Tasks tab filtered to that state,
///  * a short "needs attention" list of overdue and at-risk work.
///
/// Everything is read from the repositories inside [build]. `HomeShell`
/// rebuilds its tabs whenever the user switches tab, so the numbers are
/// current every time the dashboard is shown.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key, this.onOpenTasks});

  /// How the dashboard asks the shell to switch to the Tasks tab. Optional so
  /// the screen still builds on its own; counters are simply not tappable
  /// until the shell passes this in.
  final OpenTasksCallback? onOpenTasks;

  /// The "needs attention" list is a nudge, not a second task list.
  static const int _maxAttentionRows = 4;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);

    final tasks = TaskRepository.instance.all;
    final counts = SlaService.summarise(tasks);
    final attention = _attentionItems(tasks);
    final shown = attention.take(_maxAttentionRows).toList();

    VoidCallback? opener(SlaStatus? filter) =>
        onOpenTasks == null ? null : () => onOpenTasks!(filter);

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.screenPadding,
          AppSpacing.xl,
          AppSpacing.screenPadding,
          AppSpacing.xl,
        ),
        children: [
          _GreetingHeader(attentionCount: attention.length),
          const SizedBox(height: AppSpacing.xl),

          // Counters, two per row.
          Row(
            children: [
              Expanded(
                child: _CounterTile(
                  label: 'Total tasks',
                  count: tasks.length,
                  icon: Icons.layers_outlined,
                  iconColor: c.textSecondary,
                  onTap: opener(null),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(child: _slaTile(context, SlaStatus.onTrack, counts, opener)),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(child: _slaTile(context, SlaStatus.atRisk, counts, opener)),
              const SizedBox(width: AppSpacing.md),
              Expanded(child: _slaTile(context, SlaStatus.overdue, counts, opener)),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),

          // Needs attention.
          SectionHeader(
            title: 'Needs attention',
            action: onOpenTasks == null
                ? null
                : SectionAction(
                    label: 'All tasks',
                    icon: Icons.chevron_right_rounded,
                    onPressed: () => onOpenTasks!(null),
                  ),
          ),
          if (shown.isEmpty)
            const EmptyState(
              icon: Icons.check_circle_outline_rounded,
              title: 'All clear',
              message: 'Nothing is overdue or at risk right now.',
            )
          else
            for (final item in shown) ...[
              _AttentionRow(item: item),
              const SizedBox(height: AppSpacing.sm),
            ],
          if (attention.length > shown.length)
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.xs),
              child: Text(
                '+${attention.length - shown.length} more on the Tasks tab',
                style: AppTypography.caption.copyWith(color: c.textTertiary),
              ),
            ),
        ],
      ),
    );
  }

  Widget _slaTile(
    BuildContext context,
    SlaStatus status,
    Map<SlaStatus, int> counts,
    VoidCallback? Function(SlaStatus?) opener,
  ) {
    return _CounterTile(
      label: status.label,
      count: counts[status] ?? 0,
      icon: StatusColors.iconForSla(status),
      iconColor: StatusColors.forSla(context, status).foreground,
      onTap: opener(status),
    );
  }

  /// Overdue and at-risk tasks, soonest deadline first. Overdue work has the
  /// earliest deadlines, so it sorts to the top without extra rules.
  static List<_AttentionItem> _attentionItems(List<Task> tasks) {
    final items = <_AttentionItem>[];
    for (final task in tasks) {
      final evaluation = SlaService.evaluate(task);
      if (evaluation.status.needsAttention) {
        items.add(_AttentionItem(task, evaluation));
      }
    }
    items.sort((a, b) {
      final byDate = a.task.dueDate.compareTo(b.task.dueDate);
      return byDate != 0 ? byDate : a.task.title.compareTo(b.task.title);
    });
    return items;
  }
}

class _AttentionItem {
  const _AttentionItem(this.task, this.evaluation);

  final Task task;
  final SlaEvaluation evaluation;
}

class _GreetingHeader extends StatelessWidget {
  const _GreetingHeader({required this.attentionCount});

  final int attentionCount;

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final user = SessionRepository.instance.currentUser;
    final firstName = user == null || user.name.trim().isEmpty
        ? null
        : user.name.trim().split(RegExp(r'\s+')).first;

    final summary = attentionCount == 0
        ? 'Everything is on schedule.'
        : attentionCount == 1
            ? '1 task needs attention.'
            : '$attentionCount tasks need attention.';

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                firstName == null ? _greeting() : '${_greeting()}, $firstName',
                style: AppTypography.bodyStrong.copyWith(
                  fontSize: 22,
                  color: c.textPrimary,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                summary,
                style: AppTypography.caption.copyWith(color: c.textSecondary),
              ),
            ],
          ),
        ),
        if (user != null) ...[
          const SizedBox(width: AppSpacing.md),
          MemberAvatar(member: user, size: 36),
        ],
      ],
    );
  }
}

class _CounterTile extends StatelessWidget {
  const _CounterTile({
    required this.label,
    required this.count,
    required this.icon,
    required this.iconColor,
    required this.onTap,
  });

  final String label;
  final int count;
  final IconData icon;
  final Color iconColor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);

    return Semantics(
      button: onTap != null,
      label: '$count $label',
      excludeSemantics: true,
      child: AppCard(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 20, color: iconColor),
            const SizedBox(height: AppSpacing.md),
            Text(
              '$count',
              style: AppTypography.bodyStrong.copyWith(
                fontSize: 26,
                height: 1.1,
                color: c.textPrimary,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              label,
              style: AppTypography.caption.copyWith(color: c.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}

class _AttentionRow extends StatelessWidget {
  const _AttentionRow({required this.item});

  final _AttentionItem item;

  String _dueText(int daysRemaining) {
    if (daysRemaining < 0) {
      final late = daysRemaining.abs();
      return late == 1 ? '1 day overdue' : '$late days overdue';
    }
    if (daysRemaining == 0) return 'Due today';
    if (daysRemaining == 1) return 'Due tomorrow';
    return 'Due in $daysRemaining days';
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final member = MemberRepository.instance.byId(item.task.assigneeId);

    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: [
          MemberAvatar(member: member, size: 28),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.task.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.bodyStrong.copyWith(
                    color: c.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${member?.name ?? 'Unassigned'} · '
                  '${_dueText(item.evaluation.daysRemaining)}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.caption.copyWith(
                    color: c.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          _SlaChip(status: item.evaluation.status),
        ],
      ),
    );
  }
}

/// A compact status pill. If the project's `SlaBadge` fits this spot, it can
/// replace this widget - both read their colours from [StatusColors].
class _SlaChip extends StatelessWidget {
  const _SlaChip({required this.status});

  final SlaStatus status;

  @override
  Widget build(BuildContext context) {
    final pair = StatusColors.forSla(context, status);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: pair.background,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(StatusColors.iconForSla(status), size: 12, color: pair.foreground),
          const SizedBox(width: AppSpacing.xs),
          Text(
            status.label,
            style: AppTypography.badge.copyWith(color: pair.foreground),
          ),
        ],
      ),
    );
  }
}