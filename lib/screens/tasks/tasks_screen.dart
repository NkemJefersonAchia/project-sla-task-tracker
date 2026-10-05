import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../repositories/member_repository.dart';
import '../../repositories/task_repository.dart';
import 'widgets/task_row.dart';

/// The Tasks tab: every task on the project, most urgent first.
///
/// The screen reads `TaskRepository.instance.all` inside `build`. The
/// repository is already in memory, so there is no future to await and no
/// spinner to show - and because nothing is cached here, a change made on
/// another tab is visible the moment this one rebuilds.
class TasksScreen extends StatefulWidget {
  const TasksScreen({super.key});

  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen> {
  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final tasks = TaskRepository.instance.all;

    return Scaffold(
      backgroundColor: c.canvas,
      body: SafeArea(
        child: Column(
          children: [
            _Header(total: tasks.length),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.screenPadding,
                  AppSpacing.sm,
                  AppSpacing.screenPadding,
                  AppSpacing.xxl,
                ),
                itemCount: tasks.length,
          // A gap between rows rather than a divider: the cards already have
          // their own hairline, and stacking a divider on top of a border
          // gives you a 2px line that reads as a mistake.
                separatorBuilder: (_, _) =>
                    const SizedBox(height: AppSpacing.sm),
                itemBuilder: (context, index) {
                  final task = tasks[index];
                  return TaskRow(
                    task: task,
                    assignee:
                        MemberRepository.instance.byId(task.assigneeId),
                    onTap: () {},
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The page title and a live count.
///
/// Notion puts the page title in the body rather than in a chrome app bar, at
/// a size that makes it obviously a heading, with everything else quieter
/// around it. There is no AppBar on this screen for that reason.
class _Header extends StatelessWidget {
  const _Header({required this.total});

  final int total;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screenPadding,
        AppSpacing.lg,
        AppSpacing.screenPadding,
        AppSpacing.md,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(child: Text('Tasks', style: AppTypography.pageTitle)),
          Text(
            total == 1 ? '1 task' : '$total tasks',
            style: AppTypography.caption.copyWith(color: c.textTertiary),
          ),
        ],
      ),
    );
  }
}
