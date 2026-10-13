import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mfb_think_tank/app/router.dart';
import 'package:mfb_think_tank/features/readers_digest/data/article_detail.dart';
import 'package:mfb_think_tank/features/readers_digest/presentation/digest_colors.dart';
import 'package:mfb_think_tank/features/readers_digest/presentation/relative_time.dart';
import 'package:mfb_think_tank/features/readers_digest/presentation/topic_label.dart';
import 'package:mfb_think_tank/features/readers_digest/presentation/widgets/kind_badge.dart';

/// Source, kind, time, author, title and topic links for the reader.
class ReaderHeader extends StatelessWidget {
  const ReaderHeader({required this.detail, super.key});

  final ArticleDetail detail;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = DigestColors.of(context);
    final card = detail.card;
    final meta = [
      card.source,
      relativeTime(card.publishedAt ?? card.fetchedAt),
      if ((detail.author ?? '').isNotEmpty) detail.author!,
    ].where((s) => s.isNotEmpty).join(' · ');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            KindBadge(isThinkTank: card.isThinkTank),
            Text(
              meta,
              style: theme.textTheme.bodySmall?.copyWith(color: colors.muted),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          card.title,
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        if (card.topics.isNotEmpty) ...[
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            children: [
              for (final topic in card.topics)
                ActionChip(
                  key: Key('reader-topic-$topic'),
                  label: Text(topicLabel(topic)),
                  backgroundColor: colors.card,
                  side: BorderSide(color: colors.border),
                  onPressed: () => context.go(
                    Uri(
                      path: AppRoutes.home,
                      queryParameters: {'topic': topic},
                    ).toString(),
                  ),
                ),
            ],
          ),
        ],
      ],
    );
  }
}
