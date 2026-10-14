import 'package:fake_async/fake_async.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mfb_think_tank/features/readers_digest/application/digest_api_providers.dart';
import 'package:mfb_think_tank/features/readers_digest/application/digest_feed_provider.dart';
import 'package:mfb_think_tank/features/readers_digest/application/digest_feed_retry_provider.dart';
import 'package:mfb_think_tank/features/readers_digest/data/digest_failure.dart';
import 'package:mfb_think_tank/features/readers_digest/data/digest_feed.dart';

import '../../../helpers/fake_digest_repository.dart';

ProviderContainer _container(FakeDigestRepository repo) {
  final container = ProviderContainer(
    overrides: [
      digestRepositoryProvider.overrideWithValue(repo),
      currentUidProvider.overrideWithValue('u1'),
    ],
  );
  // Keep the feed alive and rebuilding, as the screen does.
  container.listen(digestFeedProvider, (_, _) {});
  return container;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('retries transient failures with exponential backoff', () {
    fakeAsync((async) {
      final repo = FakeDigestRepository(
        items: [fakeCard('a')],
        feedError: const DigestTooManyRequests(),
      );
      final container = _container(repo);
      addTearDown(container.dispose);
      async.flushMicrotasks();
      expect(repo.queries.length, 1);
      expect(
        container.read(digestFeedRetryProvider),
        const Duration(seconds: 2),
      );

      async.elapse(const Duration(seconds: 1));
      expect(repo.queries.length, 1);
      async.elapse(const Duration(seconds: 1));
      expect(repo.queries.length, 2);
      expect(
        container.read(digestFeedRetryProvider),
        const Duration(seconds: 4),
      );

      async.elapse(const Duration(seconds: 4));
      expect(repo.queries.length, 3);
      expect(
        container.read(digestFeedRetryProvider),
        const Duration(seconds: 8),
      );

      repo.feedError = null;
      async.elapse(const Duration(seconds: 8));
      expect(repo.queries.length, 4);
      expect(container.read(digestFeedProvider).value, isA<DigestFeed>());
      expect(container.read(digestFeedRetryProvider), isNull);

      // Nothing else fires once the feed has loaded.
      async.elapse(const Duration(minutes: 5));
      expect(repo.queries.length, 4);
    });
  });

  test('caps the delay at one minute', () {
    fakeAsync((async) {
      final repo = FakeDigestRepository(feedError: const DigestNetwork());
      final container = _container(repo);
      addTearDown(container.dispose);
      async.elapse(const Duration(minutes: 10));
      expect(
        container.read(digestFeedRetryProvider),
        const Duration(minutes: 1),
      );
      final before = repo.queries.length;
      async.elapse(const Duration(minutes: 1));
      expect(repo.queries.length, before + 1);
    });
  });

  test('does not retry failures the user has to fix', () {
    fakeAsync((async) {
      final repo = FakeDigestRepository(feedError: const DigestForbidden());
      final container = _container(repo);
      addTearDown(container.dispose);
      async.elapse(const Duration(minutes: 5));
      expect(repo.queries.length, 1);
      expect(container.read(digestFeedRetryProvider), isNull);
    });
  });

  test('a manual refresh cancels the pending retry and is not duplicated', () {
    fakeAsync((async) {
      final repo = FakeDigestRepository(feedError: const DigestNetwork());
      final container = _container(repo);
      addTearDown(container.dispose);
      async.flushMicrotasks();
      final notifier = container.read(digestFeedProvider.notifier);
      notifier.refresh();
      notifier.refresh();
      notifier.refresh();
      async.flushMicrotasks();
      expect(repo.queries.length, 2);
      // The retry scheduled by the first failure was cancelled; only the
      // one scheduled by the manual refresh's failure fires.
      async.elapse(const Duration(seconds: 2));
      expect(repo.queries.length, 2);
      async.elapse(const Duration(seconds: 2));
      expect(repo.queries.length, 3);
    });
  });
}
