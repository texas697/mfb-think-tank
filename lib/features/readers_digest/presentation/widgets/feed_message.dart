import 'package:material_ui/material_ui.dart';
import 'package:mfb_think_tank/features/readers_digest/presentation/digest_colors.dart';

/// Centered message for loading failures, empty libraries and no matches.
class FeedMessage extends StatelessWidget {
  const FeedMessage({
    required this.title,
    this.body,
    this.actionLabel,
    this.onAction,
    super.key,
  });

  final String title;
  final String? body;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          Text(
            title,
            textAlign: TextAlign.center,
            style: theme.textTheme.titleMedium,
          ),
          if (body != null) ...[
            const SizedBox(height: 8),
            Text(
              body!,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: DigestColors.of(context).muted,
              ),
            ),
          ],
          if (actionLabel != null) ...[
            const SizedBox(height: 16),
            OutlinedButton(
              key: const Key('feed-message-action'),
              onPressed: onAction,
              child: Text(actionLabel!),
            ),
          ],
        ],
      ),
    );
  }
}
