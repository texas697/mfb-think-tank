import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mfb_think_tank/features/auth/application/auth_providers.dart';
import 'package:mfb_think_tank/features/auth/data/auth_failure.dart';
import 'package:mfb_think_tank/features/auth/data/auth_repository.dart';
import 'package:mfb_think_tank/features/auth/presentation/auth_action.dart';
import 'package:mfb_think_tank/features/auth/presentation/widgets/verify_email_banner.dart';
import 'package:mfb_think_tank/features/feedback/presentation/feedback_sheet.dart';

/// Account details, sign out and account deletion.
class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen>
    with AuthActionMixin {
  Future<void> _signOut() =>
      runAuthAction(() => ref.read(authRepositoryProvider).signOut());

  Future<void> _deleteAccount(User user) async {
    final usesPassword = user.providerData.any(
      (p) => p.providerId == AuthProviderIds.password,
    );
    final confirmation = await showDialog<_DeleteConfirmation>(
      context: context,
      builder: (_) => _DeleteAccountDialog(askForPassword: usesPassword),
    );
    if (confirmation == null || !mounted) return;

    // On success the router redirects to sign-in.
    await runAuthAction(() async {
      try {
        await ref
            .read(authRepositoryProvider)
            .deleteAccount(password: confirmation.password);
      } on AuthFailure catch (e) {
        if (!e.requiresRecentLogin) rethrow;
        throw const AuthFailure(
          'requires-recent-login',
          'For your security, sign out and sign back in, then try again.',
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider).value;
    final theme = Theme.of(context);

    if (user == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final name = user.displayName;
    final providers = user.providerData.map((p) => p.providerId).toSet();

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const VerifyEmailBanner(),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: CircleAvatar(
                child: Text(_initial(name ?? user.email ?? '?')),
              ),
              title: Text(name == null || name.isEmpty ? 'No name' : name),
              subtitle: Text(user.email ?? 'No email'),
            ),
            if (providers.isNotEmpty)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.key_outlined),
                title: const Text('Sign-in methods'),
                subtitle: Text(providers.map(_providerLabel).join(', ')),
              ),
            const Divider(height: 32),
            OutlinedButton.icon(
              onPressed: busy ? null : _signOut,
              icon: const Icon(Icons.logout),
              label: const Text('Sign out'),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              key: const Key('send-feedback'),
              onPressed: busy ? null : () => showFeedbackSheet(context),
              icon: const Icon(Icons.feedback_outlined),
              label: const Text('Send feedback'),
            ),
            const SizedBox(height: 32),
            Text(
              'Danger zone',
              style: theme.textTheme.titleSmall?.copyWith(
                color: theme.colorScheme.error,
              ),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              key: const Key('delete-account'),
              style: OutlinedButton.styleFrom(
                foregroundColor: theme.colorScheme.error,
                side: BorderSide(color: theme.colorScheme.error),
              ),
              onPressed: busy ? null : () => _deleteAccount(user),
              icon: const Icon(Icons.delete_forever_outlined),
              label: const Text('Delete account'),
            ),
          ],
        ),
      ),
    );
  }

  static String _initial(String text) =>
      text.isEmpty ? '?' : text.characters.first.toUpperCase();

  static String _providerLabel(String providerId) => switch (providerId) {
    AuthProviderIds.password => 'Email',
    AuthProviderIds.google => 'Google',
    AuthProviderIds.apple => 'Apple',
    _ => providerId,
  };
}

class _DeleteConfirmation {
  const _DeleteConfirmation(this.password);
  final String? password;
}

class _DeleteAccountDialog extends StatefulWidget {
  const _DeleteAccountDialog({required this.askForPassword});

  final bool askForPassword;

  @override
  State<_DeleteAccountDialog> createState() => _DeleteAccountDialogState();
}

class _DeleteAccountDialogState extends State<_DeleteAccountDialog> {
  final _formKey = GlobalKey<FormState>();
  final _password = TextEditingController();

  @override
  void dispose() {
    _password.dispose();
    super.dispose();
  }

  void _confirm() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.of(
      context,
    ).pop(_DeleteConfirmation(widget.askForPassword ? _password.text : null));
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return AlertDialog(
      title: const Text('Delete account?'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'This permanently deletes your account and data. '
              'This cannot be undone.',
            ),
            if (widget.askForPassword) ...[
              const SizedBox(height: 16),
              TextFormField(
                key: const Key('delete-account-password'),
                controller: _password,
                obscureText: true,
                autofocus: true,
                decoration: const InputDecoration(
                  labelText: 'Confirm your password',
                ),
                validator: (v) =>
                    (v == null || v.isEmpty) ? 'Enter your password' : null,
                onFieldSubmitted: (_) => _confirm(),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        TextButton(
          key: const Key('delete-account-confirm'),
          style: TextButton.styleFrom(foregroundColor: colors.error),
          onPressed: _confirm,
          child: const Text('Delete'),
        ),
      ],
    );
  }
}
