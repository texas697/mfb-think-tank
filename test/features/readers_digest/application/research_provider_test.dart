import 'package:fake_async/fake_async.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mfb_think_tank/features/readers_digest/application/digest_api_providers.dart';
import 'package:mfb_think_tank/features/readers_digest/application/research_provider.dart';
import 'package:mfb_think_tank/features/readers_digest/data/article_detail.dart';
import 'package:mfb_think_tank/features/readers_digest/data/research_result.dart';

import '../../../helpers/fake_digest_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('polls while running, stops when done, and starts only once', () {
    fakeAsync((async) {
      final repo = FakeDigestRepository(
        details: {'a': ArticleDetail(card: fakeCard('a'))},
      );
      final container = ProviderContainer(
        overrides: [
          digestRepositoryProvider.overrideWithValue(repo),
          currentUidProvider.overrideWithValue('u1'),
        ],
      );
      final sub = container.listen(researchProvider('a'), (_, _) {});
      async.flushMicrotasks();
      final syncFetches = repo.researchFetches;

      repo.research = const ResearchResult(state: 'running', stage: 'reading');
      container.read(researchProvider('a').notifier).start();
      async.flushMicrotasks();
      expect(repo.researchStarts, 1);
      expect(sub.read().result.isRunning, isTrue);

      async.elapse(const Duration(milliseconds: 2600));
      expect(repo.researchFetches, syncFetches + 1);
      expect(sub.read().result.stage, 'reading');

      repo.research = const ResearchResult(state: 'done', markdown: '# Done');
      async.elapse(const Duration(seconds: 3));
      expect(sub.read().result.isDone, isTrue);

      final fetches = repo.researchFetches;
      async.elapse(const Duration(seconds: 30));
      expect(repo.researchFetches, fetches);
      expect(repo.researchStarts, 1);
      container.dispose();
    });
  });

  test('does not poll while the app is paused', () {
    fakeAsync((async) {
      final repo = FakeDigestRepository(
        details: {'a': ArticleDetail(card: fakeCard('a'))},
      )..research = const ResearchResult(state: 'running');
      final container = ProviderContainer(
        overrides: [
          digestRepositoryProvider.overrideWithValue(repo),
          currentUidProvider.overrideWithValue('u1'),
        ],
      );
      container.listen(researchProvider('a'), (_, _) {});
      async.flushMicrotasks();
      container.read(researchProvider('a').notifier).start();
      async.flushMicrotasks();
      TestWidgetsFlutterBinding.instance.handleAppLifecycleStateChanged(
        AppLifecycleState.paused,
      );
      final fetches = repo.researchFetches;
      async.elapse(const Duration(seconds: 10));
      expect(repo.researchFetches, fetches);
      TestWidgetsFlutterBinding.instance.handleAppLifecycleStateChanged(
        AppLifecycleState.resumed,
      );
      container.dispose();
    });
  });
}
