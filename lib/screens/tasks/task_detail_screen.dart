import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/theme/status_colors.dart';
import '../../repositories/task_repository.dart';
import '../../widgets/task/sla_badge.dart';

/// Everything about one task.
///
/// The screen is given a task **id**, not a Task. It re-reads the object from
/// the repository on every build, so an edit made on the form screen is
/// already reflected by the time we pop back here - there is no copy to go
/// stale.
class TaskDetailScreen extends StatefulWidget {
  const TaskDetailScreen({super.key, required this.taskId});

  final String taskId;

  @override
  State<TaskDetailScreen> createState() => _TaskDetailScreenState();
}

class _TaskDetailScreenState extends State<TaskDetailScreen> {
  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final task = TaskRepository.instance.byId(widget.taskId);

    return Scaffold(
      backgroundColor: c.canvas,
      appBar: AppBar(title: const Text('Task')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.screenPadding,
          AppSpacing.sm,
          AppSpacing.screenPadding,
          AppSpacing.xxl,
        ),
        children: [
          if (task!.category.isNotEmpty) ...[
            // The category sits above the title as a quiet label rather than
            // beside it - the same place Notion puts a page's parent.
            ToneBadge(
              label: task.category,
              pair: ColorPair(c.textSecondary, c.surfaceMuted),
            ),
            const SizedBox(height: AppSpacing.md),
          ],
          Text(
            task.title,
            style: AppTypography.pageTitle.copyWith(color: c.textPrimary),
          ),
          if (task.description.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            Text(
              task.description,
              style: AppTypography.body.copyWith(color: c.textSecondary),
            ),
          ],
        ],
      ),
    );
  }
}
