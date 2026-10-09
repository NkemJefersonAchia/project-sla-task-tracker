import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:project_sla_task_tracker/repositories/member_repository.dart';
import 'package:project_sla_task_tracker/screens/team/member_form_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('storage failure reports an error and keeps the form open', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => Navigator.of(context).push<void>(
                MaterialPageRoute<void>(
                  builder: (_) => const MemberFormScreen(),
                ),
              ),
              child: const Text('Open form'),
            ),
          ),
        ),
      ),
    );
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

    expect(
      find.text('Could not save the member. Please try again.'),
      findsOneWidget,
    );
    expect(find.text('Add member'), findsWidgets);
    expect(MemberRepository.instance.all, hasLength(1));
  });
}
