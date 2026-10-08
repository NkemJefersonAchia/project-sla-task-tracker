import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/date_formatting.dart';
import '../../repositories/session_repository.dart';
import '../../widgets/common/member_avatar.dart';

/// The Home tab: the dashboard.
///
/// It answers one question the moment the app opens - is this project in
/// trouble, and if so where. It is the only screen that looks across every
/// task at once, so it is a summary and a way in, not another task list.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final me = SessionRepository.instance.currentUser;

    return Scaffold(
      backgroundColor: c.canvas,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.screenPadding,
            AppSpacing.lg,
            AppSpacing.screenPadding,
            AppSpacing.xxl,
          ),
          children: [
            _Greeting(
              name: me?.name.split(' ').first ?? 'there',
              role: me?.role ?? '',
              avatar: MemberAvatar(member: me, size: 38),
            ),
          ],
        ),
      ),
    );
  }
}

/// "Good afternoon / Amara / Project Manager", with the avatar on the right.
///
/// The time-of-day greeting is the one piece of warmth on an otherwise
/// factual screen, and it doubles as confirmation of who you are signed in
/// as - which matters on a shared demo device.
class _Greeting extends StatelessWidget {
  const _Greeting({
    required this.name,
    required this.role,
    required this.avatar,
  });

  final String name;
  final String role;
  final Widget avatar;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                DateFormatting.greeting(),
                style: AppTypography.caption.copyWith(color: c.textTertiary),
              ),
              const SizedBox(height: 2),
              Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.pageTitle.copyWith(color: c.textPrimary),
              ),
              if (role.isNotEmpty)
                Text(
                  role,
                  style: AppTypography.caption.copyWith(
                    color: c.textSecondary,
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        avatar,
      ],
    );
  }
}
