import 'package:flutter/material.dart';

import '../../core/constants/app_routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../models/team_member.dart';
import '../../repositories/member_repository.dart';
import '../../repositories/session_repository.dart';
import '../../repositories/task_repository.dart';
import '../../services/storage_service.dart';
import '../../widgets/common/app_buttons.dart';
import '../../widgets/common/app_feedback.dart';
import '../../widgets/common/empty_state.dart';
import 'member_card.dart';
import 'member_tasks_sheet.dart';

class TeamScreen extends StatefulWidget {
  const TeamScreen({super.key, this.onNavigate});

  final ValueChanged<int>? onNavigate;

  @override
  State<TeamScreen> createState() => _TeamScreenState();
}

class _TeamScreenState extends State<TeamScreen> {
  Future<void> _openForm({String? memberId}) async {
    final saved = await Navigator.pushNamed<bool>(
      context,
      AppRoutes.memberForm,
      arguments: memberId,
    );
    if (saved == true && mounted) setState(() {});
  }

  Future<void> _delete(TeamMember member) async {
    final me = SessionRepository.instance.currentUser;
    if (me?.id == member.id) {
      AppFeedback.showError(
        context,
        'You cannot delete the member you are signed in as.',
      );
      return;
    }

    final owned = TaskRepository.instance.byAssignee(member.id);
    final ok = await AppFeedback.confirm(
      context,
      title: 'Delete ${member.name}?',
      message: owned.isNotEmpty
          ? '${owned.length} assigned task(s) will become unassigned.'
          : 'This action cannot be undone.',
      confirmLabel: 'Delete',
    );
    if (ok != true || !mounted) return;

    try {
      await TaskRepository.instance.unassignAll(member.id);
      await MemberRepository.instance.delete(member.id);
      if (!mounted) return;
      setState(() {});
      AppFeedback.showSuccess(context, '${member.name} removed');
    } on StorageException catch (_) {
      if (!mounted) return;
      AppFeedback.showError(
        context,
        'Could not remove ${member.name}. Please try again.',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final members = MemberRepository.instance.all;

    return Scaffold(
      backgroundColor: c.surfaceMuted,
      drawer: _TeamNavigationDrawer(onNavigate: widget.onNavigate),
      appBar: AppBar(
        backgroundColor: c.surfaceMuted,
        centerTitle: true,
        leading: Builder(
          builder: (context) => IconButton(
            tooltip: 'Open navigation menu',
            icon: const Icon(Icons.menu),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        title: const Text('Team Members'),
        actions: [
          IconButton(
            tooltip: 'Add member',
            icon: Icon(Icons.add_circle, color: c.accent, size: 30),
            onPressed: () => _openForm(),
          ),
        ],
      ),
      body: members.isEmpty
          ? EmptyState(
              icon: Icons.group_outlined,
              title: 'No team members yet',
              message: 'Add the first person to start assigning work.',
              action: PrimaryButton(
                label: 'Add member',
                onPressed: () => _openForm(),
                expand: false,
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(AppSpacing.screenPadding),
              itemCount: members.length,
              separatorBuilder: (context, index) =>
                  const SizedBox(height: AppSpacing.md),
              itemBuilder: (context, index) {
                final member = members[index];
                return MemberCard(
                  member: member,
                  onTap: () => MemberTasksSheet.show(context, member),
                  onMenu: (action) => action == MemberMenuAction.edit
                      ? _openForm(memberId: member.id)
                      : _delete(member),
                );
              },
            ),
    );
  }
}

class _TeamNavigationDrawer extends StatelessWidget {
  const _TeamNavigationDrawer({required this.onNavigate});

  final ValueChanged<int>? onNavigate;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    const destinations = ['Home', 'Tasks', 'Team', 'Profile'];
    const icons = [
      Icons.dashboard_outlined,
      Icons.check_circle_outline_rounded,
      Icons.people_outline_rounded,
      Icons.person_outline_rounded,
    ];

    return Drawer(
      backgroundColor: c.surface,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: Text(
                'SLA Task Tracker',
                style: AppTypography.sectionTitle.copyWith(
                  color: c.textPrimary,
                ),
              ),
            ),
            for (var index = 0; index < destinations.length; index++)
              ListTile(
                leading: Icon(
                  icons[index],
                  color: index == 2 ? c.blue : c.textSecondary,
                ),
                title: Text(destinations[index]),
                selected: index == 2,
                onTap: onNavigate == null
                    ? () => Navigator.pop(context)
                    : () {
                        Navigator.pop(context);
                        onNavigate!(index);
                      },
              ),
          ],
        ),
      ),
    );
  }
}
