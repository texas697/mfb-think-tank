import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mfb_think_tank/features/readers_digest/application/rating_provider.dart';
import 'package:mfb_think_tank/features/readers_digest/presentation/digest_colors.dart';

/// Independent thumbs up/down controls for one article.
class RatingButtons extends ConsumerWidget {
  const RatingButtons({required this.id, super.key});

  final String id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = DigestColors.of(context);
    final rating = ref.watch(ratingProvider(id));
    final notifier = ref.read(ratingProvider(id).notifier);
    ref.listen(ratingProvider(id), (previous, next) {
      final error = next.error;
      if (error == null || error == previous?.error) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error),
          action: SnackBarAction(label: 'Retry', onPressed: notifier.retry),
        ),
      );
      notifier.clearError();
    });
    final onPressed = rating.isSaving ? null : notifier.send;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          key: Key('rate-up-$id'),
          tooltip: rating.isUp ? 'Remove thumbs up' : 'Thumbs up',
          isSelected: rating.isUp,
          color: colors.muted,
          selectedIcon: Icon(Icons.thumb_up, color: colors.accent),
          icon: const Icon(Icons.thumb_up_outlined),
          onPressed: onPressed == null ? null : () => onPressed(1),
        ),
        IconButton(
          key: Key('rate-down-$id'),
          tooltip: rating.isDown ? 'Remove thumbs down' : 'Thumbs down',
          isSelected: rating.isDown,
          color: colors.muted,
          selectedIcon: Icon(Icons.thumb_down, color: colors.danger),
          icon: const Icon(Icons.thumb_down_outlined),
          onPressed: onPressed == null ? null : () => onPressed(-1),
        ),
      ],
    );
  }
}
