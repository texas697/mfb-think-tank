import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mfb_think_tank/app/app.dart';
import 'package:mfb_think_tank/app/router.dart';
import 'package:mfb_think_tank/features/auth/application/auth_providers.dart';
import 'package:mfb_think_tank/features/readers_digest/application/digest_api_providers.dart';
import 'package:mfb_think_tank/features/readers_digest/data/digest_failure.dart';
import 'package:mfb_think_tank/features/readers_digest/presentation/article_screen.dart';
import 'package:mfb_think_tank/features/readers_digest/presentation/widgets/digest_filter_bar.dart';

import '../../../helpers/fake_digest_repository.dart';

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
          firebaseAuthProvider.overrideWithValue(
            MockFirebaseAuth(
              signedIn: true,
              mockUser: MockUser(uid: 'u1', email: 'ann@example.com'),
            ),
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

  testWidgets('shows a retryable error', (tester) async {
    repo.feedError = const DigestNetwork();
    await pumpApp(tester);
    expect(find.text('Could not load the library'), findsOneWidget);
    repo.feedError = null;
    await tester.tap(find.byKey(const Key('feed-message-action')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('article-a')), findsOneWidget);
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
