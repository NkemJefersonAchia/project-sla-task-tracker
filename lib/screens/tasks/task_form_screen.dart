import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/theme/status_colors.dart';
import '../../core/utils/date_formatting.dart';
import '../../core/utils/validators.dart';
import '../../models/task.dart';
import '../../models/task_priority.dart';
import '../../models/task_status.dart';
import '../../repositories/member_repository.dart';
import '../../repositories/session_repository.dart';
import '../../repositories/task_repository.dart';
import '../../services/storage_service.dart';
import '../../widgets/common/app_buttons.dart';
import '../../widgets/common/app_feedback.dart';
import '../../widgets/common/member_avatar.dart';
import '../../widgets/common/section_header.dart';

/// Create or edit a task.
///
/// One screen serves both jobs. A null [taskId] means "create" and the form
/// opens with sensible defaults; a non-null id loads that task and pre-fills
/// every field. Keeping it as one widget means the validation rules can only
/// ever be written once.
///
/// The screen pops with `true` when something was saved, so the caller knows
/// whether it needs to refresh.
class TaskFormScreen extends StatefulWidget {
  const TaskFormScreen({super.key, this.taskId});

  final String? taskId;

  @override
  State<TaskFormScreen> createState() => _TaskFormScreenState();
}

class _TaskFormScreenState extends State<TaskFormScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;

  String? _category;
  String? _assigneeId;
  DateTime? _dueDate;
  TaskPriority _priority = TaskPriority.medium;
  TaskStatus _status = TaskStatus.todo;

  bool _isSaving = false;

  /// Tracked separately from the form fields so we can warn before discarding
  /// work on a back gesture.
  bool _isDirty = false;

  /// Errors that no single field owns. The date picker is not a
  /// [TextFormField], so its validation message has to be rendered by hand.
  String? _dueDateError;

  Task? get _existingTask =>
      widget.taskId == null ? null : TaskRepository.instance.byId(widget.taskId!);

  bool get _isEditing => widget.taskId != null;

  /// The categories this team works in. A fixed list rather than free text:
  /// it removes a whole validation path, it keeps the search results tidy,
  /// and picking from six options is faster than typing on a phone.
  static const List<String> _categories = [
    'UI/UX Design',
    'Mobile Development',
    'Backend Logic',
    'Quality Assurance',
    'Documentation',
    'Project Setup',
  ];

  @override
  void initState() {
    super.initState();

    final task = _existingTask;

    _titleController = TextEditingController(text: task?.title ?? '');
    _descriptionController =
        TextEditingController(text: task?.description ?? '');

    // An unrecognised stored category (e.g. one typed by an older build)
    // resolves to null so the field shows its hint instead of a stale value.
    _category = _categories.contains(task?.category) ? task!.category : null;

    if (task != null) {
      _assigneeId = task.assigneeId;
      _dueDate = task.dueDate;
      _priority = task.priority;
      _status = task.status;
    } else {
      // Defaults for a new task: assigned to whoever is signed in, due in a
      // week. Good defaults mean most tasks can be created by typing a title
      // and pressing save.
      _assigneeId = SessionRepository.instance.currentUser?.id;
      _dueDate = Task.dateOnly(DateTime.now().add(const Duration(days: 7)));
    }

    // Any keystroke in either text field marks the form dirty.
    for (final controller in [_titleController, _descriptionController]) {
      controller.addListener(_markDirty);
    }
  }

  @override
  void dispose() {
    for (final controller in [_titleController, _descriptionController]) {
      controller
        ..removeListener(_markDirty)
        ..dispose();
    }
    super.dispose();
  }

  void _markDirty() {
    if (!_isDirty) setState(() => _isDirty = true);
  }

  Future<void> _pickDueDate() async {
    final today = Task.dateOnly(DateTime.now());

    final picked = await showDatePicker(
      context: context,
      initialDate: _dueDate ?? today.add(const Duration(days: 7)),
      // The picker itself enforces the same window the validator checks, so
      // an invalid date is hard to produce in the first place - the validator
      // is the safety net, not the only line of defence.
      firstDate: today,
      lastDate: DateTime(
        today.year + Validators.maxDueDateYearsAhead,
        today.month,
        today.day,
      ),
      helpText: 'Select the deadline',
    );

    if (picked == null) return;
    setState(() {
      _dueDate = Task.dateOnly(picked);
      _dueDateError = null;
      _isDirty = true;
    });
  }

  Future<void> _save() async {
    FocusScope.of(context).unfocus();

    // Run both halves of the validation before deciding, so the user sees
    // every problem at once instead of fixing them one round-trip at a time.
    final fieldsValid = _formKey.currentState!.validate();
    final dateError = Validators.dueDate(_dueDate);

    setState(() => _dueDateError = dateError);

    if (!fieldsValid || dateError != null) {
      AppFeedback.showError(context, 'Fix the highlighted fields to continue.');
      return;
    }

    setState(() => _isSaving = true);

    final now = DateTime.now();
    final existing = _existingTask;

    final task = existing == null
        ? Task(
            id: TaskRepository.instance.newId(),
            title: _titleController.text.trim(),
            description: _descriptionController.text.trim(),
            category: _category ?? '',
            assigneeId: _assigneeId ?? '',
            dueDate: _dueDate!,
            priority: _priority,
            status: _status,
            createdAt: now,
            updatedAt: now,
            completedAt: _status.isComplete ? now : null,
          )
        : existing.copyWith(
            title: _titleController.text.trim(),
            description: _descriptionController.text.trim(),
            category: _category ?? '',
            assigneeId: _assigneeId ?? '',
            dueDate: _dueDate!,
            priority: _priority,
            status: _status,
            updatedAt: now,
            // Reopening a completed task has to clear the completion stamp,
            // otherwise the statistics would keep counting it as delivered.
            completedAt: _status.isComplete
                ? (existing.completedAt ?? now)
                : null,
            clearCompletedAt: !_status.isComplete,
          );

    try {
      await TaskRepository.instance.save(task);
      if (!mounted) return;
      Navigator.of(context).pop(true);
      AppFeedback.showSuccess(
        context,
        _isEditing ? 'Task updated.' : 'Task created.',
      );
    } on StorageException catch (error) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      AppFeedback.showError(context, error.message);
    }
  }

  /// Guards the back gesture: leaving with unsaved edits asks first.
  Future<void> _handlePop(bool didPop, Object? result) async {
    if (didPop || !_isDirty) return;

    final discard = await AppFeedback.confirm(
      context,
      title: 'Discard changes?',
      message: 'This task has edits that have not been saved yet.',
      confirmLabel: 'Discard',
    );

    if (discard && mounted) Navigator.of(context).pop(false);
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final members = MemberRepository.instance.all;

    return PopScope(
      // Blocking the pop only while the form is dirty keeps the normal case -
      // opening the form and closing it again - completely friction free.
      canPop: !_isDirty,
      onPopInvokedWithResult: _handlePop,
      child: Scaffold(
        backgroundColor: c.canvas,
        appBar: AppBar(
          title: Text(_isEditing ? 'Edit task' : 'New task'),
          leading: IconButton(
            icon: const Icon(Icons.close_rounded),
            tooltip: 'Cancel',
            onPressed: () => Navigator.of(context).maybePop(),
          ),
        ),
        body: Form(
          key: _formKey,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.screenPadding,
              AppSpacing.md,
              AppSpacing.screenPadding,
              AppSpacing.xxl,
            ),
            children: [
              _FieldLabel(label: 'Title', required: true),
              TextFormField(
                controller: _titleController,
                textCapitalization: TextCapitalization.sentences,
                textInputAction: TextInputAction.next,
                maxLength: Validators.titleMaxLength,
                // The counter is noise until the limit is close, and the
                // validator already explains the rule.
                buildCounter: (_,
                        {required currentLength,
                        required isFocused,
                        maxLength}) =>
                    null,
                decoration: const InputDecoration(
                  hintText: 'What needs to be done?',
                ),
                validator: Validators.taskTitle,
              ),
              const SizedBox(height: AppSpacing.lg),

              _FieldLabel(label: 'Description'),
              TextFormField(
                controller: _descriptionController,
                textCapitalization: TextCapitalization.sentences,
                minLines: 3,
                maxLines: 5,
                decoration: const InputDecoration(
                  hintText: 'Add the detail somebody else would need to pick '
                      'this up.',
                ),
                validator: Validators.taskDescription,
              ),
              const SizedBox(height: AppSpacing.lg),

              _FieldLabel(label: 'Category', required: true),
              DropdownButtonFormField<String>(
                initialValue: _category,
                isExpanded: true,
                decoration: const InputDecoration(
                  hintText: 'Pick a category',
                ),
                items: [
                  for (final category in _categories)
                    DropdownMenuItem(
                      value: category,
                      child: Text(category, style: AppTypography.caption),
                    ),
                ],
                onChanged: (value) => setState(() {
                  _category = value;
                  _isDirty = true;
                }),
                validator: Validators.category,
              ),
              const SizedBox(height: AppSpacing.xl),

              SectionHeader(title: 'Assignment'),
              _FieldLabel(label: 'Assign to', required: true),
              DropdownButtonFormField<String>(
                initialValue: _assigneeId,
                isExpanded: true,
                decoration: const InputDecoration(
                  hintText: 'Select a team member',
                ),
                items: [
                  for (final member in members)
                    DropdownMenuItem(
                      value: member.id,
                      child: Row(
                        children: [
                          MemberAvatar(member: member, size: 22),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: Text(
                              '${member.name} · ${member.role}',
                              overflow: TextOverflow.ellipsis,
                              style: AppTypography.caption,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
                onChanged: (value) => setState(() {
                  _assigneeId = value;
                  _isDirty = true;
                }),
                validator: Validators.assignee,
              ),
              const SizedBox(height: AppSpacing.lg),

              _FieldLabel(label: 'Due date', required: true),
              _DueDateField(
                value: _dueDate,
                errorText: _dueDateError,
                onTap: _pickDueDate,
              ),
              const SizedBox(height: AppSpacing.lg),

              _FieldLabel(label: 'Priority'),
              _PriorityPicker(
                value: _priority,
                onChanged: (value) => setState(() {
                  _priority = value;
                  _isDirty = true;
                }),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Priority also decides how early the SLA flags this task: '
                'urgent work is marked At Risk sooner than low priority work.',
                style: AppTypography.caption.copyWith(color: c.textTertiary),
              ),
              const SizedBox(height: AppSpacing.lg),

              _FieldLabel(label: 'Status'),
              DropdownButtonFormField<TaskStatus>(
                initialValue: _status,
                isExpanded: true,
                items: [
                  for (final status in TaskStatus.values)
                    DropdownMenuItem(
                      value: status,
                      child: Text(status.label, style: AppTypography.caption),
                    ),
                ],
                onChanged: (value) {
                  if (value == null) return;
                  setState(() {
                    _status = value;
                    _isDirty = true;
                  });
                },
              ),
              const SizedBox(height: AppSpacing.xxl),

              PrimaryButton(
                label: _isEditing ? 'Save changes' : 'Create task',
                isLoading: _isSaving,
                onPressed: _save,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Small label above a field, with an optional red asterisk.
class _FieldLabel extends StatelessWidget {
  const _FieldLabel({required this.label, this.required = false});

  final String label;
  final bool required;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        children: [
          Text(
            label,
            style: AppTypography.caption.copyWith(
              color: c.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          if (required)
            Text(' *', style: AppTypography.caption.copyWith(color: c.red)),
        ],
      ),
    );
  }
}

/// A tappable field that looks like the other inputs but opens a date picker.
///
/// It is built by hand rather than with `TextFormField` because the value is
/// a `DateTime`, not text - so it also has to render its own error message to
/// match what the real form fields do.
class _DueDateField extends StatelessWidget {
  const _DueDateField({
    required this.value,
    required this.onTap,
    this.errorText,
  });

  final DateTime? value;
  final VoidCallback onTap;
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final hasError = errorText != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.md),
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.md + 2,
            ),
            decoration: BoxDecoration(
              color: c.surfaceMuted,
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(color: hasError ? c.red : c.border),
            ),
            child: Row(
              children: [
                Icon(Icons.event_outlined, size: 18, color: c.textTertiary),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Text(
                    value == null
                        ? 'Select a date'
                        : DateFormatting.full(value!),
                    style: AppTypography.body.copyWith(
                      color: value == null ? c.textTertiary : c.textPrimary,
                    ),
                  ),
                ),
                if (value != null)
                  Text(
                    DateFormatting.relativeDueDate(value!),
                    style: AppTypography.caption.copyWith(
                      color: c.textTertiary,
                    ),
                  ),
              ],
            ),
          ),
        ),
        if (hasError)
          Padding(
            padding: const EdgeInsets.only(top: 6, left: AppSpacing.md),
            child: Text(
              errorText!,
              style: AppTypography.caption.copyWith(color: c.red),
            ),
          ),
      ],
    );
  }
}

/// Four segmented options - faster than a dropdown for a short, fixed list.
class _PriorityPicker extends StatelessWidget {
  const _PriorityPicker({required this.value, required this.onChanged});

  final TaskPriority value;
  final ValueChanged<TaskPriority> onChanged;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);

    return Row(
      children: [
        for (final priority in TaskPriority.values)
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(
                right: priority == TaskPriority.values.last
                    ? 0
                    : AppSpacing.sm,
              ),
              child: _PriorityOption(
                priority: priority,
                selected: priority == value,
                onTap: () => onChanged(priority),
                neutralBorder: c.border,
              ),
            ),
          ),
      ],
    );
  }
}

class _PriorityOption extends StatelessWidget {
  const _PriorityOption({
    required this.priority,
    required this.selected,
    required this.onTap,
    required this.neutralBorder,
  });

  final TaskPriority priority;
  final bool selected;
  final VoidCallback onTap;
  final Color neutralBorder;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final pair = StatusColors.forPriority(context, priority);

    return Material(
      color: selected ? pair.background : c.surfaceMuted,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.md - 2),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(
              color: selected ? pair.foreground : neutralBorder,
            ),
          ),
          child: Text(
            priority.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.badge.copyWith(
              color: selected ? pair.foreground : c.textSecondary,
              fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
        ),
      ),
    );
  }
}
