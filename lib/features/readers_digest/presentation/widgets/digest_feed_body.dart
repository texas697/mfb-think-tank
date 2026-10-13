import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mfb_think_tank/features/readers_digest/application/digest_feed_provider.dart';
import 'package:mfb_think_tank/features/readers_digest/data/digest_failure.dart';
import 'package:mfb_think_tank/features/readers_digest/data/digest_feed.dart';
import 'package:mfb_think_tank/features/readers_digest/data/digest_query.dart';
import 'package:mfb_think_tank/features/readers_digest/presentation/widgets/article_tile.dart';
import 'package:mfb_think_tank/features/readers_digest/presentation/widgets/digest_status_line.dart';
import 'package:mfb_think_tank/features/readers_digest/presentation/widgets/digest_taste_row.dart';
import 'package:mfb_think_tank/features/readers_digest/presentation/widgets/digest_topic_strip.dart';
import 'package:mfb_think_tank/features/readers_digest/presentation/widgets/feed_message.dart';

/// Everything below the pinned controls: topics, taste, status, cards, and the
/// loading, empty, no-match and error states.
class DigestFeedBody extends ConsumerWidget {
  const DigestFeedBody({
    required this.query,
    required this.onTopic,
    required this.onClearFilters,
    super.key,
  });

  final DigestQuery query;
  final ValueChanged<String> onTopic;
  final VoidCallback onClearFilters;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final feed = ref.watch(digestFeedProvider);
    final data = feed.value;
    final retry = ref.read(digestFeedProvider.notifier).refresh;
    if (data == null) {
      return SliverToBoxAdapter(
        child: feed.hasError
            ? FeedMessage(
                title: 'Could not load the library',
                body: _message(feed.error),
                actionLabel: 'Retry',
                onAction: retry,
              )
            : const Padding(
                padding: EdgeInsets.all(48),
                child: Center(child: CircularProgressIndicator()),
              ),
      );
    }
    final isFiltered =
        query.hasSearch || query.hasTopic || query.filter != 'all';
    final featured =
        !query.hasSearch && !query.hasTopic && data.items.isNotEmpty;
    return SliverMainAxisGroup(
      slivers: [
        if (feed.hasError)
          SliverToBoxAdapter(
            child: FeedMessage(
              title: 'Could not refresh',
              body: _message(feed.error),
              actionLabel: 'Retry',
              onAction: retry,
            ),
          ),
        if (data.topics.isNotEmpty)
          SliverToBoxAdapter(
            child: DigestTopicStrip(
              topics: data.topics,
              selected: query.topic,
              onSelected: onTopic,
            ),
          ),
        if (!data.taste.isEmpty)
          SliverToBoxAdapter(child: DigestTasteRow(taste: data.taste)),
        SliverToBoxAdapter(child: DigestStatusLine(feed: data)),
        if (data.items.isEmpty)
          SliverToBoxAdapter(
            child: isFiltered
                ? FeedMessage(
                    title: 'No matches',
                    body: 'Nothing in the library fits these filters.',
                    actionLabel: 'Clear filters',
                    onAction: onClearFilters,
                  )
                : const FeedMessage(
                    title: 'The library is empty',
                    body: 'New articles appear after the next ingestion.',
                  ),
          )
        else
          SliverList.builder(
            itemCount: data.items.length,
            itemBuilder: (context, index) => ArticleTile(
              card: data.items[index],
              featuredLabel: featured && index == 0 ? _label(data) : null,
            ),
          ),
        const SliverToBoxAdapter(child: SizedBox(height: 24)),
      ],
    );
  }

  String _label(DigestFeed feed) =>
      feed.isRankedByAffinity ? 'Top pick for you' : 'Latest';

  String _message(Object? error) => error is DigestFailure
      ? error.message
      : 'Something went wrong. Try again.';
}
