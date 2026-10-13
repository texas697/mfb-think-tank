import 'dart:async';

import 'package:fake_async/fake_async.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mfb_think_tank/features/readers_digest/application/digest_api_providers.dart';
import 'package:mfb_think_tank/features/readers_digest/application/research_provider.dart';
import 'package:mfb_think_tank/features/readers_digest/data/article_detail.dart';
import 'package:mfb_think_tank/features/readers_digest/data/digest_failure.dart';
import 'package:mfb_think_tank/features/readers_digest/data/research_result.dart';

import '../../../helpers/fake_digest_repository.dart';

/// Fails `fetchResearch` [failuresLeft] times, then answers normally.
class _FlakyRepository extends FakeDigestRepository {
  _FlakyRepository({required this.failuresLeft, super.details});

  int failuresLeft;

  @override
  Future<ResearchResult> fetchResearch(String id) async {
    researchFetches++;
    if (failuresLeft > 0) {
      failuresLeft--;
      throw const DigestNetwork();
    }
    return research;
  }
}

/// Every `fetchResearch` stays in flight until the test completes it.
class _PendingRepository extends FakeDigestRepository {
  _PendingRepository({super.details});

  final pending = <Completer<ResearchResult>>[];

  @override
  Future<ResearchResult> fetchResearch(String id) {
    researchFetches++;
    final completer = Completer<ResearchResult>();
    pending.add(completer);
    return completer.future;
  }
}

/// Switchable uid so a test can sign a different user in mid-poll.
final _uidProvider = NotifierProvider<_UidNotifier, String?>(_UidNotifier.new);

class _UidNotifier extends Notifier<String?> {
  @override
  String? build() => 'u1';

  void set(String? uid) => state = uid;
}

ProviderContainer _container(FakeDigestRepository repo) => ProviderContainer(
  overrides: [
    digestRepositoryProvider.overrideWithValue(repo),
    currentUidProvider.overrideWith((ref) => ref.watch(_uidProvider)),
  ],
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('polls while running, stops when done, and starts only once', () {
    fakeAsync((async) {
      final repo = FakeDigestRepository(
        details: {'a': ArticleDetail(card: fakeCard('a'))},
      );
      final container = _container(repo);
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
      final container = _container(repo);
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

  test('backs off to 20 s, keeps polling, warns, and resets on success', () {
    fakeAsync((async) {
      // The initial sync fetch on build fails too, then polls 0..5 fail and
      // poll 6 succeeds.
      final repo = _FlakyRepository(
        failuresLeft: 7,
        details: {'a': ArticleDetail(card: fakeCard('a'))},
      )..research = const ResearchResult(state: 'running', stage: 'reading');
      final container = _container(repo);
      final sub = container.listen(researchProvider('a'), (_, _) {});
      async.flushMicrotasks();
      expect(repo.researchFetches, 1);
      container.read(researchProvider('a').notifier).start();
      async.flushMicrotasks();

      // Gaps between polls: 2.5 s, 5 s, 10 s, 20 s, 20 s, 20 s, 20 s.
      const gaps = [2500, 5000, 10000, 20000, 20000, 20000, 20000];
      for (final (index, gap) in gaps.indexed) {
        async.elapse(Duration(milliseconds: gap - 100));
        expect(repo.researchFetches, index + 1, reason: 'early at poll $index');
        async.elapse(const Duration(milliseconds: 100));
        expect(repo.researchFetches, index + 2, reason: 'late at poll $index');
        final state = sub.read();
        expect(state.result.isRunning, isTrue);
        final failures = index + 1;
        if (index == gaps.length - 1) {
          expect(state.error, isNull);
        } else if (failures >= ResearchNotifier.failuresBeforeWarning) {
          expect(state.error, ResearchNotifier.pollingUnavailableMessage);
        } else {
          expect(state.error, isNull);
        }
      }
      expect(sub.read().result.stage, 'reading');

      // Interval is back to the base after the success.
      final fetches = repo.researchFetches;
      async.elapse(const Duration(milliseconds: 2600));
      expect(repo.researchFetches, fetches + 1);
      container.dispose();
    });
  });

  test('a poll in flight for the old user is dropped on uid change', () {
    fakeAsync((async) {
      final repo = _PendingRepository(
        details: {'a': ArticleDetail(card: fakeCard('a'))},
      );
      final container = _container(repo);
      final sub = container.listen(researchProvider('a'), (_, _) {});
      async.flushMicrotasks();
      repo.pending.removeLast().complete(const ResearchResult());
      async.flushMicrotasks();
      container.read(researchProvider('a').notifier).start();
      async.flushMicrotasks();
      async.elapse(const Duration(milliseconds: 2600));
      final inFlight = repo.pending.removeLast();

      container.read(_uidProvider.notifier).set('u2');
      async.flushMicrotasks();
      expect(sub.read().result.isNone, isTrue);
      final sync = repo.pending.removeLast();

      inFlight.complete(
        const ResearchResult(state: 'done', markdown: '# u1 only'),
      );
      async.flushMicrotasks();
      expect(sub.read().result.isNone, isTrue, reason: 'stale reply applied');

      sync.complete(const ResearchResult(state: 'running', stage: 'reading'));
      async.flushMicrotasks();
      expect(sub.read().result.stage, 'reading');
      container.dispose();
    });
  });

  test('a sync in flight is dropped on sign-out', () {
    fakeAsync((async) {
      final repo = _PendingRepository(
        details: {'a': ArticleDetail(card: fakeCard('a'))},
      );
      final container = _container(repo);
      final sub = container.listen(researchProvider('a'), (_, _) {});
      async.flushMicrotasks();
      final inFlight = repo.pending.removeLast();
      container.read(_uidProvider.notifier).set(null);
      async.flushMicrotasks();
      inFlight.complete(const ResearchResult(state: 'done'));
      async.flushMicrotasks();
      expect(sub.read().result.isNone, isTrue);
      expect(repo.pending, isEmpty);
      container.dispose();
    });
  });
}
