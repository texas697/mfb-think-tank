import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mfb_think_tank/app/router.dart';
import 'package:mfb_think_tank/features/auth/application/auth_providers.dart';
import 'package:mfb_think_tank/features/digest_settings/application/me_profile_provider.dart';
import 'package:mfb_think_tank/features/digest_settings/data/digest_settings_failure.dart';
import 'package:mfb_think_tank/features/digest_settings/presentation/ai_settings_form.dart';
import 'package:mfb_think_tank/features/feedback/presentation/feedback_sheet.dart';
import 'package:mfb_think_tank/features/readers_digest/presentation/digest_colors.dart';
import 'package:mfb_think_tank/features/readers_digest/presentation/widgets/feed_message.dart';

/// Opens the account and AI key sheet.
Future<void> showAccountSheet(BuildContext context) =>
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => const AccountSheet(),
    );

/// Who is signed in, plus the AI provider/key form.
class AccountSheet extends ConsumerWidget {
  const AccountSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final user = ref.watch(currentUserProvider).value;
    final profile = ref.watch(meProfileProvider);
    final providers = user?.providerData.map((p) => p.providerId).join(', ');
    return Padding(
      padding: EdgeInsets.fromLTRB(
        16,
        16,
        16,
        16 + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Account', style: theme.textTheme.titleLarge),
            const SizedBox(height: 4),
            Text(user?.email ?? user?.displayName ?? ''),
            if (providers != null && providers.isNotEmpty)
              Text(
                'Signed in with $providers',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: DigestColors.of(context).muted,
                ),
              ),
            const SizedBox(height: 16),
            Text('AI write-ups', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            if (profile.value case final value? when value.hasSharedLlm)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  key: const Key('account-shared-llm'),
                  value.hasLlm
                      ? 'Your own key is used for write-ups and deep dives.'
                      : 'Write-ups and deep dives are included. Add your own '
                            'key below only if you want unlimited use.',
                  style: theme.textTheme.bodySmall,
                ),
              ),
            if (profile.value case final value?)
              AiSettingsForm(profile: value)
            else if (profile case AsyncError(:final error))
              FeedMessage(
                key: const Key('account-error'),
                title: 'Could not load settings.',
                body: error is DigestSettingsFailure ? error.message : null,
                actionLabel: 'Retry',
                onAction: () => ref.invalidate(meProfileProvider),
              )
            else
              const Center(child: CircularProgressIndicator()),
            const SizedBox(height: 16),
            OutlinedButton(
              key: const Key('account-profile'),
              onPressed: () {
                Navigator.of(context).pop();
                context.go(AppRoutes.profile);
              },
              child: const Text('Profile and sign out'),
            ),
            OutlinedButton.icon(
              key: const Key('account-feedback'),
              onPressed: () {
                // Open the next sheet from the navigator, not from this
                // sheet's context, which is on its way out.
                final navigator = Navigator.of(context)..pop();
                showFeedbackSheet(navigator.context);
              },
              icon: const Icon(Icons.feedback_outlined),
              label: const Text('Send feedback'),
            ),
            TextButton(
              key: const Key('account-done'),
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Done'),
            ),
          ],
        ),
      ),
    );
  }
}
