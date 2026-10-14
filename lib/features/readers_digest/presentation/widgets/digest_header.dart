import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mfb_think_tank/features/auth/application/auth_providers.dart';
import 'package:mfb_think_tank/features/digest_settings/presentation/account_sheet.dart';
import 'package:mfb_think_tank/features/feedback/presentation/feedback_sheet.dart';
import 'package:mfb_think_tank/features/readers_digest/presentation/digest_colors.dart';

/// Brand row with the account button, then the screen title.
class DigestHeader extends ConsumerWidget {
  const DigestHeader({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colors = DigestColors.of(context);
    final user = ref.watch(currentUserProvider).value;
    final label = user?.displayName ?? user?.email ?? '';
    final initial = label.isEmpty ? '?' : label[0].toUpperCase();
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: _BrandLockup(),
                ),
              ),
              IconButton(
                key: const Key('open-feedback'),
                tooltip: 'Send feedback',
                icon: const Icon(Icons.feedback_outlined),
                onPressed: () => showFeedbackSheet(context),
              ),
              IconButton(
                key: const Key('open-account'),
                tooltip: 'Account',
                icon: CircleAvatar(
                  radius: 16,
                  backgroundColor: colors.raised,
                  child: Text(initial),
                ),
                onPressed: () => showAccountSheet(context),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Think Tank',
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          Text(
            'Think tanks and news, ranked by what you rate.',
            style: theme.textTheme.bodyMedium?.copyWith(color: colors.muted),
          ),
        ],
      ),
    );
  }
}

/// MFB Services Inc. wordmark over an INTELLIGENCE rule, drawn as text so
/// it stays legible at phone widths (the kit's one-piece navbar image does
/// not).
class _BrandLockup extends StatelessWidget {
  const _BrandLockup();

  static const _width = 180.0;

  @override
  Widget build(BuildContext context) {
    final colors = DigestColors.of(context);
    final rule = Expanded(child: Container(height: 1, color: colors.muted));
    return SizedBox(
      width: _width,
      child: Column(
        children: [
          Image.asset(
            'assets/brand/mfb_wordmark_dark.png',
            width: _width,
            semanticLabel: 'MFB Services Inc.',
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              rule,
              // Scales down under large fonts so the rules keep some width.
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: _width - 40),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: Text(
                      'INTELLIGENCE',
                      style: TextStyle(
                        color: colors.text,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 3,
                      ),
                    ),
                  ),
                ),
              ),
              rule,
            ],
          ),
        ],
      ),
    );
  }
}
