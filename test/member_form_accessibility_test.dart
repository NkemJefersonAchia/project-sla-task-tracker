import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:project_sla_task_tracker/screens/team/member_form_screen.dart';

void main() {
  testWidgets('accent colours are labelled buttons with selection state', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();

    await tester.pumpWidget(const MaterialApp(home: MemberFormScreen()));

    final blue = find.bySemanticsLabel('blue accent colour');
    final green = find.bySemanticsLabel('green accent colour');

    expect(blue, findsOneWidget);
    expect(green, findsOneWidget);
    expect(tester.getSemantics(blue).hasFlag(SemanticsFlag.isButton), isTrue);
    expect(tester.getSemantics(blue).hasFlag(SemanticsFlag.isSelected), isTrue);
    expect(
      tester.getSemantics(green).hasFlag(SemanticsFlag.isSelected),
      isFalse,
    );

    await tester.ensureVisible(green);
    await tester.tap(green);
    await tester.pump();

    expect(
      tester.getSemantics(green).hasFlag(SemanticsFlag.isSelected),
      isTrue,
    );
    semantics.dispose();
  });
}
