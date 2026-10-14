import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mfb_think_tank/features/readers_digest/data/digest_failure.dart';

/// Delay before the feed retries on its own, or null when no retry is pending.
///
/// Backs off exponentially from [DigestFeedRetryNotifier.firstDelay] to
/// [DigestFeedRetryNotifier.maxDelay] across consecutive failures so a
/// backend outage is not met with a request storm from every open app.
final digestFeedRetryProvider =
    NotifierProvider<DigestFeedRetryNotifier, Duration?>(
      DigestFeedRetryNotifier.new,
    );

class DigestFeedRetryNotifier extends Notifier<Duration?> {
  static const firstDelay = Duration(seconds: 2);
  static const maxDelay = Duration(minutes: 1);

  // Lives for the app's lifetime: this provider has no dependencies, so it is
  // never rebuilt and the counter survives feed reloads.
  int _failures = 0;

  @override
  Duration? build() => null;

  /// Whether [error] is worth retrying without the user doing anything.
  static bool isTransient(Object? error) => switch (error) {
    DigestNetwork() ||
    DigestTimeout() ||
    DigestUnavailable() ||
    DigestTooManyRequests() ||
    DigestUnknown() => true,
    _ => false,
  };

  /// Records another failure and returns the delay before the next attempt.
  Duration scheduleNext() {
    final delay = _delayFor(_failures);
    _failures++;
    state = delay;
    return delay;
  }

  /// A retry attempt is now in flight.
  void clear() => state = null;

  /// The feed loaded, or failed in a way that a retry cannot fix.
  void reset() {
    _failures = 0;
    state = null;
  }

  Duration _delayFor(int failures) {
    final scaled = firstDelay * (1 << failures.clamp(0, 10));
    return scaled > maxDelay ? maxDelay : scaled;
  }
}
