import 'dart:ui' show Tristate;

import 'package:flutter/material.dart';
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
    expect(
      tester.getSemantics(blue).getSemanticsData().flagsCollection.isButton,
      isTrue,
    );
    expect(
      tester.getSemantics(blue).getSemanticsData().flagsCollection.isSelected,
      Tristate.isTrue,
    );
    expect(
      tester.getSemantics(green).getSemanticsData().flagsCollection.isSelected,
      Tristate.isFalse,
    );

    await tester.ensureVisible(green);
    await tester.tap(green);
    await tester.pump();

    expect(
      tester.getSemantics(green).getSemanticsData().flagsCollection.isSelected,
      Tristate.isTrue,
    );
    semantics.dispose();
  });
}
