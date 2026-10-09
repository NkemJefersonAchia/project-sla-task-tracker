import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../models/task.dart';
import '../../../repositories/member_repository.dart';
import '../../tasks/widgets/task_row.dart';

/// One time bucket on the dashboard - "Overdue", "Today", "This week".
///
/// ## Why the dashboard is an agenda
///
/// A wall of counters tells you there are three tasks at risk. It does not
/// tell you which, or what to do, so every reading of it ends in a trip to
/// the task list anyway. Grouping the actual work by when it is due answers
/// the count and the question behind it in the same glance.
///
/// The count still appears - in the heading, where it labels a group you can
/// immediately act on rather than floating in a card of its own.
class AgendaSection extends StatelessWidget {
  const AgendaSection({
    super.key,
    required this.title,
    required this.tasks,
    required this.onTaskTap,
    required this.accent,
    this.emptyNote,
    this.maxRows = 3,
  });

  final String title;
  final List<Task> tasks;
  final void Function(String taskId) onTaskTap;

  /// Colours the rule beside the heading, so the three groups are
  /// distinguishable without reading the words.
  final Color accent;

  /// Shown instead of rows when the bucket is empty. Null hides the whole
  /// section - an empty "Today" is worth saying, an empty "This week" is not.
  final String? emptyNote;

  final int maxRows;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);

    if (tasks.isEmpty && emptyNote == null) return const SizedBox.shrink();

    final shown = tasks.take(maxRows).toList();
    final hidden = tasks.length - shown.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.md),
          child: Row(
            children: [
              // A short coloured rule instead of an icon. It marks the group
              // without adding another glyph to a screen that already has
              // badges doing that job.
              Container(
                height: 14,
                width: 3,
                decoration: BoxDecoration(
                  color: accent,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                title.toUpperCase(),
                style: AppTypography.overline.copyWith(color: c.textSecondary),
              ),
              const SizedBox(width: 6),
              Text(
                '${tasks.length}',
                style: AppTypography.overline.copyWith(color: c.textTertiary),
              ),
            ],
          ),
        ),
        if (shown.isEmpty)
          Padding(
            padding: const EdgeInsets.only(
              left: AppSpacing.md,
              bottom: AppSpacing.lg,
            ),
            child: Text(
              emptyNote!,
              style: AppTypography.caption.copyWith(color: c.textTertiary),
            ),
          )
        else ...[
          for (final task in shown)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: TaskRow(
                task: task,
                assignee: MemberRepository.instance.byId(task.assigneeId),
                onTap: () => onTaskTap(task.id),
              ),
            ),
          if (hidden > 0)
            Padding(
              padding: const EdgeInsets.only(
                left: AppSpacing.md,
                bottom: AppSpacing.md,
              ),
              child: Text(
                hidden == 1 ? '1 more' : '$hidden more',
                style: AppTypography.caption.copyWith(color: c.textTertiary),
              ),
            ),
          const SizedBox(height: AppSpacing.sm),
        ],
      ],
    );
  }
}
