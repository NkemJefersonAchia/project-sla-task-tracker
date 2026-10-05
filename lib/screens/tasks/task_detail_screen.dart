import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/theme/status_colors.dart';
import '../../core/utils/date_formatting.dart';
import '../../models/sla_status.dart';
import '../../models/task.dart';
import '../../models/task_status.dart';
import '../../repositories/member_repository.dart';
import '../../repositories/task_repository.dart';
import '../../services/sla_service.dart';
import '../../services/storage_service.dart';
import '../../widgets/common/app_card.dart';
import '../../widgets/common/app_feedback.dart';
import '../../widgets/common/section_header.dart';
import '../../widgets/common/member_avatar.dart';
import '../../widgets/common/property_row.dart';
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
  late final TextEditingController _notesController;

  /// True while the field differs from what is stored. It is what enables the
  /// Save action, so an untouched field offers nothing to press.
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
      // Pop true so the list behind knows to re-read rather than rendering a
      // row for a task that no longer exists.
      Navigator.of(context).pop(true);
      AppFeedback.showSuccess(context, 'Task deleted.');
    } on StorageException catch (error) {
      if (!mounted) return;
      AppFeedback.showError(context, error.message);
    }
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

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final task = TaskRepository.instance.byId(widget.taskId);
    final assignee = MemberRepository.instance.byId(task?.assigneeId);
    final sla = task == null ? null : SlaService.evaluate(task);

    return Scaffold(
      backgroundColor: c.canvas,
      appBar: AppBar(
        title: const Text('Task'),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_horiz_rounded),
            tooltip: 'Task actions',
            onSelected: (value) {
              if (value == 'delete') _delete(task!);
            },
            itemBuilder: (context) => [
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
          const SizedBox(height: AppSpacing.xl),
          Divider(color: c.border),
          const SizedBox(height: AppSpacing.sm),

          // The property block. A fixed-width label column means the rows
          // line up into a clean vertical rule, which is what makes this read
          // as a record rather than as loose text.
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
                  // The exact date and the human reading of it, together: one
                  // is unambiguous, the other is the one you actually act on.
                  DateFormatting.relativeDueDate(task.dueDate),
                  style: AppTypography.caption.copyWith(
                    color: sla!.status == SlaStatus.overdue
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
            // The one property editable in place. It is the field that moves
            // several times a week, while everything else is usually set once
            // and left alone - so it is worth saving the trip to the form.
            child: _StatusPicker(
              value: task.status,
              onChanged: _changeStatus,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Divider(color: c.border),
          const SizedBox(height: AppSpacing.xl),

          SectionHeader(title: 'SLA status'),
          _SlaCard(evaluation: sla),
          const SizedBox(height: AppSpacing.xl),

          SectionHeader(
            title: 'Notes',
            // The Save action only appears once there is something to save.
            action: _notesDirty
                ? SectionAction(
                    label: _isSavingNotes ? 'Saving' : 'Save',
                    onPressed: () => _saveNotes(task),
                  )
                : null,
          ),
          TextField(
            controller: _notesController,
            minLines: 3,
            maxLines: 6,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
              hintText: 'Add context, a blocker, or a handover note',
            ),
            onChanged: (value) {
              // Only rebuild when the dirty flag actually flips, rather than
              // on every keystroke.
              final dirty = value.trim() != task.notes.trim();
              if (dirty != _notesDirty) setState(() => _notesDirty = dirty);
            },
          ),
        ],
      ),
    );
  }
}

/// The SLA verdict, and the reason for it.
///
/// The explanation is not written here. It comes from SlaService.evaluate,
/// the same call that decided the status, so the words on screen and the rule
/// that produced them cannot drift apart as the thresholds change.
class _SlaCard extends StatelessWidget {
  const _SlaCard({required this.evaluation});

  final SlaEvaluation evaluation;

  @override
  Widget build(BuildContext context) {
    final pair = StatusColors.forSla(context, evaluation.status);

    return AppCard(
      // Tinted fill with a matching border rather than the usual white card.
      // This is the one block on the page that should carry colour.
      background: pair.background,
      borderColor: pair.background,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            StatusColors.iconForSla(evaluation.status),
            size: 18,
            color: pair.foreground,
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  evaluation.status.label,
                  style: AppTypography.bodyStrong.copyWith(
                    color: pair.foreground,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  evaluation.explanation,
                  style: AppTypography.caption.copyWith(
                    color: pair.foreground,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Inline status picker: the status badge itself, with a chevron.
///
/// It looks like the value it edits rather than like a form control, so the
/// property block stays a record you can change rather than becoming a form
/// you have to fill in.
class _StatusPicker extends StatelessWidget {
  const _StatusPicker({required this.value, required this.onChanged});

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
