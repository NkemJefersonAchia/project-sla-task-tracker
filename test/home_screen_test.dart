import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:project_sla_task_tracker/core/navigation/app_router.dart';
import 'package:project_sla_task_tracker/core/navigation/tasks_filter_bridge.dart';
import 'package:project_sla_task_tracker/core/theme/app_theme.dart';
import 'package:project_sla_task_tracker/models/sla_status.dart';
import 'package:project_sla_task_tracker/models/task_status.dart';
import 'package:project_sla_task_tracker/repositories/member_repository.dart';
import 'package:project_sla_task_tracker/repositories/session_repository.dart';
import 'package:project_sla_task_tracker/repositories/task_repository.dart';
import 'package:project_sla_task_tracker/screens/home/home_screen.dart';
import 'package:project_sla_task_tracker/screens/home/widgets/sla_health_strip.dart';
import 'package:project_sla_task_tracker/screens/tasks/widgets/task_row.dart';
import 'package:project_sla_task_tracker/services/storage_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Widget tests for the agenda dashboard.
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

  Widget harness() => MaterialApp(
        theme: AppTheme.light(),
        onGenerateRoute: AppRouter.onGenerateRoute,
        home: const HomeScreen(),
      );

  testWidgets('leads with a headline and the SLA band', (tester) async {
    await tester.pumpWidget(harness());
    await tester.pumpAndSettle();

    expect(find.byType(SlaHealthStrip), findsOneWidget);
    expect(find.textContaining('need'), findsWidgets);
  });

  testWidgets('groups unfinished work by when it is due', (tester) async {
    await tester.pumpWidget(harness());
    await tester.pumpAndSettle();

    expect(find.text('OVERDUE'), findsOneWidget);
    expect(find.text('DUE TODAY'), findsOneWidget);
    expect(find.byType(TaskRow), findsWidgets);
  });

  testWidgets('completed work never appears on the agenda', (tester) async {
    final done = TaskRepository.instance.all
        .where((t) => t.status.isComplete)
        .map((t) => t.title)
        .toList();

    await tester.pumpWidget(harness());
    await tester.pumpAndSettle();

    for (final title in done) {
      expect(find.text(title), findsNothing);
    }
  });

  testWidgets('tapping a band label asks the bridge for that filter',
      (tester) async {
    TasksFilterRequest? seen;
    void listener() => seen = TasksFilterBridge.requests.value;
    TasksFilterBridge.requests.addListener(listener);
    addTearDown(() => TasksFilterBridge.requests.removeListener(listener));

    await tester.pumpWidget(harness());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Overdue').first);
    await tester.pumpAndSettle();

    expect(seen?.slaFilter, SlaStatus.overdue);
  });

  testWidgets('says so when the near horizon is clear', (tester) async {
    for (final task in TaskRepository.instance.all.toList()) {
      await TaskRepository.instance.updateStatus(task.id, TaskStatus.done);
    }

    await tester.pumpWidget(harness());
    await tester.pumpAndSettle();

    expect(find.textContaining('Nothing needs you'), findsOneWidget);
  });
}
