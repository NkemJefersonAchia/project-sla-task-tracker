import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:project_sla_task_tracker/app.dart';
import 'package:project_sla_task_tracker/core/theme/theme_controller.dart';
import 'package:project_sla_task_tracker/models/task_status.dart';
import 'package:project_sla_task_tracker/repositories/member_repository.dart';
import 'package:project_sla_task_tracker/repositories/session_repository.dart';
import 'package:project_sla_task_tracker/repositories/task_repository.dart';
import 'package:project_sla_task_tracker/screens/tasks/task_detail_screen.dart';
import 'package:project_sla_task_tracker/screens/tasks/task_list_screen.dart';
import 'package:project_sla_task_tracker/screens/tasks/task_form_screen.dart';
import 'package:project_sla_task_tracker/services/storage_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// End-to-end smoke tests over the real widget tree.
///
/// `SharedPreferences.setMockInitialValues` gives the app a clean in-memory
/// store, so these run the genuine start-up path - seed the data, build the
/// real screens, navigate between them - without a device. Any layout
/// overflow or null crash on the main flow fails the test.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  /// Rebuilds the world before each test so no test can depend on another's
  /// leftovers.
  Future<void> bootstrap() async {
    SharedPreferences.setMockInitialValues({});

    TaskRepository.instance.resetForTesting();
    MemberRepository.instance.resetForTesting();

    await StorageService.instance.init();
    await ThemeController.instance.load();
    await MemberRepository.instance.load();
    await TaskRepository.instance.load();
    await SessionRepository.instance.load();
  }

  setUp(bootstrap);

  /// Scrolls [finder] into view before acting on it.
  ///
  /// The test surface is shorter than a real phone, so buttons at the foot of
  /// a form start off-screen. Scrolling first is what a user would do.
  ///
  /// The scrollable has to be named explicitly: the shell keeps all four tabs
  /// alive, so several ListViews exist at once and the helpers that look for
  /// "the" scrollable would throw. [within] is the screen that owns the one
  /// we mean.
  Future<void> scrollTo(
    WidgetTester tester,
    Finder finder, {
    required Finder within,
  }) async {
    final scrollable = find
        .descendant(of: within, matching: find.byType(Scrollable))
        .first;

    await tester.dragUntilVisible(finder, scrollable, const Offset(0, -120));
    await tester.pumpAndSettle();
  }

  testWidgets('first launch seeds the demo data', (tester) async {
    expect(TaskRepository.instance.all, isNotEmpty);
    expect(MemberRepository.instance.all, hasLength(4));
  });

  testWidgets('a signed-out user lands on sign in', (tester) async {
    await SessionRepository.instance.signOut();
    await tester.pumpWidget(const TaskTrackerApp());
    await tester.pumpAndSettle();

    expect(find.text('Sign in'), findsOneWidget);
    expect(find.text('Amara Okonkwo'), findsOneWidget);
  });

  testWidgets('picking a member from the roster opens the dashboard',
      (tester) async {
    await SessionRepository.instance.signOut();
    await tester.pumpWidget(const TaskTrackerApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Liam Mugisha'));
    await tester.pumpAndSettle();

    // The dashboard greets the signed-in member by their first name.
    expect(find.text('Liam'), findsOneWidget);
    expect(find.text('Total tasks'), findsOneWidget);
    expect(SessionRepository.instance.currentUser?.name, 'Liam Mugisha');
  });

  testWidgets('an unknown email is rejected with a form-level message',
      (tester) async {
    await SessionRepository.instance.signOut();
    await tester.pumpWidget(const TaskTrackerApp());
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byType(TextFormField).first,
      'stranger@example.com',
    );
    await tester.enterText(find.byType(TextFormField).last, 'password123');
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    expect(find.textContaining('No team member uses'), findsOneWidget);
    expect(SessionRepository.instance.isSignedIn, isFalse);
  });

  testWidgets('a malformed email is rejected by field validation',
      (tester) async {
    await SessionRepository.instance.signOut();
    await tester.pumpWidget(const TaskTrackerApp());
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField).first, 'not-an-email');
    await tester.enterText(find.byType(TextFormField).last, 'password123');
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    expect(find.textContaining('valid email address'), findsOneWidget);
  });

  testWidgets('the four bottom tabs all build', (tester) async {
    await SessionRepository.instance
        .signIn(MemberRepository.instance.all.first);
    await tester.pumpWidget(const TaskTrackerApp());
    await tester.pumpAndSettle();

    for (final label in ['Tasks', 'Team', 'Profile', 'Home']) {
      await tester.tap(find.text(label).last);
      await tester.pumpAndSettle();
    }

    // Back on Home at the end of the loop.
    expect(find.text('Total tasks'), findsOneWidget);
  });

  testWidgets('completing a task from the list persists and updates the count',
      (tester) async {
    await SessionRepository.instance
        .signIn(MemberRepository.instance.all.first);
    await tester.pumpWidget(const TaskTrackerApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Tasks').last);
    await tester.pumpAndSettle();

    final openTask = TaskRepository.instance.all
        .firstWhere((task) => !task.status.isComplete);
    final before = TaskRepository.instance.all
        .where((task) => task.status.isComplete)
        .length;

    // Tap the checkbox on that task's row.
    final checkbox = find.byKey(ValueKey('complete-${openTask.id}'));
    await tester.ensureVisible(checkbox);
    await tester.pumpAndSettle();
    await tester.tap(checkbox);
    await tester.pumpAndSettle();

    final after = TaskRepository.instance.all
        .where((task) => task.status.isComplete)
        .length;

    expect(after, before + 1);
    expect(
      TaskRepository.instance.byId(openTask.id)!.status,
      TaskStatus.done,
    );
    // The completion stamp is what the statistics screen will need later.
    expect(TaskRepository.instance.byId(openTask.id)!.completedAt, isNotNull);
  });

  testWidgets('creating a task through the form adds it to the list',
      (tester) async {
    await SessionRepository.instance
        .signIn(MemberRepository.instance.all.first);
    await tester.pumpWidget(const TaskTrackerApp());
    await tester.pumpAndSettle();

    final before = TaskRepository.instance.all.length;

    await tester.tap(find.byIcon(Icons.add_rounded).first);
    await tester.pumpAndSettle();

    expect(find.text('New task'), findsOneWidget);

    await tester.enterText(
      find.byType(TextFormField).first,
      'Rehearse the walkthrough',
    );
    // Category is required and comes from a dropdown.
    await tester.tap(find.byType(DropdownButtonFormField<String>).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Documentation').last);
    await tester.pumpAndSettle();

    await scrollTo(
      tester,
      find.text('Create task'),
      within: find.byType(TaskFormScreen),
    );
    await tester.tap(find.text('Create task'));
    await tester.pumpAndSettle();

    expect(TaskRepository.instance.all.length, before + 1);
    expect(
      TaskRepository.instance.all
          .any((task) => task.title == 'Rehearse the walkthrough'),
      isTrue,
    );
  });

  testWidgets('a task with too short a title is blocked by validation',
      (tester) async {
    await SessionRepository.instance
        .signIn(MemberRepository.instance.all.first);
    await tester.pumpWidget(const TaskTrackerApp());
    await tester.pumpAndSettle();

    final before = TaskRepository.instance.all.length;

    await tester.tap(find.byIcon(Icons.add_rounded).first);
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField).first, 'ab');
    await scrollTo(
      tester,
      find.text('Create task'),
      within: find.byType(TaskFormScreen),
    );
    await tester.tap(find.text('Create task'));
    await tester.pumpAndSettle();

    // Nothing was saved and the form stayed open, with the failure spelled
    // out in a snack bar.
    expect(TaskRepository.instance.all.length, before);
    expect(find.byType(TaskFormScreen), findsOneWidget);
    expect(find.textContaining('Fix the highlighted fields'), findsOneWidget);
  });

  testWidgets('the task detail screen explains the SLA decision',
      (tester) async {
    await SessionRepository.instance
        .signIn(MemberRepository.instance.all.first);
    await tester.pumpWidget(const TaskTrackerApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Tasks').last);
    await tester.pumpAndSettle();

    final overdue = TaskRepository.instance.all.firstWhere(
      (task) => task.dueDate.isBefore(DateTime.now()) && !task.status.isComplete,
    );

    // Scoped to the task list: the dashboard tab is still alive in the
    // IndexedStack and shows some of the same titles.
    await tester.tap(
      find
          .descendant(
            of: find.byType(TaskListScreen),
            matching: find.text(overdue.title),
          )
          .first,
    );
    await tester.pumpAndSettle();

    // SectionHeader upper-cases its title, so the rendered text is the
    // shouty version.
    await scrollTo(
      tester,
      find.text('SLA STATUS'),
      within: find.byType(TaskDetailScreen),
    );

    expect(find.text('SLA STATUS'), findsOneWidget);
    // The card states the reason, not just the colour - and that sentence is
    // generated by SlaService, the same code that made the decision.
    expect(find.textContaining('deadline passed'), findsOneWidget);
    expect(find.text('Overdue'), findsWidgets);
  });

  testWidgets('data written in one session is read back in the next',
      (tester) async {
    // Prove persistence without restarting the process: write, drop the
    // in-memory cache, then load again from the same mock store.
    final task = TaskRepository.instance.all.first;
    await TaskRepository.instance.updateStatus(task.id, TaskStatus.inProgress);

    TaskRepository.instance.resetForTesting();
    await TaskRepository.instance.load();

    expect(
      TaskRepository.instance.byId(task.id)!.status,
      TaskStatus.inProgress,
    );
  });
}
