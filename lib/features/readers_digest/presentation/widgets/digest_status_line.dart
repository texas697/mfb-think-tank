import 'package:material_ui/material_ui.dart';
import 'package:mfb_think_tank/features/readers_digest/data/digest_feed.dart';
import 'package:mfb_think_tank/features/readers_digest/presentation/digest_colors.dart';

/// Truthful library status: loaded/matching counts and ranking mode.
class DigestStatusLine extends StatelessWidget {
  const DigestStatusLine({required this.feed, super.key});

  final DigestFeed feed;

  @override
  Widget build(BuildContext context) {
    final ranking = feed.isRankedByAffinity
        ? 'ranked for you'
        : feed.ratingsUntilAffinity > 0
        ? 'newest first · rate ${feed.ratingsUntilAffinity} more to personalize'
        : 'newest first';
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
      child: Text(
        '${feed.items.length} of ${feed.total} matching · '
        '${feed.storeSize} in library · $ranking',
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: DigestColors.of(context).muted,
          fontFamily: 'GeistMono',
        ),
      ),
    );
  }
}
