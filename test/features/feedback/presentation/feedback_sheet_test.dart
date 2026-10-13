import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mfb_think_tank/features/feedback/application/feedback_providers.dart';
import 'package:mfb_think_tank/features/feedback/data/feedback_failure.dart';
import 'package:mfb_think_tank/features/feedback/data/feedback_report.dart';
import 'package:mfb_think_tank/features/feedback/presentation/feedback_sheet.dart';

import '../../../helpers/fake_feedback_repository.dart';

void main() {
  late FakeFeedbackRepository repo;

  /// Opens the sheet from a button so the pop and snackbar have a host.
  Future<void> pump(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [feedbackRepositoryProvider.overrideWithValue(repo)],
        child: MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                key: const Key('open'),
                onPressed: () => showModalBottomSheet<void>(
                  context: context,
                  isScrollControlled: true,
                  builder: (_) => const FeedbackSheet(page: '/article/1'),
                ),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.byKey(const Key('open')));
    await tester.pumpAndSettle();
  }

  testWidgets('requires a description, then sends and closes', (tester) async {
    repo = FakeFeedbackRepository();
    await pump(tester);

    await tester.tap(find.byKey(const Key('feedback-send')));
    await tester.pump();
    expect(find.text('Tell us a bit more.'), findsOneWidget);
    expect(repo.submitted, isEmpty);

    await tester.tap(find.byKey(const Key('feedback-category-idea')));
    await tester.enterText(
      find.byKey(const Key('feedback-description')),
      'Add a dark mode toggle',
    );
    await tester.tap(find.byKey(const Key('feedback-send')));
    await tester.pumpAndSettle();

    final report = repo.submitted.single;
    expect(report.category, FeedbackCategory.idea);
    expect(report.description, 'Add a dark mode toggle');
    expect(report.page, '/article/1');
    expect(find.byKey(const Key('feedback-send')), findsNothing);
    expect(find.text('Thanks, your feedback was sent.'), findsOneWidget);
  });

  testWidgets('shows the failure and stays open', (tester) async {
    repo = FakeFeedbackRepository(error: const FeedbackRateLimited());
    await pump(tester);
    await tester.enterText(
      find.byKey(const Key('feedback-description')),
      'Something broke',
    );
    await tester.tap(find.byKey(const Key('feedback-send')));
    await tester.pumpAndSettle();
    expect(find.text(const FeedbackRateLimited().message), findsOneWidget);
    expect(find.byKey(const Key('feedback-send')), findsOneWidget);
  });

  testWidgets('locks the form while sending', (tester) async {
    repo = FakeFeedbackRepository()..gate = Completer<void>();
    await pump(tester);
    await tester.enterText(
      find.byKey(const Key('feedback-description')),
      'Slow one',
    );
    await tester.tap(find.byKey(const Key('feedback-send')));
    await tester.pump();
    expect(find.text('Sending…'), findsOneWidget);
    expect(
      tester
          .widget<TextField>(find.byKey(const Key('feedback-description')))
          .enabled,
      isFalse,
    );
    repo.gate!.complete();
    await tester.pumpAndSettle();
    expect(repo.submitted, hasLength(1));
  });
}
