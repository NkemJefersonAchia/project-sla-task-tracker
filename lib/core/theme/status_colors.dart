import 'package:flutter/material.dart';

import '../../models/sla_status.dart';
import '../../models/task_priority.dart';
import '../../models/task_status.dart';
import 'app_colors.dart';

/// A foreground/background colour pair used by every badge in the app.
@immutable
class ColorPair {
  const ColorPair(this.foreground, this.background);

  final Color foreground;
  final Color background;
}

/// Maps domain values onto the palette.
///
/// This is the only place that decides "Overdue is red". Because the list,
/// the detail screen, the dashboard tiles and the statistics screen all read
/// from here, they can never disagree about what a colour means - and
/// re-theming the app is a change to this file alone.
abstract final class StatusColors {
  static ColorPair forSla(BuildContext context, SlaStatus status) {
    final c = AppColors.of(context);
    switch (status) {
      case SlaStatus.onTrack:
        return ColorPair(c.green, c.greenBg);
      case SlaStatus.atRisk:
        return ColorPair(c.yellow, c.yellowBg);
      case SlaStatus.overdue:
        return ColorPair(c.red, c.redBg);
      case SlaStatus.completed:
        return ColorPair(c.gray, c.grayBg);
    }
  }

  /// Icons double up with colour so the status is still readable for someone
  /// who cannot distinguish the hues.
  static IconData iconForSla(SlaStatus status) {
    switch (status) {
      case SlaStatus.onTrack:
        return Icons.check_circle_outline_rounded;
      case SlaStatus.atRisk:
        return Icons.error_outline_rounded;
      case SlaStatus.overdue:
        return Icons.schedule_rounded;
      case SlaStatus.completed:
        return Icons.task_alt_rounded;
    }
  }

  static ColorPair forPriority(BuildContext context, TaskPriority priority) {
    final c = AppColors.of(context);
    switch (priority) {
      case TaskPriority.low:
        return ColorPair(c.gray, c.grayBg);
      case TaskPriority.medium:
        return ColorPair(c.blue, c.blueBg);
      case TaskPriority.high:
        return ColorPair(c.orange, c.orangeBg);
      case TaskPriority.urgent:
        return ColorPair(c.red, c.redBg);
    }
  }

  static ColorPair forTaskStatus(BuildContext context, TaskStatus status) {
    final c = AppColors.of(context);
    switch (status) {
      case TaskStatus.todo:
        return ColorPair(c.gray, c.grayBg);
      case TaskStatus.inProgress:
        return ColorPair(c.blue, c.blueBg);
      case TaskStatus.done:
        return ColorPair(c.green, c.greenBg);
    }
  }

  /// Resolves the accent name stored on a [TeamMember] to a real colour pair.
  static ColorPair forMemberColor(BuildContext context, String colorKey) {
    final c = AppColors.of(context);
    switch (colorKey) {
      case 'blue':
        return ColorPair(c.blue, c.blueBg);
      case 'green':
        return ColorPair(c.green, c.greenBg);
      case 'purple':
        return ColorPair(c.purple, c.purpleBg);
      case 'orange':
        return ColorPair(c.orange, c.orangeBg);
      case 'red':
        return ColorPair(c.red, c.redBg);
      case 'yellow':
        return ColorPair(c.yellow, c.yellowBg);
      default:
        return ColorPair(c.gray, c.grayBg);
    }
  }

  /// The accent names offered when creating a member, in a fixed order so the
  /// colour picker is stable.
  static const List<String> memberColorKeys = [
    'blue',
    'green',
    'purple',
    'orange',
    'red',
    'yellow',
    'gray',
  ];
}
