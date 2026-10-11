import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mfb_think_tank/features/auth/application/auth_providers.dart';

/// "or" divider plus Google / Apple buttons, as allowed by
/// [socialSignInOptionsProvider]. Renders nothing if no option applies.
class SocialSignInButtons extends ConsumerWidget {
  const SocialSignInButtons({
    required this.enabled,
    required this.onGoogle,
    required this.onApple,
    super.key,
  });

  final bool enabled;
  final VoidCallback onGoogle;
  final VoidCallback onApple;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final options = ref.watch(socialSignInOptionsProvider);
    if (!options.showGoogle && !options.showApple) {
      return const SizedBox.shrink();
    }
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 24),
        Row(
          children: [
            const Expanded(child: Divider()),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text('or', style: theme.textTheme.bodySmall),
            ),
            const Expanded(child: Divider()),
          ],
        ),
        const SizedBox(height: 24),
        if (options.showApple) ...[
          // Apple's HIG asks for this button to be at least as prominent as
          // other third-party sign-in buttons.
          FilledButton.icon(
            key: const Key('apple-sign-in'),
            style: FilledButton.styleFrom(
              backgroundColor: theme.brightness == Brightness.dark
                  ? Colors.white
                  : Colors.black,
              foregroundColor: theme.brightness == Brightness.dark
                  ? Colors.black
                  : Colors.white,
            ),
            onPressed: enabled ? onApple : null,
            icon: const Icon(Icons.apple),
            label: const Text('Sign in with Apple'),
          ),
          const SizedBox(height: 12),
        ],
        if (options.showGoogle) ...[
          OutlinedButton.icon(
            key: const Key('google-sign-in'),
            onPressed: enabled && options.googleConfigured ? onGoogle : null,
            icon: const Text(
              'G',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            label: const Text('Continue with Google'),
          ),
          if (!options.googleConfigured) ...[
            const SizedBox(height: 8),
            Text(
              'Google Sign-In is not configured. Add the client ids to '
              'config/app_config.json (see README) and rebuild.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ],
    );
  }
}
