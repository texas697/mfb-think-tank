import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mfb_think_tank/features/readers_digest/application/article_detail_provider.dart';
import 'package:mfb_think_tank/features/readers_digest/application/digest_api_providers.dart';
import 'package:mfb_think_tank/features/readers_digest/application/digest_feed_provider.dart';
import 'package:mfb_think_tank/features/readers_digest/data/digest_failure.dart';

/// Write-up generation state for one article.
@immutable
class ArticleActionState {
  const ArticleActionState({this.isSummarizing = false, this.error});

  final bool isSummarizing;
  final String? error;

  ArticleActionState copyWith({bool? isSummarizing, String? error}) =>
      ArticleActionState(
        isSummarizing: isSummarizing ?? this.isSummarizing,
        error: error,
      );
}

/// Generates the AI write-up for one article. Duplicate taps while running
/// are ignored; failures keep the readable content and expose a message.
final articleActionProvider =
    NotifierProvider.family<ArticleActionNotifier, ArticleActionState, String>(
      ArticleActionNotifier.new,
    );

class ArticleActionNotifier extends Notifier<ArticleActionState> {
  ArticleActionNotifier(this.id);

  final String id;

  @override
  ArticleActionState build() => const ArticleActionState();

  /// Generates the write-up; returns true on success.
  Future<bool> summarize() async {
    if (state.isSummarizing) return false;
    state = const ArticleActionState(isSummarizing: true);
    try {
      final refreshed = await ref.read(digestRepositoryProvider).summarize(id);
      ref.read(articleDetailProvider(id).notifier).applySummary(refreshed);
      _markDone();
      return true;
    } catch (error) {
      if (_mayHaveCompleted(error) && await _refreshFindsWriteup()) {
        _markDone();
        return true;
      }
      state = ArticleActionState(error: _message(error));
      return false;
    }
  }

  void _markDone() {
    ref.read(digestFeedProvider.notifier).applyWriteup(id);
    state = const ArticleActionState();
  }

  // A timeout or dropped connection says nothing about the server, which may
  // have finished and stored the write-up after the client gave up.
  bool _mayHaveCompleted(Object error) =>
      error is DigestTimeout || error is DigestNetwork;

  Future<bool> _refreshFindsWriteup() async {
    await ref.read(articleDetailProvider(id).notifier).refresh();
    return ref.read(articleDetailProvider(id)).value?.hasWriteup ?? false;
  }

  /// Clears a visible error after the user acknowledges it.
  void clearError() {
    if (state.error == null) return;
    state = state.copyWith();
  }

  String _message(Object error) => error is DigestFailure
      ? error.message
      : 'Could not write this up. Try again.';
}
