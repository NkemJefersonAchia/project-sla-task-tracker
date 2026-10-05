import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/theme/status_colors.dart';
import '../../core/utils/date_formatting.dart';
import '../../models/sla_status.dart';
import '../../repositories/member_repository.dart';
import '../../repositories/task_repository.dart';
import '../../services/sla_service.dart';
import '../../widgets/common/member_avatar.dart';
import '../../widgets/common/property_row.dart';
import '../../widgets/task/sla_badge.dart';

/// Everything about one task.
///
/// The screen is given a task **id**, not a Task. It re-reads the object from
/// the repository on every build, so an edit made on the form screen is
/// already reflected by the time we pop back here - there is no copy to go
/// stale.
class TaskDetailScreen extends StatefulWidget {
  const TaskDetailScreen({super.key, required this.taskId});

  final String taskId;

  @override
  State<TaskDetailScreen> createState() => _TaskDetailScreenState();
}

class _TaskDetailScreenState extends State<TaskDetailScreen> {
  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final task = TaskRepository.instance.byId(widget.taskId);
    final assignee = MemberRepository.instance.byId(task?.assigneeId);
    final sla = task == null ? null : SlaService.evaluate(task);

    return Scaffold(
      backgroundColor: c.canvas,
      appBar: AppBar(title: const Text('Task')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.screenPadding,
          AppSpacing.sm,
          AppSpacing.screenPadding,
          AppSpacing.xxl,
        ),
        children: [
          if (task!.category.isNotEmpty) ...[
            // The category sits above the title as a quiet label rather than
            // beside it - the same place Notion puts a page's parent.
            ToneBadge(
              label: task.category,
              pair: ColorPair(c.textSecondary, c.surfaceMuted),
            ),
            const SizedBox(height: AppSpacing.md),
          ],
          Text(
            task.title,
            style: AppTypography.pageTitle.copyWith(color: c.textPrimary),
          ),
          if (task.description.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            Text(
              task.description,
              style: AppTypography.body.copyWith(color: c.textSecondary),
            ),
          ],
          const SizedBox(height: AppSpacing.xl),
          Divider(color: c.border),
          const SizedBox(height: AppSpacing.sm),

          // The property block. A fixed-width label column means the rows
          // line up into a clean vertical rule, which is what makes this read
          // as a record rather than as loose text.
          PropertyRow(
            icon: Icons.person_outline_rounded,
            label: 'Assignee',
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                MemberAvatar(member: assignee, size: 22),
                const SizedBox(width: AppSpacing.sm),
                Flexible(
                  child: Text(
                    assignee?.name ?? 'Unassigned',
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.caption.copyWith(
                      color: c.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          PropertyRow(
            icon: Icons.event_outlined,
            label: 'Due date',
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  DateFormatting.full(task.dueDate),
                  style: AppTypography.caption.copyWith(color: c.textPrimary),
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  // The exact date and the human reading of it, together: one
                  // is unambiguous, the other is the one you actually act on.
                  DateFormatting.relativeDueDate(task.dueDate),
                  style: AppTypography.caption.copyWith(
                    color: sla!.status == SlaStatus.overdue
                        ? c.red
                        : c.textTertiary,
                  ),
                ),
              ],
            ),
          ),
          PropertyRow(
            icon: Icons.flag_outlined,
            label: 'Priority',
            child: ToneBadge(
              label: task.priority.label,
              pair: StatusColors.forPriority(context, task.priority),
            ),
          ),
          PropertyRow(
            icon: Icons.donut_large_outlined,
            label: 'Status',
            child: ToneBadge(
              label: task.status.label,
              pair: StatusColors.forTaskStatus(context, task.status),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Divider(color: c.border),
        ],
      ),
    );
  }
}
