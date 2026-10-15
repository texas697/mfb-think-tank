import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mfb_think_tank/app/app.dart';
import 'package:mfb_think_tank/app/router.dart';
import 'package:mfb_think_tank/features/auth/application/auth_providers.dart';
import 'package:mfb_think_tank/features/readers_digest/application/digest_api_providers.dart';
import 'package:mfb_think_tank/features/readers_digest/data/digest_failure.dart';
import 'package:mfb_think_tank/features/readers_digest/data/digest_feed.dart';
import 'package:mfb_think_tank/features/readers_digest/data/digest_query.dart';
import 'package:mfb_think_tank/features/readers_digest/presentation/article_screen.dart';
import 'package:mfb_think_tank/features/readers_digest/presentation/widgets/digest_filter_bar.dart';

import '../../../helpers/fake_digest_repository.dart';
import '../../../helpers/mocks.dart';

/// Fake whose feed fetches after the first wait on [gate] before resolving.
class GatedDigestRepository extends FakeDigestRepository {
  GatedDigestRepository({super.items});

  Completer<void>? gate;

  @override
  Future<DigestFeed> fetchFeed(DigestQuery query) async {
    final pending = gate;
    if (pending != null) await pending.future;
    return super.fetchFeed(query);
  }
}

void main() {
  late FakeDigestRepository repo;

  Future<ProviderContainer> pumpApp(
    WidgetTester tester, {
    double width = 1080,
    double textScale = 1,
  }) async {
    tester.view.physicalSize = Size(width, 2400);
    tester.view.devicePixelRatio = 3;
    tester.platformDispatcher.textScaleFactorTestValue = textScale;
    addTearDown(tester.view.reset);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authStateChangesProvider.overrideWith(
            (ref) => Stream.value(fakeAppUser()),
          ),
          currentUserProvider.overrideWith(
            (ref) => Stream.value(fakeAppUser()),
          ),
          digestRepositoryProvider.overrideWithValue(repo),
        ],
        child: const App(),
      ),
    );
    await tester.pumpAndSettle();
    final container = ProviderScope.containerOf(
      tester.element(find.byType(App)),
    );
    container.read(routerProvider).go(AppRoutes.home);
    await tester.pumpAndSettle();
    return container;
  }

  String location(ProviderContainer c) =>
      c.read(routerProvider).routerDelegate.currentConfiguration.uri.toString();

  setUp(() {
    repo = FakeDigestRepository(
      items: [
        fakeCard('a'),
        fakeCard('b', kind: 'thinktank', topics: const ['energy']),
      ],
    );
  });

  testWidgets('shows the featured card and the library', (tester) async {
    await pumpApp(tester);
    expect(find.text('LATEST'), findsOneWidget);
    expect(find.byKey(const Key('article-a')), findsOneWidget);
    expect(find.byKey(const Key('article-b')), findsOneWidget);
    expect(find.textContaining('2 in library'), findsOneWidget);
  });

  testWidgets('filter chips route to the server filter', (tester) async {
    final container = await pumpApp(tester);
    await tester.scrollUntilVisible(
      find.byKey(const Key('filter-news')),
      100,
      scrollable: find.descendant(
        of: find.byType(DigestFilterBar),
        matching: find.byType(Scrollable),
      ),
    );
    await tester.tap(find.byKey(const Key('filter-news')));
    await tester.pumpAndSettle();
    expect(location(container), '/?filter=news');
    expect(find.byKey(const Key('article-b')), findsNothing);
    expect(repo.queries.last.filter, 'news');
  });

  testWidgets('an invalid filter in the URL falls back to all', (tester) async {
    final container = await pumpApp(tester);
    container.read(routerProvider).go('/?filter=bogus');
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('article-b')), findsOneWidget);
  });

  testWidgets('no matches offers to clear filters', (tester) async {
    final container = await pumpApp(tester);
    container.read(routerProvider).go('/?topic=missing');
    await tester.pumpAndSettle();
    expect(find.text('No matches'), findsOneWidget);
    await tester.tap(find.byKey(const Key('feed-message-action')));
    await tester.pumpAndSettle();
    expect(location(container), '/');
    expect(find.byKey(const Key('article-a')), findsOneWidget);
  });

  testWidgets('search is debounced and replaces the route', (tester) async {
    final container = await pumpApp(tester);
    await tester.enterText(find.byKey(const Key('digest-search')), 'Title b');
    await tester.pump(const Duration(milliseconds: 100));
    expect(repo.queries.last.q, '');
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpAndSettle();
    expect(repo.queries.last.q, 'Title b');
    expect(location(container), '/?q=Title+b');
    expect(find.byKey(const Key('article-a')), findsNothing);
  });

  testWidgets('a new search shows a reloading bar over the stale list', (
    tester,
  ) async {
    final gated = GatedDigestRepository(items: [fakeCard('a')]);
    repo = gated;
    await pumpApp(tester);
    expect(find.byKey(const Key('feed-reloading')), findsNothing);
    gated.gate = Completer<void>();
    await tester.enterText(find.byKey(const Key('digest-search')), 'Title');
    // Debounce fires, the route is replaced, the query provider syncs on the
    // next event-loop turn, and the feed provider then enters loading.
    for (var i = 0; i < 4; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(find.byKey(const Key('feed-reloading')), findsOneWidget);
    expect(find.byKey(const Key('article-a')), findsOneWidget);
    gated.gate!.complete();
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('feed-reloading')), findsNothing);
  });

  testWidgets('shows a retryable error', (tester) async {
    repo.feedError = const DigestNetwork();
    await pumpApp(tester);
    expect(find.text('Could not load the library'), findsOneWidget);
    repo.feedError = null;
    await tester.tap(find.byKey(const Key('feed-message-action')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('article-a')), findsOneWidget);
  });

  testWidgets('a failing retry does not throw out of the UI', (tester) async {
    repo.feedError = const DigestNetwork();
    await pumpApp(tester);
    final attempts = repo.queries.length;
    await tester.tap(find.byKey(const Key('feed-message-action')));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('Could not load the library'), findsOneWidget);
    expect(repo.queries.length, greaterThan(attempts));
  });

  testWidgets('a failing pull-to-refresh keeps the list and does not throw', (
    tester,
  ) async {
    await pumpApp(tester);
    repo.feedError = const DigestNetwork();
    await tester.fling(
      find.byType(CustomScrollView),
      const Offset(0, 400),
      1000,
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('Could not refresh'), findsOneWidget);
    expect(find.byKey(const Key('article-a')), findsOneWidget);
  });

  testWidgets('a debounced search does not replace a pushed reader', (
    tester,
  ) async {
    final container = await pumpApp(tester);
    await tester.enterText(find.byKey(const Key('digest-search')), 'Title');
    await tester.tap(find.byKey(const Key('article-a')));
    // pumpAndSettle lets the 250 ms debounce fire with the reader on top.
    await tester.pumpAndSettle();
    expect(find.byType(ArticleScreen), findsOneWidget);
    expect(repo.queries.any((query) => query.q == 'Title'), isFalse);
    container.read(routerProvider).pop();
    await tester.pumpAndSettle();
    expect(find.byType(ArticleScreen), findsNothing);
    expect(location(container), '/');
  });

  testWidgets('rating a card saves and shows the server rating', (
    tester,
  ) async {
    await pumpApp(tester);
    await tester.tap(find.byKey(const Key('rate-up-a')));
    await tester.pumpAndSettle();
    expect(repo.ratings, [('a', 1)]);
    expect(find.byIcon(Icons.thumb_up), findsOneWidget);
    await tester.tap(find.byKey(const Key('rate-up-a')));
    await tester.pumpAndSettle();
    expect(repo.ratings.last, ('a', 0));
  });

  testWidgets('opening an article keeps the library underneath', (
    tester,
  ) async {
    final container = await pumpApp(tester);
    container.read(routerProvider).go('/?filter=news');
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('article-a')));
    await tester.pumpAndSettle();
    expect(find.byType(ArticleScreen), findsOneWidget);
    container.read(routerProvider).pop();
    await tester.pumpAndSettle();
    expect(location(container), '/?filter=news');
  });

  for (final (width, scale) in [(960.0, 1.0), (1290.0, 1.0), (1080.0, 2.0)]) {
    testWidgets('lays out at width $width and text scale $scale', (
      tester,
    ) async {
      await pumpApp(tester, width: width, textScale: scale);
      await tester.scrollUntilVisible(
        find.byKey(const Key('article-a')),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      expect(tester.takeException(), isNull);
    });
  }
}
