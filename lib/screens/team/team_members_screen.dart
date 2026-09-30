import 'package:flutter/material.dart';

import '../../core/constants/app_routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/theme/status_colors.dart';
import '../../models/sla_status.dart';
import '../../models/team_member.dart';
import '../../repositories/member_repository.dart';
import '../../repositories/session_repository.dart';
import '../../repositories/task_repository.dart';
import '../../services/sla_service.dart';
import '../../widgets/common/app_card.dart';
import '../../widgets/common/empty_state.dart';
import '../../widgets/common/member_avatar.dart';
import '../../widgets/common/section_header.dart';
import '../../widgets/common/unbuilt_feature_notice.dart';
import '../../widgets/task/task_list_tile.dart';

/// The team roster, with each member's current workload.
///
/// The value here is not the list of names - it is the per-person SLA
/// breakdown, which turns "who is on the team" into "who is overloaded".
///
/// ## Status: partially implemented
///
/// Listing members and drilling into their workload is done. Adding, editing
/// and removing members is the next piece of work - see `TEAM_TASKS.md`,
/// work stream B.
class TeamMembersScreen extends StatefulWidget {
  const TeamMembersScreen({super.key, required this.onDataChanged});

  final VoidCallback onDataChanged;

  @override
  State<TeamMembersScreen> createState() => _TeamMembersScreenState();
}

class _TeamMembersScreenState extends State<TeamMembersScreen> {
  Future<void> _openMemberWorkload(TeamMember member) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _MemberWorkloadSheet(member: member),
    );
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final members = MemberRepository.instance.all;
    final currentUserId = SessionRepository.instance.currentUser?.id;

    return Scaffold(
      backgroundColor: c.canvas,
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.screenPadding,
          AppSpacing.lg,
          AppSpacing.screenPadding,
          AppSpacing.xxl,
        ),
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Text('Team', style: AppTypography.pageTitle),
              ),
              Text(
                '${members.length} members',
                style: AppTypography.caption.copyWith(color: c.textTertiary),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Tap a member to see everything currently on their plate.',
            style: AppTypography.caption.copyWith(color: c.textSecondary),
          ),
          const SizedBox(height: AppSpacing.xl),
          if (members.isEmpty)
            EmptyState(
              icon: Icons.group_outlined,
              title: 'No team members yet',
              message: 'Members are seeded on first launch. Adding them from '
                  'the app is still to be built.',
            )
          else
            for (final member in members)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: _MemberCard(
                  member: member,
                  isCurrentUser: member.id == currentUserId,
                  onTap: () => _openMemberWorkload(member),
                ),
              ),
          const SizedBox(height: AppSpacing.lg),
          const UnbuiltFeatureNotice(
            title: 'Managing the roster is not built yet',
            message: 'Adding, editing and removing team members is work '
                'stream B in TEAM_TASKS.md. The repository already exposes '
                'save() and newId(); the screen and the form are what is '
                'missing.',
          ),
        ],
      ),
    );
  }
}

/// A roster row: avatar, name, role, and a one-line workload summary.
class _MemberCard extends StatelessWidget {
  const _MemberCard({
    required this.member,
    required this.isCurrentUser,
    required this.onTap,
  });

  final TeamMember member;
  final bool isCurrentUser;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);

    final tasks = TaskRepository.instance.byAssignee(member.id);
    final counts = SlaService.summarise(tasks);
    final open = tasks.where((task) => !task.status.isComplete).length;

    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: [
          MemberAvatar(member: member, size: 40),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        member.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.bodyStrong.copyWith(
                          color: c.textPrimary,
                        ),
                      ),
                    ),
                    if (isCurrentUser) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 5,
                          vertical: 1,
                        ),
                        decoration: BoxDecoration(
                          color: c.blueBg,
                          borderRadius: BorderRadius.circular(AppRadius.sm),
                        ),
                        child: Text(
                          'You',
                          style: AppTypography.badge.copyWith(
                            color: c.blue,
                            fontSize: 10,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                Text(
                  member.role,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.caption.copyWith(
                    color: c.textSecondary,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Text(
                      '$open open',
                      style: AppTypography.badge.copyWith(
                        color: c.textTertiary,
                      ),
                    ),
                    // Only the buckets that actually have work are shown, so
                    // a healthy member's row stays quiet.
                    for (final status in [
                      SlaStatus.overdue,
                      SlaStatus.atRisk,
                    ])
                      if ((counts[status] ?? 0) > 0) ...[
                        const SizedBox(width: AppSpacing.sm),
                        _WorkloadDot(
                          count: counts[status]!,
                          label: status.label,
                          color: StatusColors.forSla(context, status)
                              .foreground,
                        ),
                      ],
                  ],
                ),
              ],
            ),
          ),
          Icon(Icons.chevron_right_rounded, size: 18, color: c.textTertiary),
        ],
      ),
    );
  }
}

class _WorkloadDot extends StatelessWidget {
  const _WorkloadDot({
    required this.count,
    required this.label,
    required this.color,
  });

  final int count;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          height: 6,
          width: 6,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(
          '$count $label',
          style: AppTypography.badge.copyWith(color: color, fontSize: 11),
        ),
      ],
    );
  }
}

/// Bottom sheet listing everything assigned to one member.
class _MemberWorkloadSheet extends StatelessWidget {
  const _MemberWorkloadSheet({required this.member});

  final TeamMember member;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);

    final tasks = TaskRepository.instance.byAssignee(member.id)
      // Most urgent deadline first - the question this sheet answers is
      // "what should this person do next?".
      ..sort((a, b) => a.dueDate.compareTo(b.dueDate));

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.7,
      maxChildSize: 0.94,
      builder: (context, scrollController) {
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(AppSpacing.screenPadding),
              child: Row(
                children: [
                  MemberAvatar(member: member, size: 40),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          member.name,
                          style: AppTypography.sectionTitle.copyWith(
                            color: c.textPrimary,
                          ),
                        ),
                        Text(
                          member.email,
                          style: AppTypography.caption.copyWith(
                            color: c.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 20),
                    tooltip: 'Close',
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            Divider(color: c.border, height: 1),
            Expanded(
              child: tasks.isEmpty
                  ? Center(
                      child: EmptyState(
                        icon: Icons.beach_access_outlined,
                        title: 'Nothing assigned',
                        message:
                            '${member.name.split(' ').first} has no tasks on '
                            'the board right now.',
                      ),
                    )
                  : ListView.separated(
                      controller: scrollController,
                      padding: const EdgeInsets.all(AppSpacing.screenPadding),
                      itemCount: tasks.length + 1,
                      separatorBuilder: (_, _) =>
                          const SizedBox(height: AppSpacing.sm),
                      itemBuilder: (context, index) {
                        if (index == 0) {
                          return SectionHeader(
                            title: 'Assigned work (${tasks.length})',
                            padding: EdgeInsets.zero,
                          );
                        }
                        final task = tasks[index - 1];
                        return TaskListTile(
                          task: task,
                          assignee: member,
                          onTap: () {
                            // Close the sheet first so the detail screen is
                            // pushed onto the page behind it, not on top of a
                            // sheet the user would have to dismiss twice.
                            Navigator.of(context).pop();
                            Navigator.of(context).pushNamed(
                              AppRoutes.taskDetail,
                              arguments: TaskDetailArgs(task.id),
                            );
                          },
                        );
                      },
                    ),
            ),
          ],
        );
      },
    );
  }
}
