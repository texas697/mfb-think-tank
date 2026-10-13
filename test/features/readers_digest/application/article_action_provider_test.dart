import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mfb_think_tank/features/readers_digest/application/article_action_provider.dart';
import 'package:mfb_think_tank/features/readers_digest/application/article_detail_provider.dart';
import 'package:mfb_think_tank/features/readers_digest/application/digest_api_providers.dart';
import 'package:mfb_think_tank/features/readers_digest/application/digest_feed_provider.dart';
import 'package:mfb_think_tank/features/readers_digest/data/article_detail.dart';
import 'package:mfb_think_tank/features/readers_digest/data/digest_failure.dart';

import '../../../helpers/fake_digest_repository.dart';

/// Fails the summarize call like a client that gave up, while the server
/// finishes and stores the write-up before the client refetches.
class _GaveUpRepo extends FakeDigestRepository {
  _GaveUpRepo({
    required super.items,
    required super.details,
    required this.failure,
    this.stored,
  });

  final DigestFailure failure;
  final ArticleDetail? stored;

  @override
  Future<ArticleDetail> summarize(String id) async {
    summarizeCalls++;
    final completed = stored;
    if (completed != null) details[id] = completed;
    throw failure;
  }
}

void main() {
  ArticleDetail plain() =>
      ArticleDetail(card: fakeCard('a'), textPreview: 'Excerpt');

  ArticleDetail written() => ArticleDetail(
    card: fakeCard('a', hasWriteup: true),
    summaryMd: '## Done',
  );

  Future<ProviderContainer> make(FakeDigestRepository repo) async {
    final container = ProviderContainer(
      overrides: [
        digestRepositoryProvider.overrideWithValue(repo),
        currentUidProvider.overrideWithValue('u1'),
      ],
    );
    addTearDown(container.dispose);
    await container.read(digestFeedProvider.future);
    await container.read(articleDetailProvider('a').future);
    return container;
  }

  for (final failure in const [DigestTimeout(), DigestNetwork()]) {
    test('${failure.runtimeType} then a refresh that finds the write-up '
        'counts as success', () async {
      final repo = _GaveUpRepo(
        items: [fakeCard('a')],
        details: {'a': plain()},
        failure: failure,
        stored: written(),
      );
      final container = await make(repo);

      final ok = await container
          .read(articleActionProvider('a').notifier)
          .summarize();

      expect(ok, isTrue);
      expect(repo.summarizeCalls, 1);
      final state = container.read(articleActionProvider('a'));
      expect(state.error, isNull);
      expect(state.isSummarizing, isFalse);
      expect(
        container.read(articleDetailProvider('a')).value?.summaryMd,
        '## Done',
      );
      expect(
        container.read(digestFeedProvider).value?.items.single.hasWriteup,
        isTrue,
      );
    });
  }

  test('a timeout with nothing stored still surfaces the error', () async {
    final repo = _GaveUpRepo(
      items: [fakeCard('a')],
      details: {'a': plain()},
      failure: const DigestTimeout(),
    );
    final container = await make(repo);

    final ok = await container
        .read(articleActionProvider('a').notifier)
        .summarize();

    expect(ok, isFalse);
    expect(repo.summarizeCalls, 1);
    expect(
      container.read(articleActionProvider('a')).error,
      const DigestTimeout().message,
    );
    expect(
      container.read(digestFeedProvider).value?.items.single.hasWriteup,
      isFalse,
    );
  });

  test('other failures do not refetch the article', () async {
    var fetches = 0;
    final repo = _GaveUpRepo(
      items: [fakeCard('a')],
      details: {'a': plain()},
      failure: const DigestMissingAiSettings(),
      stored: written(),
    );
    final container = await make(repo);
    container.listen(articleDetailProvider('a'), (_, _) => fetches++);

    final ok = await container
        .read(articleActionProvider('a').notifier)
        .summarize();

    expect(ok, isFalse);
    expect(fetches, 0);
    expect(container.read(articleActionProvider('a')).error, isNotNull);
  });
}
