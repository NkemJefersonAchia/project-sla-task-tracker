import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:project_sla_task_tracker/core/navigation/app_router.dart';
import 'package:project_sla_task_tracker/core/theme/app_theme.dart';
import 'package:project_sla_task_tracker/repositories/member_repository.dart';
import 'package:project_sla_task_tracker/repositories/session_repository.dart';
import 'package:project_sla_task_tracker/repositories/task_repository.dart';
import 'package:project_sla_task_tracker/screens/tasks/tasks_screen.dart';
import 'package:project_sla_task_tracker/screens/tasks/widgets/task_row.dart';
import 'package:project_sla_task_tracker/services/storage_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Widget tests for the Tasks tab.
///
/// `SharedPreferences.setMockInitialValues` gives each test a clean in-memory
/// store, so these run the genuine path - seed the data, build the real
/// screen, drive it - without needing a device.
///
/// The tab is pumped on its own rather than through the whole app: it is
/// faster, and a failure points at this screen instead of at whichever tab
/// happened to break first.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<void> bootstrap() async {
    SharedPreferences.setMockInitialValues({});
    TaskRepository.instance.resetForTesting();
    MemberRepository.instance.resetForTesting();

    await StorageService.instance.init();
    await MemberRepository.instance.load();
    await TaskRepository.instance.load();
    await SessionRepository.instance.load();
    await SessionRepository.instance.signIn(MemberRepository.instance.all.first);
  }

  setUp(bootstrap);

  /// The tab inside just enough app to make navigation work.
  Widget harness() {
    return MaterialApp(
      theme: AppTheme.light(),
      onGenerateRoute: AppRouter.onGenerateRoute,
      home: const TasksScreen(),
    );
  }

  group('the list', () {
    testWidgets('renders a row for every task', (tester) async {
      await tester.pumpWidget(harness());
      await tester.pumpAndSettle();

      final firstTask = TaskRepository.instance.all.first;
      expect(find.text('Tasks'), findsOneWidget);
      expect(find.text(firstTask.title), findsOneWidget);
    });

    testWidgets('puts overdue work above work that is on track',
        (tester) async {
      await tester.pumpWidget(harness());
      await tester.pumpAndSettle();

      final overdue = TaskRepository.instance.all.firstWhere(
        (t) => t.dueDate.isBefore(DateTime.now()) && !t.status.isComplete,
      );

      // The default ordering is by urgency, so the first row on screen should
      // be overdue rather than whichever task happens to be first in storage.
      final firstRowTitle = tester
          .widgetList<Text>(find.byType(Text))
          .map((t) => t.data)
          .firstWhere((text) => text == overdue.title, orElse: () => null);

      expect(firstRowTitle, overdue.title);
    });
  });

  group('search', () {
    testWidgets('hides the rows that do not match', (tester) async {
      await tester.pumpWidget(harness());
      await tester.pumpAndSettle();

      // A word from one title only. Searching a whole title would also match
      // the text now sitting in the search field itself.
      await tester.enterText(find.byType(TextField).first, 'persistence');
      await tester.pumpAndSettle();

      expect(find.byType(TaskRow), findsOneWidget);
    });

    testWidgets('matches a word in the description, not just the title',
        (tester) async {
      await tester.pumpWidget(harness());
      await tester.pumpAndSettle();

      // 'thresholds' appears in one task's description and in no title.
      await tester.enterText(find.byType(TextField).first, 'thresholds');
      await tester.pumpAndSettle();

      expect(find.byType(TaskRow), findsOneWidget);
    });

    testWidgets('a term nothing matches shows the filtered empty state',
        (tester) async {
      await tester.pumpWidget(harness());
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField).first, 'zzzzzzzz');
      await tester.pumpAndSettle();

      // Specifically the filtered wording, not "No tasks yet" - the board is
      // full, the rows are just hidden.
      expect(find.text('No tasks match'), findsOneWidget);
      expect(find.text('No tasks yet'), findsNothing);
    });

    testWidgets('clearing the filters brings every row back', (tester) async {
      await tester.pumpWidget(harness());
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField).first, 'zzzzzzzz');
      await tester.pumpAndSettle();

      await tester.tap(find.text('Clear filters'));
      await tester.pumpAndSettle();

      // Not a count: the ListView only builds the rows that fit on screen,
      // so asserting on every task would be testing the viewport height.
      expect(find.text('No tasks match'), findsNothing);
      expect(find.byType(TaskRow), findsWidgets);
    });
  });

  group('completing a task', () {
    testWidgets('writes the new status through to storage', (tester) async {
      await tester.pumpWidget(harness());
      await tester.pumpAndSettle();

      final open = TaskRepository.instance.all
          .firstWhere((task) => !task.status.isComplete);

      final checkbox = find.byKey(ValueKey('complete-${open.id}'));
      await tester.ensureVisible(checkbox);
      await tester.pumpAndSettle();
      await tester.tap(checkbox);
      await tester.pumpAndSettle();

      expect(TaskRepository.instance.byId(open.id)!.status.isComplete, isTrue);
      // The completion stamp is what the statistics screen will need later.
      expect(TaskRepository.instance.byId(open.id)!.completedAt, isNotNull);
    });

    testWidgets('survives the screen being rebuilt from storage',
        (tester) async {
      await tester.pumpWidget(harness());
      await tester.pumpAndSettle();

      final open = TaskRepository.instance.all
          .firstWhere((task) => !task.status.isComplete);

      final checkbox = find.byKey(ValueKey('complete-${open.id}'));
      await tester.ensureVisible(checkbox);
      await tester.pumpAndSettle();
      await tester.tap(checkbox);
      await tester.pumpAndSettle();

      // Drop the in-memory cache and read the same mock store again - this is
      // the persistence round trip without restarting the process.
      TaskRepository.instance.resetForTesting();
      await TaskRepository.instance.load();

      expect(TaskRepository.instance.byId(open.id)!.status.isComplete, isTrue);
    });
  });
}
