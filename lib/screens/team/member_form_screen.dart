import 'package:flutter/material.dart';
import 'package:project_sla_task_tracker/core/theme/app_colors.dart';
import 'package:project_sla_task_tracker/core/theme/app_spacing.dart';
import 'package:project_sla_task_tracker/core/theme/status_colors.dart'; // ASSUMPTION: path
import 'package:project_sla_task_tracker/core/utils/validators.dart';
import 'package:project_sla_task_tracker/models/team_member.dart';
import 'package:project_sla_task_tracker/repositories/member_repository.dart';
import 'package:project_sla_task_tracker/services/storage_service.dart';
import 'package:project_sla_task_tracker/widgets/common/app_buttons.dart';
import 'package:project_sla_task_tracker/widgets/common/app_feedback.dart';
import 'package:project_sla_task_tracker/widgets/common/section_header.dart';

/// Add (memberId == null) or edit (memberId != null) a team member.
/// Pops with `true` when something was saved.
class MemberFormScreen extends StatefulWidget {
  final String? memberId;
  const MemberFormScreen({super.key, this.memberId});

  @override
  State<MemberFormScreen> createState() => _MemberFormScreenState();
}

class _MemberFormScreenState extends State<MemberFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _role;
  late final TextEditingController _email;
  late String _colorKey;
  TeamMember? _existing;
  bool _dirty = false;
  bool _saving = false;

  bool get _isEdit => _existing != null;

  void _markDirty() {
    if (!_dirty) setState(() => _dirty = true);
  }

  @override
  void initState() {
    super.initState();
    _existing = widget.memberId == null
        ? null
        : MemberRepository.instance.byId(widget.memberId!);
    _name = TextEditingController(text: _existing?.name ?? '');
    _role = TextEditingController(text: _existing?.role ?? '');
    _email = TextEditingController(text: _existing?.email ?? '');
    _colorKey =
        _existing?.colorKey ??
        StatusColors.memberColorKeys.first; // ASSUMPTION: field colorKey
  }

  @override
  void dispose() {
    _name.dispose();
    _role.dispose();
    _email.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final repo = MemberRepository.instance;
      final member = _isEdit
          ? _existing!.copyWith(
              name: _name.text.trim(),
              role: _role.text.trim(),
              email: _email.text.trim(),
              colorKey: _colorKey,
            )
          : TeamMember(
              id: repo.newId(),
              name: _name.text.trim(),
              role: _role.text.trim(),
              email: _email.text.trim(),
              colorKey: _colorKey,
            );
      await repo.save(member); // await BEFORE confirming
      if (!mounted) return;
      AppFeedback.showSuccess(
        context,
        _isEdit ? 'Member updated' : 'Member added',
      );
      _dirty = false;
      Navigator.pop(context, true);
    } on StorageException {
      if (!mounted) return;
      setState(() => _saving = false);
      AppFeedback.showError(
        context,
        'Could not save the member. Please try again.',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return PopScope(
      canPop: !_dirty,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final discard = await AppFeedback.confirm(
          context,
          title: 'Discard changes?',
          message: 'Your edits have not been saved.',
          confirmLabel: 'Discard',
        );
        if (discard == true && context.mounted) Navigator.pop(context);
      },
      child: Scaffold(
        appBar: AppBar(title: Text(_isEdit ? 'Edit member' : 'Add member')),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Form(
            key: _formKey,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SectionHeader(
                  title: 'DETAILS',
                ), // ASSUMPTION: param `title`
                TextFormField(
                  controller: _name,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(labelText: 'Full name'),
                  validator: Validators.personName,
                  onChanged: (_) => _markDirty(),
                ),
                const SizedBox(height: AppSpacing.md),
                TextFormField(
                  controller: _role,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    labelText: 'Role',
                    hintText: 'e.g. Mobile Developer',
                  ),
                  validator: (v) => Validators.required(v, field: 'Role'),
                  onChanged: (_) => _markDirty(),
                ),
                const SizedBox(height: AppSpacing.md),
                TextFormField(
                  controller: _email,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(labelText: 'Email'),
                  validator: Validators.email,
                  onChanged: (_) => _markDirty(),
                ),
                const SizedBox(height: AppSpacing.xl),
                const SectionHeader(title: 'ACCENT COLOUR'),
                Wrap(
                  spacing: AppSpacing.md,
                  runSpacing: AppSpacing.md,
                  children: [
                    for (final key in StatusColors.memberColorKeys)
                      _Swatch(
                        label: '$key accent colour',
                        color: StatusColors.forMemberColor(
                          context,
                          key,
                        ).foreground,
                        selected: key == _colorKey,
                        borderColor: c.textPrimary,
                        onTap: () => setState(() {
                          _colorKey = key;
                          _dirty = true;
                        }),
                      ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xxl),
                SizedBox(
                  width: double.infinity,
                  child: PrimaryButton(
                    label: _isEdit
                        ? 'Save changes'
                        : 'Add member', // ASSUMPTION: params
                    isLoading: _saving,
                    onPressed: _saving ? null : _save,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Swatch extends StatelessWidget {
  final String label;
  final Color color;
  final Color borderColor;
  final bool selected;
  final VoidCallback onTap;
  const _Swatch({
    required this.label,
    required this.color,
    required this.borderColor,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      selected: selected,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: selected ? Border.all(color: borderColor, width: 2) : null,
          ),
          child: selected
              ? const Icon(Icons.check, size: 18, color: Colors.white)
              : null,
        ),
      ),
    );
  }
}
