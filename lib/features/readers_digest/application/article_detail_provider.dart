import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mfb_think_tank/features/readers_digest/application/digest_api_providers.dart';
import 'package:mfb_think_tank/features/readers_digest/data/article_detail.dart';
import 'package:mfb_think_tank/features/readers_digest/data/research_result.dart';

/// Full article for the reader, keyed by article id and signed-in user.
final articleDetailProvider =
    AsyncNotifierProvider.family<ArticleDetailNotifier, ArticleDetail, String>(
      ArticleDetailNotifier.new,
    );

class ArticleDetailNotifier extends AsyncNotifier<ArticleDetail> {
  ArticleDetailNotifier(this.id);

  final String id;

  @override
  Future<ArticleDetail> build() {
    // Discard cached data when the signed-in user changes.
    ref.watch(currentUidProvider);
    return ref.read(digestRepositoryProvider).fetchArticle(id);
  }

  /// Applies a server-confirmed vote.
  void applyVote(int rating) {
    final current = state.value;
    if (current == null) return;
    state = AsyncData(current.withVote(rating));
  }

  /// Replaces the article with a summarize response.
  void applySummary(ArticleDetail refreshed) => state = AsyncData(refreshed);

  /// Merges a polled research result without a full refetch.
  void applyResearch(ResearchResult research) {
    final current = state.value;
    if (current == null) return;
    state = AsyncData(current.withResearch(research));
  }

  /// Refreshes the article from the server, keeping the last readable
  /// content if the call fails.
  Future<void> refresh() async {
    try {
      final fresh = await ref.read(digestRepositoryProvider).fetchArticle(id);
      state = AsyncData(fresh);
    } catch (_) {
      final current = state.value;
      if (current != null) state = AsyncData(current);
    }
  }
}
