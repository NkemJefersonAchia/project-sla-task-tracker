import 'package:flutter_test/flutter_test.dart';
import 'package:project_sla_task_tracker/core/utils/validators.dart';

/// Tests for the form rules.
///
/// A validator returns `null` when the value is acceptable, so `isNull` here
/// reads as "this input passes".
void main() {
  final now = DateTime(2026, 6, 10);

  group('taskTitle', () {
    test('rejects empty and whitespace-only titles', () {
      expect(Validators.taskTitle(''), isNotNull);
      expect(Validators.taskTitle('   '), isNotNull);
      expect(Validators.taskTitle(null), isNotNull);
    });

    test('rejects a title shorter than the minimum after trimming', () {
      expect(Validators.taskTitle('  ab  '), isNotNull);
    });

    test('accepts a title exactly at the minimum length', () {
      expect(Validators.taskTitle('abc'), isNull);
    });

    test('rejects a title over the maximum length', () {
      final tooLong = 'x' * (Validators.titleMaxLength + 1);

      expect(Validators.taskTitle(tooLong), isNotNull);
    });
  });

  group('taskDescription', () {
    test('is optional', () {
      expect(Validators.taskDescription(null), isNull);
      expect(Validators.taskDescription(''), isNull);
    });

    test('rejects a description over the limit', () {
      final tooLong = 'x' * (Validators.descriptionMaxLength + 1);

      expect(Validators.taskDescription(tooLong), isNotNull);
    });
  });

  group('assignee', () {
    test('rejects an unset assignee', () {
      expect(Validators.assignee(null), isNotNull);
      expect(Validators.assignee(''), isNotNull);
    });

    test('accepts any member id', () {
      expect(Validators.assignee('member_3'), isNull);
    });
  });

  group('dueDate', () {
    test('requires a date', () {
      expect(Validators.dueDate(null, now: now), isNotNull);
    });

    test('rejects yesterday', () {
      expect(
        Validators.dueDate(now.subtract(const Duration(days: 1)), now: now),
        isNotNull,
      );
    });

    test('accepts today', () {
      // Today is a legitimate deadline, so the boundary must be inclusive.
      expect(Validators.dueDate(now, now: now), isNull);
    });

    test('accepts a date later the same day', () {
      expect(
        Validators.dueDate(DateTime(2026, 6, 10, 23, 59), now: now),
        isNull,
      );
    });

    test('rejects a date beyond the allowed horizon', () {
      final tooFar = DateTime(
        now.year + Validators.maxDueDateYearsAhead,
        now.month,
        now.day + 1,
      );

      expect(Validators.dueDate(tooFar, now: now), isNotNull);
    });
  });

  group('email', () {
    test('accepts ordinary addresses', () {
      expect(Validators.email('amara@teamsla.dev'), isNull);
      expect(Validators.email('first.last+tag@sub.example.co'), isNull);
    });

    test('rejects the common typos', () {
      expect(Validators.email('amara'), isNotNull);
      expect(Validators.email('amara@'), isNotNull);
      expect(Validators.email('amara@teamsla'), isNotNull);
      expect(Validators.email('@teamsla.dev'), isNotNull);
    });

    test('tolerates surrounding whitespace', () {
      expect(Validators.email('  amara@teamsla.dev  '), isNull);
    });
  });

  group('password', () {
    test('rejects anything under the minimum length', () {
      expect(Validators.password('12345'), isNotNull);
    });

    test('accepts the minimum length exactly', () {
      expect(Validators.password('123456'), isNull);
    });
  });
}
