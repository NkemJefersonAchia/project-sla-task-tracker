import '../../models/task.dart';

/// Form validation rules, kept out of the widgets so the same rule can be
/// reused by more than one screen and unit-tested on its own.
///
/// Every method follows Flutter's `FormFieldValidator` contract: return `null`
/// when the value is acceptable, or the message to display when it is not.
abstract final class Validators {
  static const int titleMinLength = 3;
  static const int titleMaxLength = 80;
  static const int descriptionMaxLength = 500;

  /// How far ahead a deadline may be set. A five-year deadline is almost
  /// always a typo in the year field, so we reject it at the source.
  static const int maxDueDateYearsAhead = 2;

  static String? required(String? value, {String field = 'This field'}) {
    if (value == null || value.trim().isEmpty) {
      return '$field is required.';
    }
    return null;
  }

  static String? taskTitle(String? value) {
    final empty = required(value, field: 'Task title');
    if (empty != null) return empty;

    final trimmed = value!.trim();
    if (trimmed.length < titleMinLength) {
      return 'Use at least $titleMinLength characters so the task is '
          'recognisable in the list.';
    }
    if (trimmed.length > titleMaxLength) {
      return 'Keep the title under $titleMaxLength characters '
          '(${trimmed.length} used).';
    }
    return null;
  }

  /// The description is optional, but if one is written it has to stay short
  /// enough to read on a phone.
  static String? taskDescription(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    if (value.trim().length > descriptionMaxLength) {
      return 'Descriptions are limited to $descriptionMaxLength characters.';
    }
    return null;
  }

  static String? category(String? value) =>
      required(value, field: 'Category');

  /// The assignee comes from a dropdown, so the only failure case is "nothing
  /// picked yet" - but we still validate it, because a task nobody owns can
  /// never be chased when its SLA turns red.
  static String? assignee(String? memberId) {
    if (memberId == null || memberId.isEmpty) {
      return 'Assign the task to a team member.';
    }
    return null;
  }

  /// Deadline rules: one must be chosen, and it cannot be in the past (you
  /// cannot commit to a date that has already gone) or absurdly far ahead.
  /// [now] is injectable so the rule can be tested against a fixed date.
  static String? dueDate(DateTime? value, {DateTime? now}) {
    if (value == null) return 'Choose a due date.';

    final today = Task.dateOnly(now ?? DateTime.now());
    final due = Task.dateOnly(value);

    if (due.isBefore(today)) {
      return 'The due date cannot be in the past.';
    }
    final limit = DateTime(
      today.year + maxDueDateYearsAhead,
      today.month,
      today.day,
    );
    if (due.isAfter(limit)) {
      return 'Choose a date within the next $maxDueDateYearsAhead years.';
    }
    return null;
  }

  /// Sign-in email check. A single tightly-scoped pattern is enough here: it
  /// catches the realistic typos (missing @, missing domain, trailing dot)
  /// without pretending to implement the full RFC.
  static String? email(String? value) {
    final empty = required(value, field: 'Email');
    if (empty != null) return empty;

    final pattern = RegExp(r'^[\w.+-]+@[\w-]+\.[\w.-]+$');
    if (!pattern.hasMatch(value!.trim())) {
      return 'Enter a valid email address, for example name@team.dev.';
    }
    return null;
  }

  static const int passwordMinLength = 6;

  static String? password(String? value) {
    final empty = required(value, field: 'Password');
    if (empty != null) return empty;

    if (value!.length < passwordMinLength) {
      return 'Passwords are at least $passwordMinLength characters.';
    }
    return null;
  }

  static String? personName(String? value) {
    final empty = required(value, field: 'Name');
    if (empty != null) return empty;
    if (value!.trim().length < 2) {
      return 'Enter the full name.';
    }
    return null;
  }
}
