import 'package:material_ui/material_ui.dart';

/// Recoverable stream failure, sized for both primary and monitor players.
class PlayerError extends StatelessWidget {
  const PlayerError({
    required this.message,
    required this.onRetry,
    required this.isPreview,
    super.key,
  });
  final String message;
  final VoidCallback onRetry;
  final bool isPreview;
  @override
  Widget build(BuildContext context) => Center(
    child: SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!isPreview) Text(message, textAlign: TextAlign.center),
          TextButton.icon(
            key: const Key('player-retry'),
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
          ),
        ],
      ),
    ),
  );
}
