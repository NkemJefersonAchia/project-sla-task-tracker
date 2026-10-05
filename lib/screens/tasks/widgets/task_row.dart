import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/date_formatting.dart';
import '../../../models/sla_status.dart';
import '../../../models/task.dart';
import '../../../models/team_member.dart';
import '../../../services/sla_service.dart';
import '../../../widgets/common/app_card.dart';
import '../../../widgets/common/member_avatar.dart';
import '../../../widgets/task/sla_badge.dart';

/// One task as it appears in the list.
///
/// Deliberately dumb: it is handed the task and a couple of callbacks, and
/// owns no state. Every decision - what the SLA is, who the assignee is -
/// belongs to the screen above it, so this widget can be dropped into any
/// list without dragging the repositories along with it.
class TaskRow extends StatelessWidget {
  const TaskRow({
    super.key,
    required this.task,
    required this.assignee,
    required this.onTap,
    this.onToggleComplete,
  });

  final Task task;

  /// Null renders as "Unassigned" rather than crashing - a task can outlive
  /// the member it was given to.
  final TeamMember? assignee;

  final VoidCallback onTap;

  /// Flips the task between To Do and Done without leaving the list. Null
  /// hides the checkbox, so the same row can be reused read-only elsewhere.
  final VoidCallback? onToggleComplete;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);

    // Recomputed on every build rather than read off the task. The SLA is
    // never stored, so a row that was yellow yesterday turns red today
    // without anybody editing the data.
    final sla = SlaService.statusOf(task);
    final isDone = task.status.isComplete;

    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.md,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (onToggleComplete != null) ...[
            _CompletionBox(
              isDone: isDone,
              onTap: onToggleComplete!,
            ),
            const SizedBox(width: AppSpacing.md),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        task.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.bodyStrong.copyWith(
                          // Finished work recedes: lighter text with a rule
                          // through it, so a done row is legible but stops
                          // competing for attention.
                          color: isDone ? c.textTertiary : c.textPrimary,
                          decoration:
                              isDone ? TextDecoration.lineThrough : null,
                          decorationColor: c.textTertiary,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    SlaBadge(status: sla, compact: true),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    MemberAvatar(member: assignee, size: 20),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        assignee?.name ?? 'Unassigned',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.caption.copyWith(
                          color: c.textSecondary,
                        ),
                      ),
                    ),
                    _Separator(color: c.textTertiary),
                    Text(
                      DateFormatting.relativeDueDate(task.dueDate),
                      style: AppTypography.caption.copyWith(
                        // The deadline itself turns red once it is missed, so
                        // urgency survives even if the badge is skipped over.
                        color:
                            sla == SlaStatus.overdue ? c.red : c.textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// The small square Notion uses for a to-do checkbox: a thin rounded outline
/// that fills with blue once ticked.
///
/// Material's own Checkbox is larger, carries a ripple halo and sits on a 48px
/// tap target that would roughly double the height of every row.
class _CompletionBox extends StatelessWidget {
  const _CompletionBox({required this.isDone, required this.onTap});

  final bool isDone;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);

    return Semantics(
      checked: isDone,
      label: isDone ? 'Mark as not done' : 'Mark as done',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        // The padding grows the tap target past the 18px visual box, so it is
        // comfortable on a phone without making the box itself look heavy.
        child: Padding(
          padding: const EdgeInsets.all(3),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 140),
            height: 18,
            width: 18,
            decoration: BoxDecoration(
              color: isDone ? c.blue : Colors.transparent,
              borderRadius: BorderRadius.circular(AppRadius.sm),
              border: Border.all(
                color: isDone ? c.blue : c.borderStrong,
                width: 1.4,
              ),
            ),
            child: isDone
                ? const Icon(Icons.check_rounded, size: 13, color: Colors.white)
                : null,
          ),
        ),
      ),
    );
  }
}

/// The 3px dot Notion puts between inline metadata, rather than a slash or a
/// pipe. It reads as punctuation instead of as a divider.
class _Separator extends StatelessWidget {
  const _Separator({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Container(
        height: 3,
        width: 3,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      ),
    );
  }
}
