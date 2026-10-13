import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mfb_think_tank/features/readers_digest/application/article_detail_provider.dart';
import 'package:mfb_think_tank/features/readers_digest/application/digest_api_providers.dart';
import 'package:mfb_think_tank/features/readers_digest/application/digest_feed_provider.dart';
import 'package:mfb_think_tank/features/readers_digest/application/rating_provider.dart';
import 'package:mfb_think_tank/features/readers_digest/data/article_detail.dart';
import 'package:mfb_think_tank/features/readers_digest/data/digest_failure.dart';

import '../../../helpers/fake_digest_repository.dart';

/// Holds every save open until the test completes that article's gate.
class _SlowRepo extends FakeDigestRepository {
  _SlowRepo({super.items});

  final gates = <String, Completer<int>>{};

  Completer<int> gate(String id) => gates.putIfAbsent(id, Completer.new);

  @override
  Future<int> sendRating(String id, int rating) {
    ratings.add((id, rating));
    return gate(id).future;
  }
}

class _FailingRepo extends FakeDigestRepository {
  _FailingRepo({super.items});

  @override
  Future<int> sendRating(String id, int rating) async =>
      throw const DigestNetwork();
}

/// Fails the first save, then behaves like the in-memory fake.
class _FlakyRepo extends FakeDigestRepository {
  _FlakyRepo({super.items});

  var hasFailed = false;

  @override
  Future<int> sendRating(String id, int rating) async {
    if (!hasFailed) {
      hasFailed = true;
      throw const DigestNetwork();
    }
    return super.sendRating(id, rating);
  }
}

void main() {
  ProviderContainer make(FakeDigestRepository repo, {String uid = 'u1'}) {
    final container = ProviderContainer(
      overrides: [
        digestRepositoryProvider.overrideWithValue(repo),
        currentUidProvider.overrideWithValue(uid),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  test(
    'ignores a second tap while saving and applies the server value',
    () async {
      final repo = _SlowRepo(items: [fakeCard('a')]);
      final container = make(repo);
      await container.read(digestFeedProvider.future);
      final notifier = container.read(ratingProvider('a').notifier);

      final first = notifier.send(1);
      await notifier.send(-1);
      expect(repo.ratings, [('a', 1)]);
      expect(container.read(ratingProvider('a')).isSaving, isTrue);

      repo.gate('a').complete(1);
      await first;
      expect(container.read(ratingProvider('a')).rating, 1);
      expect(container.read(digestFeedProvider).value!.items.single.vote, 1);
    },
  );

  test('pressing the selected thumb clears it', () async {
    final repo = FakeDigestRepository(items: [fakeCard('a', vote: 1)]);
    final container = make(repo);
    await container.read(digestFeedProvider.future);
    await container.read(ratingProvider('a').notifier).send(1);
    expect(repo.ratings.single, ('a', 0));
    expect(container.read(ratingProvider('a')).rating, 0);
  });

  test(
    'a failed save restores the previous rating and shows the error',
    () async {
      final repo = _FailingRepo(items: [fakeCard('a', vote: 1)]);
      final container = make(repo);
      await container.read(digestFeedProvider.future);
      await container.read(ratingProvider('a').notifier).send(-1);
      final state = container.read(ratingProvider('a'));
      expect(state.rating, 1);
      expect(state.error, const DigestNetwork().message);
      expect(state.pendingRating, -1);
      expect(state.canRetry, isTrue);
    },
  );

  test('retry re-posts the failed vote after the error is cleared', () async {
    final repo = _FlakyRepo(items: [fakeCard('a')]);
    final container = make(repo);
    await container.read(digestFeedProvider.future);
    final notifier = container.read(ratingProvider('a').notifier);

    await notifier.send(1);
    expect(container.read(ratingProvider('a')).rating, 0);
    notifier.clearError();
    expect(container.read(ratingProvider('a')).pendingRating, 1);

    await notifier.retry();
    expect(repo.ratings.single, ('a', 1));
    final state = container.read(ratingProvider('a'));
    expect(state.rating, 1);
    expect(state.pendingRating, isNull);
    expect(container.read(digestFeedProvider).value!.items.single.vote, 1);
  });

  test(
    'retry with a prior thumbs up re-posts the down vote, not a clear',
    () async {
      final repo = _FlakyRepo(items: [fakeCard('a', vote: 1)]);
      final container = make(repo);
      await container.read(digestFeedProvider.future);
      final notifier = container.read(ratingProvider('a').notifier);

      await notifier.send(-1);
      expect(container.read(ratingProvider('a')).rating, 1);

      await notifier.retry();
      expect(repo.ratings.single, ('a', -1));
      expect(container.read(ratingProvider('a')).rating, -1);
    },
  );

  test('retry is a no-op when nothing failed', () async {
    final repo = FakeDigestRepository(items: [fakeCard('a', vote: 1)]);
    final container = make(repo);
    await container.read(digestFeedProvider.future);
    await container.read(ratingProvider('a').notifier).retry();
    expect(repo.ratings, isEmpty);
    expect(container.read(ratingProvider('a')).rating, 1);
  });

  test('rating from the library never fetches the article', () async {
    final repo = FakeDigestRepository(items: [fakeCard('a')]);
    final container = make(repo);
    await container.read(digestFeedProvider.future);
    await container.read(ratingProvider('a').notifier).send(1);
    expect(repo.ratings.single, ('a', 1));
    expect(repo.articleFetches, 0);
    expect(container.exists(articleDetailProvider('a')), isFalse);
  });

  test('rating from the reader applies the vote to the open article', () async {
    final repo = FakeDigestRepository(
      details: {'a': ArticleDetail(card: fakeCard('a'))},
    );
    final container = make(repo);
    await container.read(articleDetailProvider('a').future);
    expect(repo.articleFetches, 1);

    await container.read(ratingProvider('a').notifier).send(1);
    expect(repo.articleFetches, 1);
    expect(container.read(articleDetailProvider('a')).value!.card.vote, 1);
  });

  test('a vote landing on card A keeps card B saving', () async {
    final repo = _SlowRepo(items: [fakeCard('a'), fakeCard('b')]);
    final container = make(repo);
    await container.read(digestFeedProvider.future);
    container.listen(ratingProvider('a'), (_, _) {});
    container.listen(ratingProvider('b'), (_, _) {});
    final a = container.read(ratingProvider('a').notifier);
    final b = container.read(ratingProvider('b').notifier);

    final saveA = a.send(1);
    final saveB = b.send(-1);
    expect(container.read(ratingProvider('b')).isSaving, isTrue);

    repo.gate('a').complete(1);
    await saveA;
    await container.pump();
    expect(container.read(ratingProvider('a')).rating, 1);
    expect(container.read(ratingProvider('b')).isSaving, isTrue);
    await b.send(1);
    expect(repo.ratings, [('a', 1), ('b', -1)]);

    repo.gate('b').complete(-1);
    await saveB;
    expect(container.read(ratingProvider('b')).rating, -1);
    final votes = container.read(digestFeedProvider).value!.items;
    expect(votes.map((item) => item.vote), [1, -1]);
  });

  test('a user change discards the previous feed', () async {
    final repo = FakeDigestRepository(items: [fakeCard('a')]);
    final container = make(repo);
    await container.read(digestFeedProvider.future);
    expect(repo.queries, hasLength(1));
    container.updateOverrides([
      digestRepositoryProvider.overrideWithValue(repo),
      currentUidProvider.overrideWithValue('u2'),
    ]);
    await container.read(digestFeedProvider.future);
    expect(repo.queries, hasLength(2));
  });
}
