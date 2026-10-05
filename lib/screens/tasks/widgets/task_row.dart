import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/date_formatting.dart';
import '../../../models/task.dart';
import '../../../models/team_member.dart';
import '../../../widgets/common/app_card.dart';
import '../../../widgets/common/member_avatar.dart';

/// One task as it appears in the list.
///
/// Deliberately dumb: it is handed the task and a callback, and owns no state.
/// Every decision - what the SLA is, who the assignee is - belongs to the
/// screen above it, so this widget can be dropped into any list.
class TaskRow extends StatelessWidget {
  const TaskRow({
    super.key,
    required this.task,
    required this.assignee,
    required this.onTap,
  });

  final Task task;

  /// Null renders as "Unassigned" rather than crashing - a task can outlive
  /// the member it was given to.
  final TeamMember? assignee;

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);

    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.md,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            task.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.bodyStrong.copyWith(color: c.textPrimary),
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
                style: AppTypography.caption.copyWith(color: c.textSecondary),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// The 3px dot Notion uses between inline metadata, rather than a slash or a
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
