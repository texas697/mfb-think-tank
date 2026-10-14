import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mfb_think_tank/features/auth/application/auth_providers.dart';
import 'package:mfb_think_tank/features/auth/data/auth_repository.dart';
import 'package:mfb_think_tank/features/auth/presentation/auth_action.dart';

/// Prompts email/password users to verify their address. Hidden otherwise.
class VerifyEmailBanner extends ConsumerStatefulWidget {
  const VerifyEmailBanner({super.key});

  @override
  ConsumerState<VerifyEmailBanner> createState() => _VerifyEmailBannerState();
}

class _VerifyEmailBannerState extends ConsumerState<VerifyEmailBanner>
    with AuthActionMixin {
  Future<void> _resend() async {
    final ok = await runAuthAction(
      () => ref.read(authRepositoryProvider).sendEmailVerification(),
    );
    if (ok && mounted) {
      showSnackMessage(context, 'Verification email sent.');
    }
  }

  Future<void> _refresh() async {
    final ok = await runAuthAction(
      () => ref.read(authRepositoryProvider).reloadUser(),
    );
    if (!ok || !mounted) return;
    // reload() does not always emit on userChanges(); re-subscribe to pick up
    // the fresh emailVerified flag.
    ref.invalidate(currentUserProvider);
    final verified =
        ref.read(authRepositoryProvider).currentUser?.emailVerified ?? false;
    if (!verified && mounted) {
      showSnackMessage(context, 'Your email is not verified yet.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider).value;
    final needsVerification =
        user != null &&
        !user.emailVerified &&
        user.hasProvider(AuthProviderIds.password);
    if (!needsVerification) return const SizedBox.shrink();

    final colors = Theme.of(context).colorScheme;
    return Card(
      color: colors.tertiaryContainer,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.mark_email_unread_outlined,
                  color: colors.onTertiaryContainer,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Verify your email address. We sent a link to '
                    '${user.email}.',
                    style: TextStyle(color: colors.onTertiaryContainer),
                  ),
                ),
              ],
            ),
            OverflowBar(
              alignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: busy ? null : _resend,
                  child: const Text('Resend'),
                ),
                TextButton(
                  onPressed: busy ? null : _refresh,
                  child: const Text("I've verified"),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
