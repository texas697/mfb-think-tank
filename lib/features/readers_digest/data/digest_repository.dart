import 'package:mfb_think_tank/features/readers_digest/data/article_detail.dart';
import 'package:mfb_think_tank/features/readers_digest/data/digest_feed.dart';
import 'package:mfb_think_tank/features/readers_digest/data/digest_query.dart';
import 'package:mfb_think_tank/features/readers_digest/data/research_result.dart';

/// Digest API contract. Implementations throw `DigestFailure` only.
///
/// Never auto-retries ratings or generation POSTs: a lost response can
/// conceal a successful mutation.
abstract interface class DigestRepository {
  /// Library feed with votes, topics, taste, and ranking metadata.
  Future<DigestFeed> fetchFeed(DigestQuery query);

  /// Full article for the reader, including the user's research projection.
  Future<ArticleDetail> fetchArticle(String id);

  /// Saves a rating (-1, 0, 1) and returns the server-confirmed rating.
  ///
  /// Sending the currently selected rating clears it (returns 0).
  Future<int> sendRating(String id, int rating);

  /// Generates an AI write-up with the user's key; returns the refreshed
  /// article.
  Future<ArticleDetail> summarize(String id);

  /// Starts (or regenerates) research. Resolves when the server accepts the
  /// job (202); poll [fetchResearch] for progress.
  Future<void> startResearch(String id);

  /// Latest research state for this user and article.
  Future<ResearchResult> fetchResearch(String id);
}
