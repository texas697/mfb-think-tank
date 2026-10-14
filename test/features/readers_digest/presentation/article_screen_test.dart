import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mfb_think_tank/features/auth/application/auth_providers.dart';
import 'package:mfb_think_tank/features/digest_settings/application/digest_settings_providers.dart';
import 'package:mfb_think_tank/features/readers_digest/application/digest_api_providers.dart';
import 'package:mfb_think_tank/features/readers_digest/application/external_link_provider.dart';
import 'package:mfb_think_tank/features/readers_digest/data/article_detail.dart';
import 'package:mfb_think_tank/features/readers_digest/data/digest_failure.dart';
import 'package:mfb_think_tank/features/readers_digest/data/research_result.dart';
import 'package:mfb_think_tank/features/readers_digest/presentation/article_screen.dart';

import '../../../helpers/fake_digest_repository.dart';
import '../../../helpers/fake_settings_repository.dart';
import '../../../helpers/mocks.dart';

void main() {
  late FakeDigestRepository repo;
  late List<Uri> opened;

  ArticleDetail plain() => ArticleDetail(
    card: fakeCard('a'),
    textPreview: 'The real excerpt.',
    isExtracted: true,
  );

  Future<void> pump(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authStateChangesProvider.overrideWith(
            (ref) => Stream.value(fakeAppUser()),
          ),
          digestRepositoryProvider.overrideWithValue(repo),
          digestSettingsRepositoryProvider.overrideWithValue(
            FakeSettingsRepository(),
          ),
          externalLinkProvider.overrideWithValue((uri) async {
            opened.add(uri);
            return uri.host != 'blocked.example';
          }),
        ],
        child: const MaterialApp(home: ArticleScreen(id: 'a')),
      ),
    );
    await tester.pumpAndSettle();
  }

  setUp(() {
    opened = [];
    repo = FakeDigestRepository(details: {'a': plain()});
  });

  testWidgets('shows the real excerpt and generates a write-up', (
    tester,
  ) async {
    repo.summarizeResult = ArticleDetail(
      card: fakeCard('a', hasWriteup: true),
      summaryMd: '## Key points\n\nA summary.',
      summaryModel: 'anthropic/claude',
      isExtracted: true,
    );
    await pump(tester);
    expect(find.text('The real excerpt.'), findsOneWidget);
    await tester.tap(find.byKey(const Key('writeup-generate')));
    await tester.pumpAndSettle();
    expect(repo.summarizeCalls, 1);
    expect(find.text('Written by anthropic/claude'), findsOneWidget);
    expect(find.textContaining('A summary.'), findsOneWidget);
    expect(find.byKey(const Key('writeup-generate')), findsNothing);
  });

  testWidgets('a missing key keeps the excerpt and points to settings', (
    tester,
  ) async {
    repo.summarizeError = const DigestMissingAiSettings();
    await pump(tester);
    await tester.tap(find.byKey(const Key('writeup-generate')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('writeup-error')), findsOneWidget);
    expect(find.text('The real excerpt.'), findsOneWidget);
    await tester.tap(find.byKey(const Key('writeup-ai-settings')));
    await tester.pumpAndSettle();
    expect(find.text('AI write-ups'), findsWidgets);
  });

  testWidgets('research runs, finishes and lists cited sources', (
    tester,
  ) async {
    await pump(tester);
    await tester.scrollUntilVisible(
      find.byKey(const Key('research-start')),
      200,
    );
    repo.research = const ResearchResult(state: 'running', stage: 'reading');
    await tester.tap(find.byKey(const Key('research-start')));
    await tester.pump();
    expect(repo.researchStarts, 1);
    expect(find.byKey(const Key('research-progress')), findsOneWidget);

    repo.research = const ResearchResult(
      state: 'done',
      markdown: '## Findings\n\nCited.',
      sources: [
        ResearchSource(title: 'Source one', url: 'https://e.com/1'),
        ResearchSource(title: 'Blocked', url: 'https://blocked.example/x'),
      ],
    );
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();
    expect(find.text('Source one'), findsOneWidget);
    expect(find.text('Regenerate research'), findsOneWidget);

    await tester.tap(find.byKey(const Key('research-source-0')));
    expect(opened.single.toString(), 'https://e.com/1');
    await tester.tap(find.byKey(const Key('research-source-1')));
    await tester.pump();
    expect(find.text('Could not open link.'), findsOneWidget);
    expect(repo.researchStarts, 1);
  });

  testWidgets('an unknown article shows not found', (tester) async {
    repo.details.clear();
    await pump(tester);
    expect(find.text('Article not found'), findsOneWidget);
  });

  testWidgets('the original link only opens valid http(s) urls', (
    tester,
  ) async {
    await pump(tester);
    await tester.tap(find.byKey(const Key('reader-original')));
    await tester.pump();
    expect(opened.single.toString(), 'https://example.com/a');
    expect(parseHttpUrl('javascript:alert(1)'), isNull);
    expect(parseHttpUrl('ftp://example.com'), isNull);
    expect(parseHttpUrl('not a url'), isNull);
  });

  testWidgets('rating from the reader toolbar saves the vote', (tester) async {
    await pump(tester);
    await tester.tap(find.byKey(const Key('rate-down-a')));
    await tester.pumpAndSettle();
    expect(repo.ratings, [('a', -1)]);
    expect(find.byIcon(Icons.thumb_down), findsOneWidget);
  });
}
