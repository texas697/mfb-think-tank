import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mfb_think_tank/features/readers_digest/application/digest_api_providers.dart';
import 'package:mfb_think_tank/features/readers_digest/application/digest_query_provider.dart';
import 'package:mfb_think_tank/features/readers_digest/data/digest_feed.dart';

/// Library feed for the current query and signed-in user.
final digestFeedProvider =
    AsyncNotifierProvider<DigestFeedNotifier, DigestFeed>(
      DigestFeedNotifier.new,
    );

class DigestFeedNotifier extends AsyncNotifier<DigestFeed> {
  @override
  Future<DigestFeed> build() {
    ref.watch(digestQueryProvider);
    // Re-fetch when the signed-in user changes.
    ref.watch(currentUidProvider);
    return ref
        .read(digestRepositoryProvider)
        .fetchFeed(ref.read(digestQueryProvider));
  }

  /// Applies a server-confirmed vote to the loaded feed.
  void applyVote(String id, int rating) {
    final current = state.value;
    if (current == null) return;
    state = AsyncData(current.withVote(id, rating));
  }

  /// Marks an article as having a write-up after generation.
  void applyWriteup(String id) {
    final current = state.value;
    if (current == null) return;
    state = AsyncData(current.withWriteup(id, true));
  }

  /// Reloads the feed; previous data stays visible while refreshing.
  ///
  /// Completes once the reload settles. A failed reload is not rethrown:
  /// the provider's [AsyncValue] already carries the error for the UI.
  Future<void> refresh() async {
    ref.invalidateSelf();
    try {
      await future;
    } catch (_) {
      // Surfaced through state as AsyncError.
    }
  }
}
