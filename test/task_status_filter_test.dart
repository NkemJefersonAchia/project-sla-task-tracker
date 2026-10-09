import 'package:flutter_test/flutter_test.dart';
import 'package:project_sla_task_tracker/models/sla_status.dart';
import 'package:project_sla_task_tracker/models/task.dart';
import 'package:project_sla_task_tracker/models/task_priority.dart';
import 'package:project_sla_task_tracker/models/task_status.dart';
import 'package:project_sla_task_tracker/repositories/task_repository.dart';
import 'package:project_sla_task_tracker/services/storage_service.dart';
import 'package:project_sla_task_tracker/services/task_query.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  SharedPreferences.setMockInitialValues({StorageKeys.tasks: '[]'});

  setUpAll(() async {
    await StorageService.instance.init();
    await TaskRepository.instance.load();
  });

  test('SLA filters reflect a task status change immediately', () async {
    final now = DateTime(2026, 6, 10);
    final repository = TaskRepository.instance;
    repository.resetForTesting();
    await repository.load();
    await repository.save(
      Task(
        id: 'filter_test_task',
        title: 'Finish report',
        description: '',
        category: 'Work',
        assigneeId: 'member_1',
        dueDate: DateTime(2026, 6, 9),
        priority: TaskPriority.medium,
        status: TaskStatus.inProgress,
        createdAt: now,
        updatedAt: now,
      ),
    );

    expect(
      const TaskQuery(slaFilter: SlaStatus.overdue)
          .apply(repository.all, now: now)
          .map((task) => task.id),
      contains('filter_test_task'),
    );

    await repository.updateStatus('filter_test_task', TaskStatus.done);

    expect(
      const TaskQuery(slaFilter: SlaStatus.completed)
          .apply(repository.all, now: now)
          .map((task) => task.id),
      contains('filter_test_task'),
    );
    expect(
      const TaskQuery(slaFilter: SlaStatus.overdue)
          .apply(repository.all, now: now)
          .map((task) => task.id),
      isNot(contains('filter_test_task')),
    );
  });
}
