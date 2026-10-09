import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:project_sla_task_tracker/app.dart';
import 'package:project_sla_task_tracker/core/theme/theme_controller.dart';
import 'package:project_sla_task_tracker/repositories/member_repository.dart';
import 'package:project_sla_task_tracker/repositories/session_repository.dart';
import 'package:project_sla_task_tracker/repositories/task_repository.dart';
import 'package:project_sla_task_tracker/services/storage_service.dart';

void main() {
  setUp(() async {
    // Fake, empty device storage so the test never touches real data.
    SharedPreferences.setMockInitialValues({});

    // Same start-up order as main.dart.
    await StorageService.instance.init();
    await ThemeController.instance.load();
    await MemberRepository.instance.load();
    await TaskRepository.instance.load();
    await SessionRepository.instance.load();
  });

  testWidgets('opens on the login screen when signed out', (tester) async {
    await tester.pumpWidget(const TaskTrackerApp());
    await tester.pumpAndSettle();

    expect(find.text('Plan. Track. Deliver Together.'), findsOneWidget);
    expect(find.text('Sign In'), findsOneWidget);
  });
}