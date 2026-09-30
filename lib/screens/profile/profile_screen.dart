import 'package:flutter/material.dart';

import '../../core/constants/app_routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/theme/status_colors.dart';
import '../../models/sla_status.dart';
import '../../models/task.dart';
import '../../repositories/session_repository.dart';
import '../../repositories/task_repository.dart';
import '../../services/sla_service.dart';
import '../../widgets/common/app_buttons.dart';
import '../../widgets/common/app_card.dart';
import '../../widgets/common/app_feedback.dart';
import '../../widgets/common/member_avatar.dart';
import '../../widgets/common/section_header.dart';
import '../../widgets/common/unbuilt_feature_notice.dart';
import 'widgets/settings_row.dart';

/// The signed-in member's own page: who they are, what they owe, and the way
/// out of the app.
///
/// ## Status: partially implemented
///
/// The identity header, the personal SLA summary, the link to statistics and
/// sign out all work. Editing the profile, the appearance setting and the
/// about page are work stream C (see the README).
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key, required this.onDataChanged});

  final VoidCallback onDataChanged;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Future<void> _signOut() async {
    final confirmed = await AppFeedback.confirm(
      context,
      title: 'Sign out?',
      message: 'Your tasks stay on this device. You will need to pick your '
          'name again to come back in.',
      confirmLabel: 'Sign out',
    );
    if (!confirmed || !mounted) return;

    await SessionRepository.instance.signOut();
    if (!mounted) return;

    // Clear the whole navigation stack: after signing out there must be no
    // back route into the dashboard.
    Navigator.of(context).pushNamedAndRemoveUntil(
      AppRoutes.signIn,
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final member = SessionRepository.instance.currentUser;

    final myTasks = member == null
        ? <Task>[]
        : TaskRepository.instance.byAssignee(member.id);
    final counts = SlaService.summarise(myTasks);
    final openCount =
        myTasks.where((task) => !task.status.isComplete).length;

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
          Text('Profile', style: AppTypography.pageTitle),
          const SizedBox(height: AppSpacing.xl),
          AppCard(
            child: Column(
              children: [
                MemberAvatar(member: member, size: 64),
                const SizedBox(height: AppSpacing.md),
                Text(
                  member?.name ?? 'Not signed in',
                  style: AppTypography.sectionTitle.copyWith(
                    color: c.textPrimary,
                    fontSize: 18,
                  ),
                ),
                Text(
                  member?.role ?? '',
                  style: AppTypography.caption.copyWith(
                    color: c.textSecondary,
                  ),
                ),
                if (member != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    member.email,
                    style: AppTypography.caption.copyWith(
                      color: c.textTertiary,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),

          SectionHeader(title: 'My workload'),
          AppCard(
            child: Row(
              children: [
                _MiniStat(
                  value: openCount,
                  label: 'Open',
                  color: c.textPrimary,
                ),
                _Separator(color: c.border),
                _MiniStat(
                  value: counts[SlaStatus.atRisk] ?? 0,
                  label: 'At risk',
                  color: StatusColors.forSla(context, SlaStatus.atRisk)
                      .foreground,
                ),
                _Separator(color: c.border),
                _MiniStat(
                  value: counts[SlaStatus.overdue] ?? 0,
                  label: 'Overdue',
                  color: StatusColors.forSla(context, SlaStatus.overdue)
                      .foreground,
                ),
                _Separator(color: c.border),
                _MiniStat(
                  value: counts[SlaStatus.completed] ?? 0,
                  label: 'Done',
                  color: StatusColors.forSla(context, SlaStatus.completed)
                      .foreground,
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),

          SectionHeader(title: 'Settings'),
          AppCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                SettingsRow(
                  icon: Icons.insights_outlined,
                  label: 'Task statistics',
                  onTap: () =>
                      Navigator.of(context).pushNamed(AppRoutes.statistics),
                ),
                SettingsRow(
                  icon: Icons.badge_outlined,
                  label: 'Edit profile',
                  // TODO(team): open a form that edits the signed-in member's
                  // name, role and accent colour, then calls
                  // MemberRepository.save(). Work stream C.
                  onTap: null,
                  trailingNote: 'Not built yet',
                ),
                SettingsRow(
                  icon: Icons.contrast_outlined,
                  label: 'Appearance',
                  // TODO(team): a light / dark / system selector wired to
                  // ThemeController.instance.setMode(). The controller and
                  // its persistence are already finished - this row only
                  // needs the UI. Work stream C.
                  onTap: null,
                  trailingNote: 'Follows system',
                ),
                SettingsRow(
                  icon: Icons.info_outline_rounded,
                  label: 'About this app',
                  // TODO(team): a short page describing the SLA rules and the
                  // team. Work stream C.
                  onTap: null,
                  trailingNote: 'Not built yet',
                  isLast: true,
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          const UnbuiltFeatureNotice(
            title: 'Three settings rows are still stubs',
            message: 'Edit profile, Appearance and About are work stream C. '
                'ThemeController already loads, saves and applies the theme '
                'mode, so Appearance only needs a selector wired to it.',
          ),
          const SizedBox(height: AppSpacing.xl),

          SecondaryButton(
            label: 'Sign out',
            icon: Icons.logout_rounded,
            destructive: true,
            onPressed: _signOut,
          ),
        ],
      ),
    );
  }
}

/// One number in the four-up workload strip.
class _MiniStat extends StatelessWidget {
  const _MiniStat({
    required this.value,
    required this.label,
    required this.color,
  });

  final int value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);

    // Expanded so the four stats always split the card evenly, whatever the
    // screen width.
    return Expanded(
      child: Column(
        children: [
          Text(
            '$value',
            style: AppTypography.metric.copyWith(color: color, fontSize: 22),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.badge.copyWith(color: c.textSecondary),
          ),
        ],
      ),
    );
  }
}

class _Separator extends StatelessWidget {
  const _Separator({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 30,
      width: 1,
      color: color,
    );
  }
}
