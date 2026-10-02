import 'package:flutter/material.dart';

import '../../widgets/common/tab_placeholder.dart';

/// The Profile tab - the current user's own page, and app settings.
///
/// ## Not built yet. This file is yours.
///
/// Everything here is about the person using the app, not the project.
///
/// Build:
///  * A header with their avatar, name, role and email.
///    `SessionRepository.instance.currentUser` tells you who that is.
///  * Their own workload: how many tasks they personally have open, at risk,
///    overdue and done.
///  * A settings list. At minimum: edit profile, appearance, about, sign out.
///  * Edit profile changes their name, role and avatar colour, saved through
///    `MemberRepository.instance.save()`. The change has to show up on the
///    other tabs straight away.
///  * Appearance switches light / dark / follow system. The work behind this
///    is already finished - `ThemeController.instance.setMode()` applies and
///    saves the choice, and the app already has a full dark theme. You only
///    need the control.
///  * About: a short page explaining the SLA rules to someone new.
///
/// Sign out belongs to whoever builds the welcome screen - agree between you
/// who writes it.
///
/// Read the handover document for the full brief and the design rules.
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const TabPlaceholder(
      tab: 'Profile',
      owner: 'feature/profile-tab',
      summary: "The current user's page: who they are, what they owe, and "
          "the app's settings.",
      buildThis: [
        'A header with avatar, name, role and email.',
        'Their own counts: open, at risk, overdue, done.',
        'A settings list.',
        'Edit profile: name, role, avatar colour.',
        'Appearance: light, dark or follow system.',
        'An about page explaining the SLA rules.',
      ],
    );
  }
}
