import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:project_sla_task_tracker/models/task.dart';
import 'package:project_sla_task_tracker/models/task_priority.dart';
import 'package:project_sla_task_tracker/models/task_status.dart';
import 'package:project_sla_task_tracker/models/team_member.dart';
import 'package:project_sla_task_tracker/repositories/member_repository.dart';
import 'package:project_sla_task_tracker/repositories/session_repository.dart';
import 'package:project_sla_task_tracker/repositories/task_repository.dart';
import 'package:project_sla_task_tracker/screens/team/member_form_screen.dart';
import 'package:project_sla_task_tracker/screens/team/member_tasks_sheet.dart';
import 'package:project_sla_task_tracker/screens/team/team_screen.dart';
import 'package:project_sla_task_tracker/services/storage_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  SharedPreferences.setMockInitialValues({
    StorageKeys.members: '[]',
    StorageKeys.tasks: '[]',
    StorageKeys.currentUserId: 'self',
  });

  setUpAll(() async {
    await StorageService.instance.init();
    await SessionRepository.instance.load();
  });

  setUp(() async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.clear();
    await preferences.setString(StorageKeys.members, '[]');
    await preferences.setString(StorageKeys.tasks, '[]');
    await preferences.setString(StorageKeys.currentUserId, 'self');

    MemberRepository.instance.resetForTesting();
    TaskRepository.instance.resetForTesting();
    await MemberRepository.instance.load();
    await TaskRepository.instance.load();
  });

  testWidgets('valid member details are saved and return success', (
    tester,
  ) async {
    bool? saveResult;
    await tester.pumpWidget(_formHost((result) => saveResult = result));
    await tester.tap(find.text('Open form'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField).at(0), 'Alex Morgan');
    await tester.enterText(find.byType(TextFormField).at(1), 'Designer');
    await tester.enterText(
      find.byType(TextFormField).at(2),
      'alex@example.com',
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Add member'));
    await tester.pumpAndSettle();

    expect(saveResult, isTrue);
    expect(MemberRepository.instance.all.single.name, 'Alex Morgan');
    expect(MemberRepository.instance.all.single.email, 'alex@example.com');
  });

  testWidgets('unsaved member edits prompt before they are discarded', (
    tester,
  ) async {
    await tester.pumpWidget(_formHost());
    await tester.tap(find.text('Open form'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).first, 'Alex Morgan');
    await tester.pump();

    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();
    expect(find.text('Discard changes?'), findsOneWidget);

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(find.text('Add member'), findsWidgets);
    expect(MemberRepository.instance.all, isEmpty);
  });

  testWidgets('signed-in member cannot be deleted', (tester) async {
    final member = _member('self', 'Signed In');
    await MemberRepository.instance.save(member);
    await tester.pumpWidget(const MaterialApp(home: TeamScreen()));

    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete'));
    await tester.pump();

    expect(
      find.text('You cannot delete the member you are signed in as.'),
      findsOneWidget,
    );
    expect(MemberRepository.instance.byId('self'), isNotNull);
  });

  testWidgets('deleting a member unassigns their tasks', (tester) async {
    await MemberRepository.instance.save(_member('self', 'Signed In'));
    await MemberRepository.instance.save(_member('colleague', 'Colleague'));
    await TaskRepository.instance.save(_task('task_1', 'colleague', 2));
    await TaskRepository.instance.save(_task('task_2', 'colleague', 3));
    await tester.pumpWidget(const MaterialApp(home: TeamScreen()));

    await tester.tap(find.byIcon(Icons.more_vert).at(1));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();
    expect(
      find.text('2 assigned task(s) will become unassigned.'),
      findsOneWidget,
    );

    await tester.tap(find.widgetWithText(TextButton, 'Delete'));
    await tester.pumpAndSettle();

    expect(MemberRepository.instance.byId('colleague'), isNull);
    expect(TaskRepository.instance.byAssignee('colleague'), isEmpty);
    expect(
      TaskRepository.instance.all.map((task) => task.assigneeId),
      everyElement(isEmpty),
    );
  });

  testWidgets('member task sheet shows the soonest deadline first', (
    tester,
  ) async {
    final member = _member('member_1', 'Alex Morgan');
    await TaskRepository.instance.save(_task('later', member.id, 10));
    await TaskRepository.instance.save(_task('sooner', member.id, 2));
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: MemberTasksSheet(member: member)),
      ),
    );

    final soonerY = tester.getTopLeft(find.text('Task sooner')).dy;
    final laterY = tester.getTopLeft(find.text('Task later')).dy;
    expect(soonerY, lessThan(laterY));
  });
}

Widget _formHost([ValueChanged<bool?>? onResult]) => MaterialApp(
  home: Builder(
    builder: (context) => Scaffold(
      body: TextButton(
        onPressed: () async {
          final result = await Navigator.of(context).push<bool>(
            MaterialPageRoute<bool>(builder: (_) => const MemberFormScreen()),
          );
          onResult?.call(result);
        },
        child: const Text('Open form'),
      ),
    ),
  ),
);

TeamMember _member(String id, String name) => TeamMember(
  id: id,
  name: name,
  role: 'Designer',
  email: '$id@example.com',
  colorKey: 'blue',
);

Task _task(String id, String assigneeId, int daysUntilDue) {
  final today = Task.dateOnly(DateTime.now());
  return Task(
    id: id,
    title: 'Task $id',
    description: '',
    category: 'Testing',
    assigneeId: assigneeId,
    dueDate: today.add(Duration(days: daysUntilDue)),
    priority: TaskPriority.medium,
    status: TaskStatus.inProgress,
    createdAt: today,
    updatedAt: today,
  );
}
