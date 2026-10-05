import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../models/task.dart';
import '../../../widgets/common/app_card.dart';

/// One task as it appears in the list.
///
/// Deliberately dumb: it is handed the task and a callback, and owns no state.
/// Every decision - what the SLA is, who the assignee is - belongs to the
/// screen above it, so this widget can be dropped into any list.
class TaskRow extends StatelessWidget {
  const TaskRow({
    super.key,
    required this.task,
    required this.onTap,
  });

  final Task task;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);

    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.md,
      ),
      child: Text(
        task.title,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: AppTypography.bodyStrong.copyWith(color: c.textPrimary),
      ),
    );
  }
}
