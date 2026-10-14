import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mfb_think_tank/features/readers_digest/application/app_lifecycle_provider.dart';
import 'package:mfb_think_tank/features/readers_digest/application/digest_api_providers.dart';
import 'package:mfb_think_tank/features/readers_digest/application/digest_feed_retry_provider.dart';
import 'package:mfb_think_tank/features/readers_digest/application/digest_query_provider.dart';
import 'package:mfb_think_tank/features/readers_digest/data/digest_feed.dart';

/// Library feed for the current query and signed-in user.
///
/// A transient failure (network, timeout, 429, 5xx) schedules an automatic
/// reload with the backoff from [digestFeedRetryProvider]; any manual reload
/// cancels the pending one.
final digestFeedProvider =
    AsyncNotifierProvider<DigestFeedNotifier, DigestFeed>(
      DigestFeedNotifier.new,
      // No Riverpod-level retry: it would fire ten requests in thirteen
      // seconds before the error (and the backoff below) is ever seen.
      retry: (_, _) => null,
    );

class DigestFeedNotifier extends AsyncNotifier<DigestFeed> {
  @override
  Future<DigestFeed> build() {
    ref.watch(digestQueryProvider);
    // Re-fetch when the signed-in user changes.
    ref.watch(currentUidProvider);
    Timer? retry;
    ref.onDispose(() => retry?.cancel());
    listenSelf((_, next) {
      if (next.isLoading) return;
      final backoff = ref.read(digestFeedRetryProvider.notifier);
      if (!next.hasError || !DigestFeedRetryNotifier.isTransient(next.error)) {
        backoff.reset();
        return;
      }
      retry = Timer(backoff.scheduleNext(), () {
        if (!ref.mounted) return;
        backoff.clear();
        // Leave a backgrounded app alone; a pull to refresh covers it.
        if (ref.read(appLifecycleProvider) != AppLifecycleState.resumed) return;
        ref.invalidateSelf();
      });
    });
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
  /// A reload already in flight is awaited instead of being restarted, so
  /// repeated taps or pulls never send more than one request at a time.
  /// Completes once the reload settles. A failed reload is not rethrown:
  /// the provider's [AsyncValue] already carries the error for the UI.
  Future<void> refresh() async {
    if (!state.isLoading) ref.invalidateSelf();
    try {
      await future;
    } catch (_) {
      // Surfaced through state as AsyncError.
    }
  }
}
