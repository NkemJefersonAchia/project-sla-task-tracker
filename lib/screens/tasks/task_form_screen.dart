import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
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

  bool get _isEditing => widget.taskId != null;

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
