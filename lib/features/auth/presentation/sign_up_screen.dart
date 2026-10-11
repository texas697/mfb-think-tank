import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mfb_think_tank/app/router.dart';
import 'package:mfb_think_tank/features/auth/application/auth_providers.dart';
import 'package:mfb_think_tank/features/auth/presentation/auth_action.dart';
import 'package:mfb_think_tank/features/auth/presentation/validators.dart';
import 'package:mfb_think_tank/features/auth/presentation/widgets/auth_scaffold.dart';
import 'package:mfb_think_tank/features/auth/presentation/widgets/social_sign_in_buttons.dart';

class SignUpScreen extends ConsumerStatefulWidget {
  const SignUpScreen({super.key});

  @override
  ConsumerState<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends ConsumerState<SignUpScreen>
    with AuthActionMixin {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirmPassword = TextEditingController();

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    _confirmPassword.dispose();
    super.dispose();
  }

  Future<void> _signUp() async {
    if (!_formKey.currentState!.validate()) return;
    TextInput.finishAutofillContext();
    await runAuthAction(
      () => ref
          .read(authRepositoryProvider)
          .signUpWithEmail(
            email: _email.text,
            password: _password.text,
            displayName: _name.text,
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final query = GoRouterState.of(context).uri.query;
    final repo = ref.read(authRepositoryProvider);

    return AuthScaffold(
      title: 'Create account',
      subtitle: "We'll send you an email to verify your address.",
      children: [
        Form(
          key: _formKey,
          child: AutofillGroup(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  key: const Key('sign-up-name'),
                  controller: _name,
                  enabled: !busy,
                  decoration: const InputDecoration(
                    labelText: 'Name (optional)',
                  ),
                  textCapitalization: TextCapitalization.words,
                  textInputAction: TextInputAction.next,
                  autofillHints: const [AutofillHints.name],
                ),
                const SizedBox(height: 16),
                TextFormField(
                  key: const Key('sign-up-email'),
                  controller: _email,
                  enabled: !busy,
                  decoration: const InputDecoration(labelText: 'Email'),
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  autocorrect: false,
                  autofillHints: const [AutofillHints.email],
                  validator: Validators.email,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  key: const Key('sign-up-password'),
                  controller: _password,
                  enabled: !busy,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Password',
                    helperText:
                        'At least ${Validators.minPasswordLength} characters, '
                        'with letters and numbers',
                  ),
                  textInputAction: TextInputAction.next,
                  autofillHints: const [AutofillHints.newPassword],
                  validator: Validators.newPassword,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  key: const Key('sign-up-confirm-password'),
                  controller: _confirmPassword,
                  enabled: !busy,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Confirm password',
                  ),
                  textInputAction: TextInputAction.done,
                  autofillHints: const [AutofillHints.newPassword],
                  validator: Validators.confirmPassword(() => _password.text),
                  onFieldSubmitted: (_) => _signUp(),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        FilledButton(
          key: const Key('sign-up-submit'),
          onPressed: busy ? null : _signUp,
          child: busy
              ? const SizedBox.square(
                  dimension: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Create account'),
        ),
        SocialSignInButtons(
          enabled: !busy,
          onGoogle: () => runAuthAction(repo.signInWithGoogle),
          onApple: () => runAuthAction(repo.signInWithApple),
        ),
        const SizedBox(height: 24),
        // Wrap (not Row) so large text scales do not overflow.
        Wrap(
          alignment: WrapAlignment.center,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            const Text('Already have an account?'),
            TextButton(
              onPressed: busy
                  ? null
                  : () => context.go(
                      query.isEmpty
                          ? AppRoutes.signIn
                          : '${AppRoutes.signIn}?$query',
                    ),
              child: const Text('Sign in'),
            ),
          ],
        ),
      ],
    );
  }
}
