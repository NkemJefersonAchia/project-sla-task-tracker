import 'package:flutter/material.dart';

import '../../core/constants/app_routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/validators.dart';
import '../../models/team_member.dart';
import '../../repositories/member_repository.dart';
import '../../repositories/session_repository.dart';
import '../../widgets/common/app_buttons.dart';
import '../../widgets/common/app_feedback.dart';
import '../../widgets/common/section_header.dart';
import 'widgets/member_picker_tile.dart';

/// Sign in / user selection.
///
/// There is no auth backend - the assignment asks for the interface and the
/// flow. "Signing in" means choosing which member of the team you are, which
/// the rest of the app then uses to greet you and to pre-fill the assignee on
/// new tasks.
///
/// Two ways in are offered on purpose:
///  * the email + password form, which is where the validation lives, and
///  * a direct roster picker, which is the fast path during a demo.
class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  /// Holds the validation state of the two fields. Calling
  /// `_formKey.currentState!.validate()` runs every field's validator at once
  /// and paints the error messages.
  final _formKey = GlobalKey<FormState>();

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  /// Lets the user reveal what they typed - a password field with no way to
  /// check it is a common source of failed sign-ins.
  bool _obscurePassword = true;

  bool _isSubmitting = false;

  /// Error that belongs to the form as a whole (rather than to one field),
  /// such as "that email is not on this team".
  String? _formError;

  @override
  void dispose() {
    // Controllers hold native resources; not disposing them leaks.
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    // Dismiss the keyboard so the user can see the result of their action.
    FocusScope.of(context).unfocus();

    setState(() => _formError = null);

    if (!_formKey.currentState!.validate()) return;

    final email = _emailController.text.trim().toLowerCase();
    final match = MemberRepository.instance.all.where(
      (member) => member.email.toLowerCase() == email,
    );

    if (match.isEmpty) {
      // Field-level validation passed (it *is* a valid email), so this is a
      // form-level error: the address is well formed but not on the roster.
      setState(() {
        _formError = 'No team member uses $email. Pick your name below, or '
            'ask your project manager to add you.';
      });
      return;
    }

    await _signIn(match.first);
  }

  Future<void> _signIn(TeamMember member) async {
    setState(() => _isSubmitting = true);

    try {
      await SessionRepository.instance.signIn(member);
      if (!mounted) return;

      // Replace rather than push: signing in should not leave a back arrow
      // that returns to the sign-in screen from the dashboard.
      Navigator.of(context).pushReplacementNamed(AppRoutes.home);
    } catch (error) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      AppFeedback.showError(context, 'Could not sign in. $error');
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final members = MemberRepository.instance.all;

    return Scaffold(
      body: SafeArea(
        // SingleChildScrollView keeps the whole form reachable when the
        // keyboard covers the lower half of a small screen.
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.screenPadding,
            vertical: AppSpacing.xl,
          ),
          child: Center(
            child: ConstrainedBox(
              // On a tablet or in a desktop window the form stops growing and
              // stays a comfortable reading width instead of stretching edge
              // to edge.
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: AppSpacing.xl),
                  const _Wordmark(),
                  const SizedBox(height: AppSpacing.xl),
                  Text('Sign in', style: AppTypography.pageTitle),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'Track what the team owes, and when it is due.',
                    style: AppTypography.body.copyWith(color: c.textSecondary),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  _buildForm(c),
                  const SizedBox(height: AppSpacing.xxl),
                  _Divider(label: 'or continue as'),
                  const SizedBox(height: AppSpacing.lg),
                  SectionHeader(title: 'Team roster (${members.length})'),
                  for (final member in members)
                    Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                      child: MemberPickerTile(
                        member: member,
                        enabled: !_isSubmitting,
                        onTap: () => _signIn(member),
                      ),
                    ),
                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    'Demo build. Any password of '
                    '${Validators.passwordMinLength} characters or more is '
                    'accepted - no account is created.',
                    textAlign: TextAlign.center,
                    style: AppTypography.caption.copyWith(
                      color: c.textTertiary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildForm(AppColors c) {
    return Form(
      key: _formKey,
      // Validate as soon as a field has been touched once, so the user gets
      // feedback while typing instead of only after pressing the button.
      autovalidateMode: AutovalidateMode.onUserInteraction,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            autocorrect: false,
            decoration: const InputDecoration(
              hintText: 'name@teamsla.dev',
              prefixIcon: Icon(Icons.alternate_email_rounded, size: 18),
            ),
            validator: Validators.email,
          ),
          const SizedBox(height: AppSpacing.md),
          TextFormField(
            controller: _passwordController,
            obscureText: _obscurePassword,
            textInputAction: TextInputAction.done,
            // Submitting from the keyboard is faster than reaching for the
            // button, and it is what people expect on the last field.
            onFieldSubmitted: (_) => _submit(),
            decoration: InputDecoration(
              hintText: 'Password',
              prefixIcon: const Icon(Icons.lock_outline_rounded, size: 18),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePassword
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  size: 18,
                ),
                tooltip: _obscurePassword ? 'Show password' : 'Hide password',
                onPressed: () =>
                    setState(() => _obscurePassword = !_obscurePassword),
              ),
            ),
            validator: Validators.password,
          ),
          if (_formError != null) ...[
            const SizedBox(height: AppSpacing.md),
            _FormError(message: _formError!),
          ],
          const SizedBox(height: AppSpacing.lg),
          PrimaryButton(
            label: 'Continue',
            isLoading: _isSubmitting,
            onPressed: _submit,
          ),
        ],
      ),
    );
  }
}

/// The small product mark at the top of the screen.
class _Wordmark extends StatelessWidget {
  const _Wordmark();

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);

    return Row(
      children: [
        Container(
          height: 34,
          width: 34,
          decoration: BoxDecoration(
            color: c.textPrimary,
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          child: Icon(Icons.bolt_rounded, size: 19, color: c.canvas),
        ),
        const SizedBox(width: AppSpacing.md),
        Text(
          'SLA Tracker',
          style: AppTypography.bodyStrong.copyWith(color: c.textPrimary),
        ),
      ],
    );
  }
}

/// A form-wide error block, visually distinct from the per-field messages.
class _FormError extends StatelessWidget {
  const _FormError({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: c.redBg,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.error_outline_rounded, size: 16, color: c.red),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              message,
              style: AppTypography.caption.copyWith(color: c.red),
            ),
          ),
        ],
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);

    return Row(
      children: [
        Expanded(child: Divider(color: c.border)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: Text(
            label,
            style: AppTypography.caption.copyWith(color: c.textTertiary),
          ),
        ),
        Expanded(child: Divider(color: c.border)),
      ],
    );
  }
}
