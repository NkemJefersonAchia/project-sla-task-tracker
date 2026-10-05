import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/validators.dart';
import '../../models/task.dart';
import '../../repositories/task_repository.dart';
import '../../widgets/common/app_buttons.dart';

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
