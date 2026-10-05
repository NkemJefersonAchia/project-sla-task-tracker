import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/date_formatting.dart';
import '../../core/utils/validators.dart';
import '../../models/task.dart';
import '../../repositories/member_repository.dart';
import '../../repositories/session_repository.dart';
import '../../repositories/task_repository.dart';
import '../../widgets/common/app_buttons.dart';
import '../../widgets/common/member_avatar.dart';

/// Create or edit a task.
///
/// One screen does both jobs. A null [taskId] means create and the form opens
/// with defaults; a real one means edit and every field is pre-filled. Keeping
/// it as a single widget means the validation rules can only ever be written
/// once - two screens would drift apart the first time a rule changed.
///
/// Pops `true` when something was saved, so the caller knows whether it needs
/// to re-read.
class TaskFormScreen extends StatefulWidget {
  const TaskFormScreen({super.key, this.taskId});

  final String? taskId;

  @override
  State<TaskFormScreen> createState() => _TaskFormScreenState();
}

class _TaskFormScreenState extends State<TaskFormScreen> {
  /// Holds the validation state of every field. Calling validate() on it runs
  /// each field's validator at once and paints all the errors together,
  /// rather than making the user fix one problem per attempt.
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;

  String? _category;
  String? _assigneeId;
  DateTime? _dueDate;

  /// The date picker is not a TextFormField, so the Form cannot validate it.
  /// Its error message is rendered by hand to match the others.
  String? _dueDateError;

  bool get _isEditing => widget.taskId != null;

  Task? get _existingTask => widget.taskId == null
      ? null
      : TaskRepository.instance.byId(widget.taskId!);

  /// The categories this team works in.
  ///
  /// A fixed list rather than free text: it removes a validation path, it
  /// stops 'QA' and 'Quality Assurance' both existing, and on a phone picking
  /// from six options beats typing.
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

    // An unrecognised stored category resolves to null so the field shows its
    // hint rather than a value that is not in the list.
    _category = _categories.contains(task?.category) ? task!.category : null;

    // A new task defaults to whoever is signed in. Most tasks are created by
    // the person who is about to do them, and a default that is right most of
    // the time is worth more than an empty field that is never wrong.
    _assigneeId = task?.assigneeId ?? SessionRepository.instance.currentUser?.id;

    // A week out: long enough to be plausible, short enough that leaving it
    // unchanged is not an obviously fake deadline.
    _dueDate = task?.dueDate ??
        Task.dateOnly(DateTime.now().add(const Duration(days: 7)));
  }

  Future<void> _pickDueDate() async {
    final today = Task.dateOnly(DateTime.now());

    final picked = await showDatePicker(
      context: context,
      initialDate: _dueDate ?? today.add(const Duration(days: 7)),
      // The picker enforces the same window the validator checks, so an
      // invalid date is hard to produce in the first place. The validator is
      // the safety net, not the only line of defence.
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
    });
  }

  @override
  void dispose() {
    // Controllers hold native resources; not disposing them leaks.
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);

    return Scaffold(
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
        // Validate once a field has been touched, so feedback arrives while
        // the user is still in the field rather than after they press save.
        autovalidateMode: AutovalidateMode.onUserInteraction,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.screenPadding,
            AppSpacing.md,
            AppSpacing.screenPadding,
            AppSpacing.xxl,
          ),
          children: [
            const _FieldLabel(label: 'Title', isRequired: true),
            TextFormField(
              controller: _titleController,
              textCapitalization: TextCapitalization.sentences,
              textInputAction: TextInputAction.next,
              maxLength: Validators.titleMaxLength,
              // The character counter is noise until you are near the limit,
              // and the validator already explains the rule when you hit it.
              buildCounter: (_, {required currentLength, required isFocused,
                      maxLength}) =>
                  null,
              decoration: const InputDecoration(
                hintText: 'What needs to be done?',
              ),
              validator: Validators.taskTitle,
            ),
            const SizedBox(height: AppSpacing.lg),

            const _FieldLabel(label: 'Description'),
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
            const _FieldLabel(label: 'Category', isRequired: true),
            DropdownButtonFormField<String>(
              initialValue: _category,
              isExpanded: true,
              decoration: const InputDecoration(hintText: 'Pick a category'),
              items: [
                for (final category in _categories)
                  DropdownMenuItem(
                    value: category,
                    child: Text(category, style: AppTypography.caption),
                  ),
              ],
              onChanged: (value) => setState(() => _category = value),
              validator: Validators.category,
            ),
            const _FieldLabel(label: 'Assign to', isRequired: true),
            DropdownButtonFormField<String>(
              initialValue: _assigneeId,
              isExpanded: true,
              decoration: const InputDecoration(
                hintText: 'Select a team member',
              ),
              items: [
                for (final member in MemberRepository.instance.all)
                  DropdownMenuItem(
                    value: member.id,
                    child: Row(
                      children: [
                        MemberAvatar(member: member, size: 22),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Text(
                            '${member.name} - ${member.role}',
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.caption,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
              onChanged: (value) => setState(() => _assigneeId = value),
              validator: Validators.assignee,
            ),
            const _FieldLabel(label: 'Due date', isRequired: true),
            _DueDateField(
              value: _dueDate,
              errorText: _dueDateError,
              onTap: _pickDueDate,
            ),
            const SizedBox(height: AppSpacing.xxl),

            PrimaryButton(
              label: _isEditing ? 'Save changes' : 'Create task',
              onPressed: () {},
            ),
          ],
        ),
      ),
    );
  }
}

/// A tappable field that looks like the other inputs but opens a date picker.
///
/// Built by hand rather than with a TextFormField, because the value is a
/// DateTime rather than text - which also means it has to render its own
/// error message to match what the real form fields do.
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
                    // Confirms what the chosen date actually means, so an
                    // off-by-a-month slip is visible before saving.
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

/// A small grey label above a field, with a red asterisk when the field is
/// required.
///
/// Flutter's floating label animates into the field's border, which looks
/// busy in a long form and leaves the field ambiguous while it is empty. A
/// static label above the input stays readable in both states.
class _FieldLabel extends StatelessWidget {
  const _FieldLabel({required this.label, this.isRequired = false});

  final String label;
  final bool isRequired;

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
          if (isRequired)
            Text(' *', style: AppTypography.caption.copyWith(color: c.red)),
        ],
      ),
    );
  }
}
