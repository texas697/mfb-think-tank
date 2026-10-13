import 'package:material_ui/material_ui.dart';
import 'package:mfb_think_tank/features/readers_digest/data/taste_summary.dart';
import 'package:mfb_think_tank/features/readers_digest/presentation/digest_colors.dart';
import 'package:mfb_think_tank/features/readers_digest/presentation/topic_label.dart';

/// Topics the server learned the user likes and dislikes.
class DigestTasteRow extends StatelessWidget {
  const DigestTasteRow({required this.taste, super.key});

  final TasteSummary taste;

  @override
  Widget build(BuildContext context) {
    final colors = DigestColors.of(context);
    final style = Theme.of(context).textTheme.bodySmall;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Wrap(
        spacing: 12,
        children: [
          for (final entry in taste.likes)
            Text(
              '+ ${topicLabel(entry.topic)}',
              style: style?.copyWith(color: colors.accent),
            ),
          for (final entry in taste.dislikes)
            Text(
              '− ${topicLabel(entry.topic)}',
              style: style?.copyWith(color: colors.danger),
            ),
        ],
      ),
    );
  }
}
