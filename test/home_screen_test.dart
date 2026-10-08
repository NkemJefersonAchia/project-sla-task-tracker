import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:project_sla_task_tracker/core/navigation/app_router.dart';
import 'package:project_sla_task_tracker/core/theme/app_theme.dart';
import 'package:project_sla_task_tracker/models/sla_status.dart';
import 'package:project_sla_task_tracker/models/task.dart';
import 'package:project_sla_task_tracker/models/task_priority.dart';
import 'package:project_sla_task_tracker/models/task_status.dart';
import 'package:project_sla_task_tracker/repositories/member_repository.dart';
import 'package:project_sla_task_tracker/repositories/session_repository.dart';
import 'package:project_sla_task_tracker/repositories/task_repository.dart';
import 'package:project_sla_task_tracker/screens/home/home_screen.dart';
import 'package:project_sla_task_tracker/screens/home/widgets/deadline_histogram.dart';
import 'package:project_sla_task_tracker/screens/home/widgets/metric_tile.dart';
import 'package:project_sla_task_tracker/screens/home/widgets/sla_ring_chart.dart';
import 'package:project_sla_task_tracker/screens/tasks/widgets/task_row.dart';
import 'package:project_sla_task_tracker/services/sla_service.dart';
import 'package:project_sla_task_tracker/services/storage_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Widget tests for the dashboard.
///
/// The screen derives everything it shows, so the tests mostly check that the
/// derivation matches the data rather than that particular pixels appeared.
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

  /// Scrolls the dashboard to the bottom.
  ///
  /// The test viewport is shorter than a phone and the page's ListView builds
  /// lazily, so the lower sections do not exist until they are scrolled near.
  Future<void> scrollToBottom(WidgetTester tester) async {
    await tester.drag(find.byType(ListView), const Offset(0, -900));
    await tester.pumpAndSettle();
  }

  /// The tab on its own, inside just enough app for navigation to work.
  Widget harness({void Function(SlaStatus?)? onOpenTasks}) {
    return MaterialApp(
      theme: AppTheme.light(),
      onGenerateRoute: AppRouter.onGenerateRoute,
      home: HomeScreen(onOpenTasks: onOpenTasks ?? (_) {}),
    );
  }

  group('the counters', () {
    testWidgets('there are four of them', (tester) async {
      await tester.pumpWidget(harness());
      await tester.pumpAndSettle();

      expect(find.byType(MetricTile), findsNWidgets(4));
      expect(find.text('Total tasks'), findsOneWidget);
    });

    testWidgets('they agree with what SlaService reports', (tester) async {
      await tester.pumpWidget(harness());
      await tester.pumpAndSettle();

      final counts = SlaService.summarise(TaskRepository.instance.all);

      final tiles = tester.widgetList<MetricTile>(find.byType(MetricTile));
      final byLabel = {for (final t in tiles) t.label: t.value};

      expect(byLabel['Total tasks'], TaskRepository.instance.all.length);
      expect(byLabel['Overdue'], counts[SlaStatus.overdue]);
      expect(byLabel['At Risk'], counts[SlaStatus.atRisk]);
      expect(byLabel['On Track'], counts[SlaStatus.onTrack]);
    });

    testWidgets('tapping one asks for that filter', (tester) async {
      SlaStatus? requested;
      var called = false;

      await tester.pumpWidget(harness(onOpenTasks: (s) {
        requested = s;
        called = true;
      }));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Overdue').first);
      await tester.pumpAndSettle();

      expect(called, isTrue);
      expect(requested, SlaStatus.overdue);
    });
  });

  group('the charts', () {
    testWidgets('both render', (tester) async {
      await tester.pumpWidget(harness());
      await tester.pumpAndSettle();

      expect(find.byType(SlaRingChart), findsOneWidget);
      expect(find.byType(DeadlineHistogram), findsOneWidget);
    });

    testWidgets('the ring survives a project with no tasks', (tester) async {
      // The grey track should still draw rather than the card collapsing.
      for (final task in TaskRepository.instance.all.toList()) {
        await TaskRepository.instance.delete(task.id);
      }

      await tester.pumpWidget(harness());
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byType(SlaRingChart), findsOneWidget);
    });

    testWidgets('the histogram counts overdue work into its first column',
        (tester) async {
      final now = DateTime(2026, 6, 10);
      final overdue = Task(
        id: 'late',
        title: 'Late task',
        description: '',
        category: 'Testing',
        assigneeId: 'member_1',
        dueDate: DateTime(2026, 6, 1),
        priority: TaskPriority.high,
        status: TaskStatus.todo,
        createdAt: now,
        updatedAt: now,
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          home: Scaffold(
            body: DeadlineHistogram(tasks: [overdue], now: now),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Overdue work must be collected, not silently dropped off the chart.
      // Asserted through the tooltip because Tooltip merges its own semantics
      // over the inner label, and the tooltip is what a user actually gets.
      expect(find.byTooltip('1 overdue'), findsOneWidget);
    });

    testWidgets('a finished task is not plotted as upcoming work',
        (tester) async {
      final now = DateTime(2026, 6, 10);
      final done = Task(
        id: 'done',
        title: 'Finished',
        description: '',
        category: 'Testing',
        assigneeId: 'member_1',
        dueDate: DateTime(2026, 6, 12),
        priority: TaskPriority.low,
        status: TaskStatus.done,
        createdAt: now,
        updatedAt: now,
        completedAt: now,
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          home: Scaffold(
            body: DeadlineHistogram(tasks: [done], now: now),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('No unfinished work'), findsOneWidget);
    });
  });

  group('needs attention', () {
    testWidgets('lists overdue and at-risk work, soonest first',
        (tester) async {
      await tester.pumpWidget(harness());
      await tester.pumpAndSettle();
      await scrollToBottom(tester);

      final expected = TaskRepository.instance.all
          .where((t) => SlaService.statusOf(t).needsAttention)
          .length;

      // Capped at three - this is a summary, not a second task list.
      expect(
        find.byType(TaskRow),
        findsNWidgets(expected > 3 ? 3 : expected),
      );
    });

    testWidgets('says so when nothing needs attention', (tester) async {
      for (final task in TaskRepository.instance.all.toList()) {
        if (SlaService.statusOf(task).needsAttention) {
          await TaskRepository.instance.updateStatus(task.id, TaskStatus.done);
        }
      }

      await tester.pumpWidget(harness());
      await tester.pumpAndSettle();
      await scrollToBottom(tester);

      expect(find.textContaining('Nothing is overdue'), findsOneWidget);
      expect(find.byType(TaskRow), findsNothing);
    });
  });
}
