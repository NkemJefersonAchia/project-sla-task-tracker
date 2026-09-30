import 'package:flutter/material.dart';

import '../../core/constants/app_routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/theme/status_colors.dart';
import '../../core/utils/date_formatting.dart';
import '../../models/task.dart';
import '../../models/task_status.dart';
import '../../repositories/member_repository.dart';
import '../../repositories/task_repository.dart';
import '../../services/sla_service.dart';
import '../../services/storage_service.dart';
import '../../widgets/common/app_buttons.dart';
import '../../widgets/common/app_card.dart';
import '../../widgets/common/app_feedback.dart';
import '../../widgets/common/member_avatar.dart';
import '../../widgets/common/property_row.dart';
import '../../widgets/common/section_header.dart';
import '../../widgets/task/sla_badge.dart';

/// Everything about one task, and the two edits people make most often -
/// changing the status and adding a note - available without leaving it.
///
/// The screen is given a task **id**, not a task. It re-reads the object from
/// the repository on every build, so an edit made on the form screen is
/// already reflected when we pop back here.
class TaskDetailScreen extends StatefulWidget {
  const TaskDetailScreen({super.key, required this.taskId});

  final String taskId;

  @override
  State<TaskDetailScreen> createState() => _TaskDetailScreenState();
}

class _TaskDetailScreenState extends State<TaskDetailScreen> {
  late final TextEditingController _notesController;

  /// True while the notes field differs from what is stored, which is what
  /// enables the Save button.
  bool _notesDirty = false;

  bool _isSavingNotes = false;

  @override
  void initState() {
    super.initState();
    final task = TaskRepository.instance.byId(widget.taskId);
    _notesController = TextEditingController(text: task?.notes ?? '');
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _changeStatus(TaskStatus status) async {
    try {
      await TaskRepository.instance.updateStatus(widget.taskId, status);
      if (!mounted) return;
      setState(() {});
      AppFeedback.showSuccess(context, 'Status set to ${status.label}.');
    } on StorageException catch (error) {
      if (!mounted) return;
      AppFeedback.showError(context, error.message);
    }
  }

  Future<void> _saveNotes(Task task) async {
    setState(() => _isSavingNotes = true);
    try {
      await TaskRepository.instance.save(
        task.copyWith(notes: _notesController.text.trim()),
      );
      if (!mounted) return;
      setState(() {
        _notesDirty = false;
        _isSavingNotes = false;
      });
      AppFeedback.showSuccess(context, 'Notes saved.');
    } on StorageException catch (error) {
      if (!mounted) return;
      setState(() => _isSavingNotes = false);
      AppFeedback.showError(context, error.message);
    }
  }

  Future<void> _edit() async {
    final saved = await Navigator.of(context).pushNamed<bool>(
      AppRoutes.taskForm,
      arguments: TaskFormArgs.edit(widget.taskId),
    );
    if (saved == true && mounted) setState(() {});
  }

  Future<void> _delete(Task task) async {
    final confirmed = await AppFeedback.confirm(
      context,
      title: 'Delete this task?',
      message: '"${task.title}" will be removed from the project. This cannot '
          'be undone.',
    );
    if (!confirmed || !mounted) return;

    try {
      await TaskRepository.instance.delete(task.id);
      if (!mounted) return;
      // Pop with `true` so the list behind us knows to re-read.
      Navigator.of(context).pop(true);
      AppFeedback.showSuccess(context, 'Task deleted.');
    } on StorageException catch (error) {
      if (!mounted) return;
      AppFeedback.showError(context, error.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final task = TaskRepository.instance.byId(widget.taskId);

    // The task can genuinely be gone - deleted from another screen - so the
    // missing case gets a real screen rather than a null-check crash.
    if (task == null) return const _MissingTaskScreen();

    final assignee = MemberRepository.instance.byId(task.assigneeId);
    final sla = SlaService.evaluate(task);
    final slaPair = StatusColors.forSla(context, sla.status);

    return Scaffold(
      backgroundColor: c.canvas,
      appBar: AppBar(
        title: const Text('Task'),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_horiz_rounded),
            tooltip: 'Task actions',
            onSelected: (value) {
              if (value == 'edit') _edit();
              if (value == 'delete') _delete(task);
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'edit', child: Text('Edit task')),
              PopupMenuItem(
                value: 'delete',
                child: Text('Delete task', style: TextStyle(color: c.red)),
              ),
            ],
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.screenPadding,
          AppSpacing.sm,
          AppSpacing.screenPadding,
          AppSpacing.xxl,
        ),
        children: [
          if (task.category.isNotEmpty) ...[
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
          const SizedBox(height: AppSpacing.xl),
          Divider(color: c.border),
          const SizedBox(height: AppSpacing.sm),

          // The property block: the same layout Notion puts under a page
          // title, so the task reads as a record rather than as a form.
          PropertyRow(
            icon: Icons.person_outline_rounded,
            label: 'Assignee',
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                MemberAvatar(member: assignee, size: 22),
                const SizedBox(width: AppSpacing.sm),
                Flexible(
                  child: Text(
                    assignee?.name ?? 'Unassigned',
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.caption.copyWith(
                      color: c.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          PropertyRow(
            icon: Icons.event_outlined,
            label: 'Due date',
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  DateFormatting.full(task.dueDate),
                  style: AppTypography.caption.copyWith(color: c.textPrimary),
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  '· ${DateFormatting.relativeDueDate(task.dueDate)}',
                  style: AppTypography.caption.copyWith(
                    color: sla.daysRemaining < 0 && !task.status.isComplete
                        ? c.red
                        : c.textTertiary,
                  ),
                ),
              ],
            ),
          ),
          PropertyRow(
            icon: Icons.flag_outlined,
            label: 'Priority',
            child: ToneBadge(
              label: task.priority.label,
              pair: StatusColors.forPriority(context, task.priority),
            ),
          ),
          PropertyRow(
            icon: Icons.donut_large_outlined,
            label: 'Status',
            // The status is the one property editable in place, because it is
            // the field that changes several times a week while everything
            // else is usually set once.
            child: _StatusDropdown(
              value: task.status,
              onChanged: _changeStatus,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Divider(color: c.border),
          const SizedBox(height: AppSpacing.xl),

          SectionHeader(title: 'SLA status'),
          AppCard(
            background: slaPair.background,
            borderColor: slaPair.background,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  StatusColors.iconForSla(sla.status),
                  size: 18,
                  color: slaPair.foreground,
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        sla.status.label,
                        style: AppTypography.bodyStrong.copyWith(
                          color: slaPair.foreground,
                        ),
                      ),
                      const SizedBox(height: 2),
                      // The explanation comes from SlaService, so the reason
                      // shown to the user is generated by the same code that
                      // made the decision - they cannot drift apart.
                      Text(
                        sla.explanation,
                        style: AppTypography.caption.copyWith(
                          color: slaPair.foreground,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),

          SectionHeader(
            title: 'Notes',
            action: _notesDirty
                ? SectionAction(
                    label: _isSavingNotes ? 'Saving…' : 'Save',
                    onPressed: () => _saveNotes(task),
                  )
                : null,
          ),
          TextField(
            controller: _notesController,
            maxLines: 4,
            minLines: 3,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
              hintText: 'Add context, blockers or a handover note…',
            ),
            onChanged: (value) {
              // Only rebuild when the dirty flag actually flips, not on every
              // keystroke.
              final dirty = value.trim() != task.notes.trim();
              if (dirty != _notesDirty) setState(() => _notesDirty = dirty);
            },
          ),
          const SizedBox(height: AppSpacing.xl),

          _Timestamps(task: task),
          const SizedBox(height: AppSpacing.xl),

          PrimaryButton(
            label: 'Edit task',
            icon: Icons.edit_outlined,
            onPressed: _edit,
          ),
          const SizedBox(height: AppSpacing.md),
          SecondaryButton(
            label: 'Delete task',
            icon: Icons.delete_outline_rounded,
            destructive: true,
            onPressed: () => _delete(task),
          ),
        ],
      ),
    );
  }
}

/// Inline status picker rendered as a tinted badge with a chevron.
class _StatusDropdown extends StatelessWidget {
  const _StatusDropdown({required this.value, required this.onChanged});

  final TaskStatus value;
  final ValueChanged<TaskStatus> onChanged;

  @override
  Widget build(BuildContext context) {
    final pair = StatusColors.forTaskStatus(context, value);

    return PopupMenuButton<TaskStatus>(
      initialValue: value,
      tooltip: 'Change status',
      onSelected: onChanged,
      itemBuilder: (context) => [
        for (final status in TaskStatus.values)
          PopupMenuItem(value: status, child: Text(status.label)),
      ],
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: 4,
        ),
        decoration: BoxDecoration(
          color: pair.background,
          borderRadius: BorderRadius.circular(AppRadius.sm),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              value.label,
              style: AppTypography.badge.copyWith(color: pair.foreground),
            ),
            const SizedBox(width: 2),
            Icon(
              Icons.keyboard_arrow_down_rounded,
              size: 15,
              color: pair.foreground,
            ),
          ],
        ),
      ),
    );
  }
}

/// Created / last updated / completed, in small muted type at the foot of the
/// page - useful during a stand-up, not important enough for the main block.
class _Timestamps extends StatelessWidget {
  const _Timestamps({required this.task});

  final Task task;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final style = AppTypography.caption.copyWith(color: c.textTertiary);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Created ${DateFormatting.withTime(task.createdAt)}', style: style),
        Text('Updated ${DateFormatting.timeAgo(task.updatedAt)}', style: style),
        if (task.completedAt != null)
          Text(
            'Completed ${DateFormatting.withTime(task.completedAt!)}',
            style: style,
          ),
      ],
    );
  }
}

/// Shown when the task behind this route no longer exists.
class _MissingTaskScreen extends StatelessWidget {
  const _MissingTaskScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Task')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.search_off_rounded, size: 28),
              const SizedBox(height: AppSpacing.md),
              Text(
                'This task no longer exists.',
                style: AppTypography.bodyStrong,
              ),
              const SizedBox(height: AppSpacing.lg),
              SecondaryButton(
                label: 'Back to tasks',
                expand: false,
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
