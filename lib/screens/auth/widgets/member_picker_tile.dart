import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../models/team_member.dart';
import '../../../widgets/common/app_card.dart';
import '../../../widgets/common/member_avatar.dart';

/// A roster row on the sign-in screen: tap your own name to continue.
///
/// Lives under `screens/auth/widgets/` rather than in the shared widget folder
/// because only the sign-in flow uses it. Widgets that two screens share move
/// up to `lib/widgets/`; ones that belong to a single screen stay next to it.
class MemberPickerTile extends StatelessWidget {
  const MemberPickerTile({
    super.key,
    required this.member,
    required this.onTap,
    this.enabled = true,
  });

  final TeamMember member;
  final VoidCallback onTap;

  /// Turned off while a sign-in is already in flight, so a second tap cannot
  /// start a competing navigation.
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);

    return Opacity(
      opacity: enabled ? 1 : 0.5,
      child: AppCard(
        onTap: enabled ? onTap : null,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.md - 2,
        ),
        child: Row(
          children: [
            MemberAvatar(member: member, size: 34),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    member.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.bodyStrong.copyWith(
                      color: c.textPrimary,
                    ),
                  ),
                  Text(
                    member.role,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.caption.copyWith(
                      color: c.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, size: 18, color: c.textTertiary),
          ],
        ),
      ),
    );
  }
}
