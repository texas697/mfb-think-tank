import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mfb_think_tank/features/readers_digest/application/article_detail_provider.dart';
import 'package:mfb_think_tank/features/readers_digest/application/digest_api_providers.dart';
import 'package:mfb_think_tank/features/readers_digest/application/digest_feed_provider.dart';
import 'package:mfb_think_tank/features/readers_digest/data/digest_failure.dart';

/// Vote state for one article: confirmed rating plus save progress.
@immutable
class RatingState {
  const RatingState({this.rating = 0, this.isSaving = false, this.error});

  final int rating;
  final bool isSaving;
  final String? error;

  bool get isUp => rating > 0;
  bool get isDown => rating < 0;

  RatingState copyWith({int? rating, bool? isSaving, String? error}) =>
      RatingState(
        rating: rating ?? this.rating,
        isSaving: isSaving ?? this.isSaving,
        error: error,
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
    // Seed from the loaded feed (library) or the reader's article. The article
    // is watched only when it already exists so the library does not
    // instantiate an article provider per card.
    final feedVote = ref
        .watch(digestFeedProvider)
        .value
        ?.items
        .where((item) => item.id == id)
        .map((item) => item.vote)
        .firstOrNull;
    final articleVote = ref.exists(articleDetailProvider(id))
        ? ref.watch(articleDetailProvider(id)).value?.card.vote ?? 0
        : null;
    return RatingState(rating: feedVote ?? articleVote ?? 0);
  }

  /// Sends a vote (1 = up, -1 = down). Pressing the currently selected thumb
  /// sends 0 to clear it. No-op while a save is in flight.
  Future<void> send(int rating) async {
    if (state.isSaving) return;
    final previous = state.rating;
    final confirmed = rating == previous ? 0 : rating;
    state = RatingState(rating: confirmed, isSaving: true);
    try {
      final serverRating = await ref
          .read(digestRepositoryProvider)
          .sendRating(id, confirmed);
      state = RatingState(rating: serverRating);
      ref.read(digestFeedProvider.notifier).applyVote(id, serverRating);
      ref.read(articleDetailProvider(id).notifier).applyVote(serverRating);
    } catch (error) {
      state = RatingState(rating: previous, error: _message(error));
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
