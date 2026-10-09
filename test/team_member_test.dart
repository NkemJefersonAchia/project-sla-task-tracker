import 'package:flutter_test/flutter_test.dart';
import 'package:project_sla_task_tracker/models/team_member.dart';

void main() {
  TeamMember memberNamed(String name) => TeamMember(
    id: 'member_1',
    name: name,
    role: 'Designer',
    email: 'designer@example.com',
    colorKey: 'blue',
  );

  group('TeamMember.initials', () {
    test('uses the first and last initials for a full name', () {
      expect(memberNamed(' Alex Morgan ').initials, 'AM');
    });

    test('uses up to two characters for a single-word name', () {
      expect(memberNamed('alex').initials, 'AL');
      expect(memberNamed('A').initials, 'A');
    });

    test('preserves non-BMP Unicode characters', () {
      expect(memberNamed('😀 Smith').initials, '😀S');
      expect(memberNamed('😀x').initials, '😀X');
    });

    test('uses a fallback for a blank name', () {
      expect(memberNamed('   ').initials, '?');
    });
  });
}
