import 'package:flutter_test/flutter_test.dart';
import 'package:project_sla_task_tracker/app.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:project_sla_task_tracker/core/theme/theme_controller.dart';
import 'package:project_sla_task_tracker/repositories/member_repository.dart';
import 'package:project_sla_task_tracker/repositories/session_repository.dart';
import 'package:project_sla_task_tracker/repositories/task_repository.dart';
import 'package:project_sla_task_tracker/services/storage_service.dart';

/// Smoke test: the app boots and renders without throwing.
///
/// This replaces the counter test the Flutter template ships with, which
/// referenced a MyApp class this project has never had.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('the app starts up and builds a frame', (tester) async {
    SharedPreferences.setMockInitialValues({});
    TaskRepository.instance.resetForTesting();
    MemberRepository.instance.resetForTesting();

    await StorageService.instance.init();
    await ThemeController.instance.load();
    await MemberRepository.instance.load();
    await TaskRepository.instance.load();
    await SessionRepository.instance.load();

    await tester.pumpWidget(const TaskTrackerApp());
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });
}
