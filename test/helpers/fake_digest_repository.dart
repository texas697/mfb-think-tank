import 'package:mfb_think_tank/features/readers_digest/data/article_card.dart';
import 'package:mfb_think_tank/features/readers_digest/data/article_detail.dart';
import 'package:mfb_think_tank/features/readers_digest/data/digest_failure.dart';
import 'package:mfb_think_tank/features/readers_digest/data/digest_feed.dart';
import 'package:mfb_think_tank/features/readers_digest/data/digest_query.dart';
import 'package:mfb_think_tank/features/readers_digest/data/digest_repository.dart';
import 'package:mfb_think_tank/features/readers_digest/data/research_result.dart';
import 'package:mfb_think_tank/features/readers_digest/data/topic_count.dart';

ArticleCard fakeCard(
  String id, {
  String title = 'Title',
  String kind = 'news',
  bool hasWriteup = false,
  int vote = 0,
  List<String> topics = const ['ai-policy'],
}) => ArticleCard(
  id: id,
  url: 'https://example.com/$id',
  title: '$title $id',
  source: 'Example',
  kind: kind,
  description: 'About $id',
  topics: topics,
  hasWriteup: hasWriteup,
  vote: vote,
);

/// In-memory [DigestRepository] for widget and provider tests.
class FakeDigestRepository implements DigestRepository {
  FakeDigestRepository({
    this.items = const [],
    Map<String, ArticleDetail>? details,
    this.mode = 'chrono',
    this.feedError,
    this.summarizeError,
  }) : details = details ?? {};

  List<ArticleCard> items;
  final Map<String, ArticleDetail> details;
  final String mode;
  DigestFailure? feedError;
  DigestFailure? summarizeError;
  ArticleDetail? summarizeResult;
  ResearchResult research = const ResearchResult();

  final queries = <DigestQuery>[];
  final ratings = <(String, int)>[];
  var summarizeCalls = 0;
  var researchStarts = 0;
  var researchFetches = 0;

  @override
  Future<DigestFeed> fetchFeed(DigestQuery query) async {
    queries.add(query);
    final error = feedError;
    if (error != null) throw error;
    final shown = [
      for (final item in items)
        if (query.filter != DigestQuery.filterNews || item.kind == 'news')
          if (query.topic.isEmpty || item.topics.contains(query.topic))
            if (query.q.isEmpty || item.title.contains(query.q)) item,
    ];
    return DigestFeed(
      items: shown,
      total: shown.length,
      mode: mode,
      storeSize: items.length,
      topics: const [TopicCount(topic: 'ai-policy', count: 2)],
    );
  }

  @override
  Future<ArticleDetail> fetchArticle(String id) async =>
      details[id] ?? (throw const DigestNotFound());

  @override
  Future<int> sendRating(String id, int rating) async {
    ratings.add((id, rating));
    return rating;
  }

  @override
  Future<ArticleDetail> summarize(String id) async {
    summarizeCalls++;
    final error = summarizeError;
    if (error != null) throw error;
    return summarizeResult ?? details[id]!;
  }

  @override
  Future<void> startResearch(String id) async => researchStarts++;

  @override
  Future<ResearchResult> fetchResearch(String id) async {
    researchFetches++;
    return research;
  }
}
