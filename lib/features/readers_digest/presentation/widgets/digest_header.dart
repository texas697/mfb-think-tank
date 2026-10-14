import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mfb_think_tank/features/auth/application/auth_providers.dart';
import 'package:mfb_think_tank/features/digest_settings/presentation/account_sheet.dart';
import 'package:mfb_think_tank/features/feedback/presentation/feedback_sheet.dart';
import 'package:mfb_think_tank/features/readers_digest/presentation/digest_colors.dart';

/// Brand row with the account button, then the screen title.
class DigestHeader extends ConsumerWidget {
  const DigestHeader({super.key});

  static const _barHeight = 64.0;
  static const _iconSize = 30.0;
  static const _avatarSize = 44.0;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colors = DigestColors.of(context);
    final user = ref.watch(currentUserProvider).value;
    final label = user?.displayName ?? user?.email ?? '';
    final initial = label.isEmpty ? '?' : label[0].toUpperCase();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Taller than a default toolbar so the buttons sit at the same scale
        // as the 44dp wordmark.
        // The wordmark's swoosh already indents the letters, so the bar
        // sits closer to the edge than the content below it.
        Container(
          height: _barHeight,
          padding: const EdgeInsets.fromLTRB(4, 0, 8, 0),
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: colors.border)),
          ),
          child: Row(
            children: [
              const Expanded(child: _BrandLockup()),
              IconButton(
                key: const Key('open-feedback'),
                tooltip: 'Send feedback',
                iconSize: _iconSize,
                icon: const Icon(Icons.feedback_outlined),
                onPressed: () => showFeedbackSheet(context),
              ),
              IconButton(
                key: const Key('open-account'),
                tooltip: 'Account',
                iconSize: _avatarSize,
                icon: CircleAvatar(
                  radius: _avatarSize / 2,
                  backgroundColor: colors.raised,
                  child: Text(
                    initial,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                onPressed: () => showAccountSheet(context),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Text(
            'Think tanks and news, ranked by what you rate.',
            style: theme.textTheme.bodyMedium?.copyWith(color: colors.muted),
          ),
        ),
      ],
    );
  }
}

/// MFB Services Inc. wordmark, then an INTELLIGENCE tag drawn as text so it
/// stays legible. The tag is dropped when the row is too narrow (phones).
class _BrandLockup extends StatelessWidget {
  const _BrandLockup();

  static const _minWidthForTag = 320.0;

  @override
  Widget build(BuildContext context) {
    final colors = DigestColors.of(context);
    return LayoutBuilder(
      builder: (context, constraints) => Row(
        children: [
          Image.asset(
            'assets/brand/mfb_wordmark_dark.png',
            height: 44,
            semanticLabel: 'MFB Services Inc.',
          ),
          if (constraints.maxWidth >= _minWidthForTag) ...[
            const SizedBox(width: 14),
            Container(width: 1, height: 28, color: colors.muted),
            const SizedBox(width: 14),
            Text(
              'INTELLIGENCE',
              style: TextStyle(
                color: colors.text,
                fontSize: 13,
                fontWeight: FontWeight.w700,
                letterSpacing: 3,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
