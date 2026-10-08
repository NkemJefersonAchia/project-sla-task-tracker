import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../models/sla_status.dart';
import '../../models/team_member.dart';
import '../../widgets/common/app_card.dart';
import '../../widgets/common/member_avatar.dart';

enum MemberMenuAction { edit, delete }

int openTaskCount(Map<SlaStatus, int> counts) =>
    counts.values.fold<int>(0, (total, count) => total + count) -
    (counts[SlaStatus.completed] ?? 0);

/// One row in the roster: avatar, name, role and options menu.
class MemberCard extends StatelessWidget {
  final TeamMember member;
  final VoidCallback onTap;
  final ValueChanged<MemberMenuAction> onMenu;

  const MemberCard({
    super.key,
    required this.member,
    required this.onTap,
    required this.onMenu,
  });

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);

    return AppCard(
      onTap: onTap,
      child: Row(
        children: [
          MemberAvatar(member: member, size: 48),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  member.name,
                  style: AppTypography.bodyStrong.copyWith(
                    color: c.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  member.role,
                  style: AppTypography.caption.copyWith(color: c.textSecondary),
                ),
              ],
            ),
          ),
          PopupMenuButton<MemberMenuAction>(
            icon: Icon(Icons.more_vert, color: c.textSecondary),
            onSelected: onMenu,
            itemBuilder: (_) => const [
              PopupMenuItem(value: MemberMenuAction.edit, child: Text('Edit')),
              PopupMenuItem(
                value: MemberMenuAction.delete,
                child: Text('Delete'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
