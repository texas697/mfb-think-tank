import 'package:flutter_test/flutter_test.dart';
import 'package:mfb_think_tank/features/feedback/application/error_reporter.dart';
import 'package:mfb_think_tank/features/feedback/data/feedback_failure.dart';
import 'package:mfb_think_tank/features/feedback/data/feedback_report.dart';

import '../../../helpers/fake_feedback_repository.dart';

void main() {
  late FakeFeedbackRepository repo;
  late ErrorReporter reporter;

  setUp(() {
    repo = FakeFeedbackRepository();
    reporter = ErrorReporter(repository: () => repo, maxPerSession: 2);
  });

  test('sends an error report with the stack and page', () async {
    await reporter.report(
      StateError('boom'),
      StackTrace.fromString('#0 main (file.dart:1)'),
      context: 'flutter',
      page: '/article/42',
    );

    final report = repo.submitted.single;
    expect(report.category, FeedbackCategory.error);
    expect(report.description, '[flutter] Bad state: boom');
    expect(report.page, '/article/42');
    expect(report.state?['type'], 'StateError');
    expect(report.state?['stack'], contains('file.dart:1'));
  });

  test('reports the same error once and respects the session cap', () async {
    final stack = StackTrace.fromString('#0 a (a.dart:1)');
    await reporter.report(StateError('same'), stack);
    await reporter.report(StateError('same'), stack);
    await reporter.report(StateError('other'), stack);
    await reporter.report(StateError('third'), stack);

    expect(repo.submitted.map((r) => r.description), [
      '[dart] Bad state: same',
      '[dart] Bad state: other',
    ]);
    expect(reporter.sentCount, 2);
  });

  test('never throws when the repository fails', () async {
    repo.error = const FeedbackNetwork();
    await expectLater(reporter.report(Exception('x'), null), completes);
    expect(repo.submitted, isEmpty);
  });

  test('clips long messages and stacks', () async {
    final long = 'x' * 10000;
    await reporter.report(Exception(long), StackTrace.fromString(long));
    final report = repo.submitted.single;
    expect(report.description.length, lessThanOrEqualTo(502));
    expect((report.state?['stack'] as String).length, lessThanOrEqualTo(4001));
  });
}
