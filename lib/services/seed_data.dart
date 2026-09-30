import '../models/task.dart';
import '../models/task_priority.dart';
import '../models/task_status.dart';
import '../models/team_member.dart';

/// Demo content written once, on first launch only.
///
/// Deadlines are expressed as offsets from "today" rather than fixed dates so
/// that a fresh install always shows every SLA state - On Track, At Risk,
/// Overdue and Completed - no matter when the app is opened.
abstract final class SeedData {
  static List<TeamMember> members() => const [
        TeamMember(
          id: 'member_1',
          name: 'Amara Okonkwo',
          role: 'Project Manager',
          email: 'amara@teamsla.dev',
          colorKey: 'blue',
        ),
        TeamMember(
          id: 'member_2',
          name: 'Liam Mugisha',
          role: 'UI/UX Designer',
          email: 'liam@teamsla.dev',
          colorKey: 'purple',
        ),
        TeamMember(
          id: 'member_3',
          name: 'Sana Rahman',
          role: 'Mobile Developer',
          email: 'sana@teamsla.dev',
          colorKey: 'green',
        ),
        TeamMember(
          id: 'member_4',
          name: 'Kwame Boateng',
          role: 'QA Engineer',
          email: 'kwame@teamsla.dev',
          colorKey: 'orange',
        ),
      ];

  static List<Task> tasks() {
    final now = DateTime.now();
    final today = Task.dateOnly(now);

    Task make({
      required String id,
      required String title,
      required String description,
      required String category,
      required String assigneeId,
      required int dueInDays,
      required TaskPriority priority,
      required TaskStatus status,
      int createdDaysAgo = 7,
    }) {
      final isDone = status.isComplete;
      return Task(
        id: id,
        title: title,
        description: description,
        category: category,
        assigneeId: assigneeId,
        dueDate: today.add(Duration(days: dueInDays)),
        priority: priority,
        status: status,
        createdAt: now.subtract(Duration(days: createdDaysAgo)),
        updatedAt: now.subtract(const Duration(days: 1)),
        completedAt: isDone ? now.subtract(const Duration(days: 1)) : null,
      );
    }

    return [
      make(
        id: 'task_1',
        title: 'Design the sign-in and onboarding flow',
        description:
            'Produce the final screens for sign-in, including the empty and '
            'error states, and hand the spacing tokens to the mobile team.',
        category: 'UI/UX Design',
        assigneeId: 'member_2',
        dueInDays: 9,
        priority: TaskPriority.medium,
        status: TaskStatus.inProgress,
      ),
      make(
        id: 'task_2',
        title: 'Wire local persistence with SharedPreferences',
        description:
            'Serialise tasks and team members to JSON and restore them on '
            'launch so nothing is lost when the app is closed.',
        category: 'Mobile Development',
        assigneeId: 'member_3',
        dueInDays: 2,
        priority: TaskPriority.high,
        status: TaskStatus.inProgress,
      ),
      make(
        id: 'task_3',
        title: 'Define the SLA classification rules',
        description:
            'Agree the thresholds that move a task from On Track to At Risk '
            'and document them for the demo.',
        category: 'Backend Logic',
        assigneeId: 'member_1',
        dueInDays: -3,
        priority: TaskPriority.urgent,
        status: TaskStatus.inProgress,
        createdDaysAgo: 14,
      ),
      make(
        id: 'task_4',
        title: 'Write regression tests for the task list filters',
        description:
            'Cover the status filter, the search field and the empty state so '
            'the list cannot silently break.',
        category: 'Quality Assurance',
        assigneeId: 'member_4',
        dueInDays: 12,
        priority: TaskPriority.low,
        status: TaskStatus.todo,
      ),
      make(
        id: 'task_5',
        title: 'Prepare the group demonstration script',
        description:
            'Draft who presents which part of the walkthrough and rehearse '
            'the end-to-end flow once.',
        category: 'Documentation',
        assigneeId: 'member_1',
        dueInDays: 3,
        priority: TaskPriority.medium,
        status: TaskStatus.todo,
      ),
      make(
        id: 'task_6',
        title: 'Set up the shared repository and branch protection',
        description:
            'Create the repository, add every member and agree the branch '
            'naming convention before development starts.',
        category: 'Project Setup',
        assigneeId: 'member_3',
        dueInDays: -6,
        priority: TaskPriority.high,
        status: TaskStatus.done,
        createdDaysAgo: 20,
      ),
      make(
        id: 'task_7',
        title: 'Build the reusable badge and chip components',
        description:
            'One badge widget drives the SLA colour everywhere so the list, '
            'the detail screen and the dashboard can never disagree.',
        category: 'UI/UX Design',
        assigneeId: 'member_2',
        dueInDays: -1,
        priority: TaskPriority.medium,
        status: TaskStatus.done,
        createdDaysAgo: 10,
      ),
      make(
        id: 'task_8',
        title: 'Review accessibility of the colour palette',
        description:
            'Check every badge pairing against contrast guidance in both the '
            'light and dark theme.',
        category: 'Quality Assurance',
        assigneeId: 'member_4',
        dueInDays: 21,
        priority: TaskPriority.low,
        status: TaskStatus.todo,
      ),
    ];
  }
}
