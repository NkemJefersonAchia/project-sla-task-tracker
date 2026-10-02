import 'package:flutter/material.dart';

import '../../widgets/common/tab_placeholder.dart';

/// The Tasks tab - the full list, and everything you can do to one task.
///
/// ## Not built yet. This file is yours.
///
/// This is the biggest piece of the app and the one the demo spends most time
/// on. It is three screens, not one: the list, a single task's detail page,
/// and the create/edit form.
///
/// Build:
///  * The list itself, one row per task. A row has to show enough to triage
///    without opening it: title, who owns it, when it is due, and its SLA
///    state. Use `SlaBadge` so the colours match the rest of the app.
///  * A search field and a row of SLA filters. `TaskQuery` already does the
///    filtering and sorting for you and is covered by tests.
///  * Tapping a row opens a detail screen: the full description, assignee,
///    deadline, priority, status, and the SLA verdict with its explanation
///    from `SlaService.evaluate(task).explanation`.
///  * A create/edit form, with validation. The rules live in `Validators`.
///  * Completing a task from the list without opening it.
///
/// Read the handover document for the full brief and the design rules.
class TasksScreen extends StatelessWidget {
  const TasksScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const TabPlaceholder(
      tab: 'Tasks',
      owner: 'feature/tasks-tab',
      summary: 'The full task list, plus the detail page and the create and '
          'edit form.',
      buildThis: [
        'A scrollable list of every task, most urgent first.',
        'Search, and filter chips for the four SLA states.',
        'A detail screen for one task, including the SLA explanation.',
        'A create and edit form with validation.',
        'Mark a task complete straight from the list.',
      ],
    );
  }
}
