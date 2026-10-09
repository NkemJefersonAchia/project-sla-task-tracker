import 'package:flutter/material.dart';
import 'package:project_sla_task_tracker/core/theme/app_colors.dart';
import 'package:project_sla_task_tracker/core/theme/app_spacing.dart';
import 'package:project_sla_task_tracker/core/theme/app_typography.dart';
import 'package:project_sla_task_tracker/core/utils/date_formatting.dart'; // ASSUMPTION: path
import 'package:project_sla_task_tracker/models/team_member.dart';
import 'package:project_sla_task_tracker/repositories/task_repository.dart'; // ASSUMPTION: path
import 'package:project_sla_task_tracker/services/sla_service.dart';
import 'package:project_sla_task_tracker/widgets/common/app_card.dart';
import 'package:project_sla_task_tracker/widgets/common/empty_state.dart';
import 'package:project_sla_task_tracker/widgets/common/member_avatar.dart';
import 'package:project_sla_task_tracker/widgets/task/sla_badge.dart';

/// Bottom sheet listing everything assigned to [member], soonest deadline first.
class MemberTasksSheet extends StatelessWidget {
  final TeamMember member;
  const MemberTasksSheet({super.key, required this.member});

  static Future<void> show(BuildContext context, TeamMember member) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => MemberTasksSheet(member: member),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    // Read from the repository on every build - never a stored copy.
    final tasks = TaskRepository.instance.byAssignee(member.id).toList()
      ..sort(
        (a, b) => a.dueDate.compareTo(b.dueDate),
      ); // ASSUMPTION: Task.dueDate

    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.75,
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            0,
            AppSpacing.lg,
            AppSpacing.lg,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  MemberAvatar(member: member),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(member.name, style: AppTypography.bodyStrong),
                        Text(
                          '${tasks.length} assigned',
                          style: AppTypography.caption.copyWith(
                            color: c.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              if (tasks.isEmpty)
                const EmptyState(
                  icon: Icons.check_circle_outline,
                  title: 'Nothing assigned',
                  message: 'This person has capacity to take on work.',
                )
              else
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: tasks.length,
                    separatorBuilder: (_, _) =>
                        const SizedBox(height: AppSpacing.sm),
                    itemBuilder: (context, i) {
                      final t = tasks[i];
                      return AppCard(
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    t.title,
                                    style: AppTypography.bodyStrong,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    DateFormatting.relativeDueDate(t.dueDate),
                                    style: AppTypography.caption.copyWith(
                                      color: c.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            SlaBadge(status: SlaService.statusOf(t)),
                          ],
                        ),
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
