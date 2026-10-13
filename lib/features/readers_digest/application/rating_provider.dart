import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mfb_think_tank/features/readers_digest/application/article_detail_provider.dart';
import 'package:mfb_think_tank/features/readers_digest/application/digest_api_providers.dart';
import 'package:mfb_think_tank/features/readers_digest/application/digest_feed_provider.dart';
import 'package:mfb_think_tank/features/readers_digest/data/digest_failure.dart';
import 'package:mfb_think_tank/features/readers_digest/data/digest_feed.dart';

/// Vote state for one article: confirmed rating plus save progress.
@immutable
class RatingState {
  const RatingState({
    this.rating = 0,
    this.isSaving = false,
    this.error,
    this.pendingRating,
  });

  final int rating;
  final bool isSaving;
  final String? error;

  /// The value the last failed save tried to post, kept so a retry can
  /// re-send it as-is instead of toggling against [rating].
  final int? pendingRating;

  bool get isUp => rating > 0;
  bool get isDown => rating < 0;
  bool get canRetry => pendingRating != null && !isSaving;

  /// Drops [error]; keeps the rating and any pending retry value.
  RatingState copyWith({int? rating, bool? isSaving, String? error}) =>
      RatingState(
        rating: rating ?? this.rating,
        isSaving: isSaving ?? this.isSaving,
        error: error,
        pendingRating: pendingRating,
      );
}

/// Serialized per-article rating saves. Duplicate taps while saving are
/// ignored; the server-confirmed rating is the one applied everywhere.
final ratingProvider =
    NotifierProvider.family<RatingNotifier, RatingState, String>(
      RatingNotifier.new,
    );

class RatingNotifier extends Notifier<RatingState> {
  RatingNotifier(this.id);

  final String id;

  @override
  RatingState build() {
    final uid = ref.watch(currentUidProvider);
    if (uid == null) return const RatingState();
    // Seed from the loaded feed (library) or the reader's article. Only this
    // card's vote is selected so another card's save does not rebuild (and
    // reset) this notifier. The article is watched only when it already
    // exists so the library does not instantiate an article provider per card.
    final feedVote = ref.watch(digestFeedProvider.select(_voteFor));
    final articleVote = ref.exists(articleDetailProvider(id))
        ? ref.watch(articleDetailProvider(id)).value?.card.vote ?? 0
        : null;
    return RatingState(rating: feedVote ?? articleVote ?? 0);
  }

  int? _voteFor(AsyncValue<DigestFeed> feed) {
    final items = feed.value?.items;
    if (items == null) return null;
    for (final item in items) {
      if (item.id == id) return item.vote;
    }
    return null;
  }

  /// Sends a vote (1 = up, -1 = down). Pressing the currently selected thumb
  /// sends 0 to clear it. No-op while a save is in flight.
  Future<void> send(int rating) {
    if (state.isSaving) return Future.value();
    final previous = state.rating;
    return _post(rating == previous ? 0 : rating, previous);
  }

  /// Re-posts the value of the last failed save exactly, without the toggle
  /// rule. No-op when nothing failed or a save is in flight.
  Future<void> retry() {
    final pending = state.pendingRating;
    if (pending == null || state.isSaving) return Future.value();
    return _post(pending, state.rating);
  }

  Future<void> _post(int rating, int previous) async {
    state = RatingState(rating: rating, isSaving: true);
    try {
      final serverRating = await ref
          .read(digestRepositoryProvider)
          .sendRating(id, rating);
      state = RatingState(rating: serverRating);
      ref.read(digestFeedProvider.notifier).applyVote(id, serverRating);
      // Only the reader creates the article provider; do not fetch an
      // article the library never shows just to apply the vote.
      if (ref.exists(articleDetailProvider(id))) {
        ref.read(articleDetailProvider(id).notifier).applyVote(serverRating);
      }
    } catch (error) {
      state = RatingState(
        rating: previous,
        error: _message(error),
        pendingRating: rating,
      );
    }
  }

  /// Clears a visible error after the user acknowledges it.
  void clearError() {
    if (state.error == null) return;
    state = state.copyWith();
  }

  String _message(Object error) => error is DigestFailure
      ? error.message
      : 'Could not save your rating. Try again.';
}
