import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mfb_think_tank/app/router.dart';
import 'package:mfb_think_tank/features/auth/application/auth_providers.dart';
import 'package:mfb_think_tank/features/auth/presentation/auth_action.dart';
import 'package:mfb_think_tank/features/auth/presentation/validators.dart';
import 'package:mfb_think_tank/features/auth/presentation/widgets/auth_scaffold.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({this.initialEmail, super.key});

  /// Pre-fills the email field (passed from the sign-in screen).
  final String? initialEmail;

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen>
    with AuthActionMixin {
  final _formKey = GlobalKey<FormState>();
  late final _email = TextEditingController(text: widget.initialEmail);
  bool _sent = false;

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  Future<void> _sendResetEmail() async {
    if (!_formKey.currentState!.validate()) return;
    final ok = await runAuthAction(
      () =>
          ref.read(authRepositoryProvider).sendPasswordResetEmail(_email.text),
    );
    if (ok && mounted) setState(() => _sent = true);
  }

  @override
  Widget build(BuildContext context) {
    if (_sent) {
      return AuthScaffold(
        title: 'Check your email',
        // Email enumeration protection means we cannot tell whether
        // the account exists, so word this neutrally.
        subtitle:
            'If an account exists for ${_email.text.trim()}, you will '
            'receive a link to reset your password.',
        showAppBar: true,
        children: [
          FilledButton(
            onPressed: () =>
                context.canPop() ? context.pop() : context.go(AppRoutes.signIn),
            child: const Text('Back to sign in'),
          ),
        ],
      );
    }

    return AuthScaffold(
      title: 'Reset password',
      subtitle: "Enter your email and we'll send you a reset link.",
      showAppBar: true,
      children: [
        Form(
          key: _formKey,
          child: TextFormField(
            key: const Key('forgot-password-email'),
            controller: _email,
            enabled: !busy,
            decoration: const InputDecoration(labelText: 'Email'),
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.done,
            autocorrect: false,
            autofillHints: const [AutofillHints.email],
            validator: Validators.email,
            onFieldSubmitted: (_) => _sendResetEmail(),
          ),
        ),
        const SizedBox(height: 24),
        FilledButton(
          onPressed: busy ? null : _sendResetEmail,
          child: const Text('Send reset link'),
        ),
      ],
    );
  }
}
