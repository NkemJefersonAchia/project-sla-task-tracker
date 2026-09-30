import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/date_formatting.dart';
import '../../models/sla_status.dart';
import '../../models/task.dart';
import '../../models/team_member.dart';
import '../../services/sla_service.dart';
import '../common/app_card.dart';
import '../common/member_avatar.dart';
import 'sla_badge.dart';

/// One task as it appears in a list.
///
/// Two lines and one badge: the title with its SLA state, then who owns it and
/// when it is due. Category and priority live on the detail screen - showing
/// them here as well turned every row into five competing labels, and the
/// question a list answers is "what needs me next", not "tell me everything".
///
/// The widget is deliberately dumb: it receives the task, its assignee and
/// some callbacks, and owns no state of its own. All the decisions - what the
/// SLA is, who the assignee is - are made by the screen above it, which is
/// what lets the same tile be reused by the dashboard and the task list.
class TaskListTile extends StatelessWidget {
  const TaskListTile({
    super.key,
    required this.task,
    required this.assignee,
    required this.onTap,
    this.onToggleComplete,
    this.onLongPress,
  });

  final Task task;
  final TeamMember? assignee;
  final VoidCallback onTap;

  /// Tapping the leading checkbox flips the task between To Do and Done
  /// without leaving the list. Null hides the checkbox.
  final VoidCallback? onToggleComplete;

  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final sla = SlaService.evaluate(task);
    final isDone = task.status.isComplete;

    return AppCard(
      onTap: onTap,
      onLongPress: onLongPress,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.md,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (onToggleComplete != null) ...[
            _CompletionBox(
              // A stable key per task, so the checkbox can be driven
              // directly from a widget test.
              key: ValueKey('complete-${task.id}'),
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
                          color: isDone ? c.textTertiary : c.textPrimary,
                          // Completed work is struck through so a finished
                          // list still scans at a glance.
                          decoration:
                              isDone ? TextDecoration.lineThrough : null,
                          decorationColor: c.textTertiary,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    SlaBadge(status: sla.status, compact: true),
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
                    _Dot(color: c.textTertiary),
                    Text(
                      DateFormatting.relativeDueDate(task.dueDate),
                      style: AppTypography.caption.copyWith(
                        // The deadline itself turns red once it is missed, so
                        // urgency is visible even without reading the badge.
                        color: sla.status == SlaStatus.overdue
                            ? c.red
                            : c.textSecondary,
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

/// A small square checkbox that reads as a Notion to-do marker.
class _CompletionBox extends StatelessWidget {
  const _CompletionBox({
    super.key,
    required this.isDone,
    required this.onTap,
  });

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
        // Extra padding grows the tap target beyond the 18px visual box so it
        // stays comfortable to hit on a phone.
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

class _Dot extends StatelessWidget {
  const _Dot({required this.color});

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
