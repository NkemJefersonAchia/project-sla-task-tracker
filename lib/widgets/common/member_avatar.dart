import 'package:flutter/material.dart';

import '../../core/theme/app_typography.dart';
import '../../core/theme/status_colors.dart';
import '../../models/team_member.dart';

/// Initials avatar for a team member.
///
/// There are no photo assets in the project, so identity is carried by the
/// member's own accent colour plus their initials. Passing a null [member]
/// renders a neutral "unassigned" placeholder instead of crashing, which is
/// what the task list needs for a task nobody owns yet.
class MemberAvatar extends StatelessWidget {
  const MemberAvatar({
    super.key,
    required this.member,
    this.size = 28,
  });

  final TeamMember? member;
  final double size;

  @override
  Widget build(BuildContext context) {
    final pair = StatusColors.forMemberColor(
      context,
      member?.colorKey ?? 'gray',
    );

    return Container(
      height: size,
      width: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: pair.background,
        shape: BoxShape.circle,
      ),
      child: member == null
          ? Icon(
              Icons.person_outline_rounded,
              size: size * 0.55,
              color: pair.foreground,
            )
          : Text(
              member!.initials,
              style: AppTypography.badge.copyWith(
                color: pair.foreground,
                fontSize: size * 0.38,
                fontWeight: FontWeight.w600,
              ),
            ),
    );
  }
}
