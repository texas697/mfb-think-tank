import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mfb_think_tank/features/readers_digest/application/digest_api_providers.dart';
import 'package:mfb_think_tank/features/readers_digest/application/digest_feed_provider.dart';
import 'package:mfb_think_tank/features/readers_digest/application/rating_provider.dart';
import 'package:mfb_think_tank/features/readers_digest/data/digest_failure.dart';

import '../../../helpers/fake_digest_repository.dart';

class _SlowRepo extends FakeDigestRepository {
  _SlowRepo({super.items});

  final gate = Completer<int>();

  @override
  Future<int> sendRating(String id, int rating) {
    ratings.add((id, rating));
    return gate.future;
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

      repo.gate.complete(1);
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
    },
  );

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

class _FailingRepo extends FakeDigestRepository {
  _FailingRepo({super.items});

  @override
  Future<int> sendRating(String id, int rating) async =>
      throw const DigestNetwork();
}
