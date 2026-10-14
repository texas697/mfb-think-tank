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

class SignInScreen extends ConsumerStatefulWidget {
  const SignInScreen({super.key});

  @override
  ConsumerState<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends ConsumerState<SignInScreen>
    with AuthActionMixin {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  // On success the router redirects away from this screen automatically.
  Future<void> _signInWithEmail() async {
    if (!_formKey.currentState!.validate()) return;
    TextInput.finishAutofillContext();
    await runAuthAction(
      () => ref
          .read(authRepositoryProvider)
          .signInWithEmail(email: _email.text, password: _password.text),
    );
  }

  Future<void> _signInWithGoogle() =>
      runAuthAction(() => ref.read(authRepositoryProvider).signInWithGoogle());

  Future<void> _signInWithApple() =>
      runAuthAction(() => ref.read(authRepositoryProvider).signInWithApple());

  @override
  Widget build(BuildContext context) {
    // Preserve a pending deep link across sign-in <-> sign-up.
    final query = GoRouterState.of(context).uri.query;
    String withQuery(String path) => query.isEmpty ? path : '$path?$query';

    return AuthScaffold(
      showLogo: true,
      subtitle: 'Sign in to continue',
      children: [
        Form(
          key: _formKey,
          child: AutofillGroup(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  key: const Key('sign-in-email'),
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
                  key: const Key('sign-in-password'),
                  controller: _password,
                  enabled: !busy,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    suffixIcon: IconButton(
                      tooltip: _obscurePassword
                          ? 'Show password'
                          : 'Hide password',
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                      ),
                      onPressed: () =>
                          setState(() => _obscurePassword = !_obscurePassword),
                    ),
                  ),
                  textInputAction: TextInputAction.done,
                  autofillHints: const [AutofillHints.password],
                  validator: Validators.requiredPassword,
                  onFieldSubmitted: (_) => _signInWithEmail(),
                ),
              ],
            ),
          ),
        ),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: busy
                ? null
                : () => context.push(
                    Uri(
                      path: AppRoutes.forgotPassword,
                      queryParameters: _email.text.trim().isEmpty
                          ? null
                          : {'email': _email.text.trim()},
                    ).toString(),
                  ),
            child: const Text('Forgot password?'),
          ),
        ),
        const SizedBox(height: 8),
        FilledButton(
          key: const Key('sign-in-submit'),
          onPressed: busy ? null : _signInWithEmail,
          child: busy
              ? const SizedBox.square(
                  dimension: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Sign in'),
        ),
        SocialSignInButtons(
          enabled: !busy,
          onGoogle: _signInWithGoogle,
          onApple: _signInWithApple,
        ),
        const SizedBox(height: 24),
        // Wrap (not Row) so large text scales do not overflow.
        Wrap(
          alignment: WrapAlignment.center,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            const Text("Don't have an account?"),
            TextButton(
              onPressed: busy
                  ? null
                  : () => context.go(withQuery(AppRoutes.signUp)),
              child: const Text('Create one'),
            ),
          ],
        ),
      ],
    );
  }
}
