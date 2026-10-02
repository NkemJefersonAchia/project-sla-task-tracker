import 'package:flutter/material.dart';

import '../../widgets/common/tab_placeholder.dart';

/// The Team tab - who is on the project and what each of them is carrying.
///
/// ## Not built yet. This file is yours.
///
/// A plain list of names would be useless. What makes this tab worth opening
/// is the workload: it should answer "who is overloaded, and who could take
/// something on".
///
/// Build:
///  * A list of the team. `MemberRepository.instance.all` gives you the
///    members; `MemberAvatar` renders their initials in their own colour.
///  * For each person, how much work they are carrying and how much of it is
///    in trouble. `TaskRepository.instance.byAssignee(id)` then
///    `SlaService.summarise(...)` gives you the numbers.
///  * Tapping a person shows everything assigned to them.
///  * Adding, editing and removing a member.
///
/// Removing a member needs a decision first: if they still own unfinished
/// tasks, do those tasks become unassigned, or is the delete refused until
/// somebody else takes them? Agree it with the team and be ready to explain
/// the choice. `MemberRepository` has no `delete()` yet for this reason.
///
/// Read the handover document for the full brief and the design rules.
class TeamScreen extends StatelessWidget {
  const TeamScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const TabPlaceholder(
      tab: 'Team',
      owner: 'feature/team-tab',
      summary: 'The people on the project, and how much work each of them is '
          'carrying.',
      buildThis: [
        "A list of the team with each person's role.",
        'Per person: open tasks, and how many are at risk or overdue.',
        'Tap a person to see everything assigned to them.',
        'Add, edit and remove a member.',
        'Decide what happens to the tasks of a member you delete.',
      ],
    );
  }
}
