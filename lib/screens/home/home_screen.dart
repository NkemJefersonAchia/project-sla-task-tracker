import 'package:flutter/material.dart';

import '../../widgets/common/tab_placeholder.dart';

/// The Home tab - the project dashboard.
///
/// ## Not built yet. This file is yours.
///
/// Home answers one question the moment the app opens: is this project in
/// trouble, and if so where. It is the only screen that looks across every
/// task at once, so it is a summary plus a way in - not another task list.
///
/// Build:
///  * A greeting header showing who is using the app.
///  * Four counters: total tasks, On Track, At Risk, Overdue. Get them from
///    `SlaService.summarise(TaskRepository.instance.all)`.
///  * Make each counter tappable so it opens the Tasks tab filtered to that
///    state. Talk to whoever owns Tasks about how you hand the filter over.
///  * A short "needs attention" list: the overdue and at-risk tasks, soonest
///    deadline first, capped at three or four rows.
///
/// Read the handover document for the full brief and the design rules.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const TabPlaceholder(
      tab: 'Home',
      owner: 'feature/home-tab',
      summary: 'The dashboard. Shows whether the project is on schedule and '
          'what needs a decision today.',
      buildThis: [
        'A greeting header with the current user.',
        'Four counters: total, On Track, At Risk, Overdue.',
        'Each counter opens the Tasks tab filtered to that SLA state.',
        'A short list of the work that is overdue or at risk.',
      ],
    );
  }
}
