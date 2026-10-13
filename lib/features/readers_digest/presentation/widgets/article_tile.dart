import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mfb_think_tank/app/router.dart';
import 'package:mfb_think_tank/features/readers_digest/data/article_card.dart';
import 'package:mfb_think_tank/features/readers_digest/presentation/digest_colors.dart';
import 'package:mfb_think_tank/features/readers_digest/presentation/relative_time.dart';
import 'package:mfb_think_tank/features/readers_digest/presentation/widgets/kind_badge.dart';
import 'package:mfb_think_tank/features/readers_digest/presentation/widgets/rating_buttons.dart';

/// Library card for one article. The featured card is larger and carries a
/// server-driven [featuredLabel].
class ArticleTile extends StatelessWidget {
  const ArticleTile({required this.card, this.featuredLabel, super.key});

  final ArticleCard card;
  final String? featuredLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = DigestColors.of(context);
    final isFeatured = featuredLabel != null;
    final time = relativeTime(card.publishedAt ?? card.fetchedAt);
    return Card(
      color: isFeatured ? colors.raised : colors.card,
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: colors.border),
      ),
      child: InkWell(
        key: Key('article-${card.id}'),
        borderRadius: BorderRadius.circular(16),
        onTap: () => context.push(AppRoutes.articleLocation(card.id)),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 8, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (isFeatured)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    featuredLabel!.toUpperCase(),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: colors.accent,
                      fontFamily: 'GeistMono',
                    ),
                  ),
                ),
              Wrap(
                spacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  KindBadge(isThinkTank: card.isThinkTank),
                  Text(
                    [card.source, time].where((s) => s.isNotEmpty).join(' · '),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colors.muted,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Text(
                  card.title,
                  style:
                      (isFeatured
                              ? theme.textTheme.titleLarge
                              : theme.textTheme.titleMedium)
                          ?.copyWith(fontWeight: FontWeight.w600),
                ),
              ),
              if (card.description.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 6, right: 8),
                  child: Text(
                    card.description,
                    maxLines: isFeatured ? 4 : 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colors.muted,
                    ),
                  ),
                ),
              Row(
                children: [
                  if (card.hasWriteup)
                    Text(
                      'AI WRITE-UP',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: colors.accent,
                        fontFamily: 'GeistMono',
                      ),
                    ),
                  const Spacer(),
                  RatingButtons(id: card.id),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
