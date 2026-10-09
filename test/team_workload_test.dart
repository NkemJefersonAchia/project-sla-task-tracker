import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:project_sla_task_tracker/models/sla_status.dart';
import 'package:project_sla_task_tracker/models/team_member.dart';
import 'package:project_sla_task_tracker/screens/team/member_card.dart';

void main() {
  test('open count excludes completed tasks', () {
    final counts = {
      SlaStatus.onTrack: 2,
      SlaStatus.atRisk: 1,
      SlaStatus.overdue: 1,
      SlaStatus.completed: 5,
    };
    expect(openTaskCount(counts), 4);
  });

  test('no tasks means zero open', () {
    expect(openTaskCount({}), 0);
  });

  testWidgets('member options button has an accessible label', (tester) async {
    const member = TeamMember(
      id: 'member_1',
      name: 'Alex Morgan',
      role: 'Designer',
      email: 'alex@example.com',
      colorKey: 'blue',
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MemberCard(member: member, onTap: () {}, onMenu: (_) {}),
        ),
      ),
    );

    final optionsButton = find.byTooltip('Member options');
    expect(optionsButton, findsOneWidget);
  });
}
