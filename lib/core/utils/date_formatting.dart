import 'package:intl/intl.dart';

import '../../models/task.dart';

/// Date presentation helpers.
///
/// Formatting lives here rather than inside widgets so that a deadline reads
/// identically on the list, the detail screen and the dashboard.
abstract final class DateFormatting {
  static final DateFormat _fullDate = DateFormat('d MMM yyyy');
  static final DateFormat _shortDate = DateFormat('d MMM');
  static final DateFormat _dateTime = DateFormat('d MMM yyyy, HH:mm');

  /// "12 Dec 2026"
  static String full(DateTime value) => _fullDate.format(value);

  /// "12 Dec 2026, 14:05" - used for created/updated stamps.
  static String withTime(DateTime value) => _dateTime.format(value);

  /// A deadline written the way a person would say it out loud: "Today",
  /// "Tomorrow", "in 4 days", "3 days ago". Falls back to the calendar date
  /// once the distance stops being meaningful.
  static String relativeDueDate(DateTime dueDate, {DateTime? now}) {
    final today = Task.dateOnly(now ?? DateTime.now());
    final due = Task.dateOnly(dueDate);
    final days = due.difference(today).inDays;

    if (days == 0) return 'Due today';
    if (days == 1) return 'Due tomorrow';
    if (days == -1) return '1 day overdue';
    if (days < -1) return '${days.abs()} days overdue';
    if (days <= 7) return 'Due in $days days';
    return 'Due ${_shortDate.format(due)}';
  }

  /// Compact "2 hours ago" style stamp for activity rows.
  static String timeAgo(DateTime value, {DateTime? now}) {
    final reference = now ?? DateTime.now();
    final difference = reference.difference(value);

    if (difference.inMinutes < 1) return 'just now';
    if (difference.inMinutes < 60) return '${difference.inMinutes}m ago';
    if (difference.inHours < 24) return '${difference.inHours}h ago';
    if (difference.inDays < 7) return '${difference.inDays}d ago';
    return _shortDate.format(value);
  }

  /// "Good morning" / "Good afternoon" / "Good evening" for the dashboard.
  static String greeting({DateTime? now}) {
    final hour = (now ?? DateTime.now()).hour;
    if (hour < 12) return 'Good morning';
    if (hour < 18) return 'Good afternoon';
    return 'Good evening';
  }
}
