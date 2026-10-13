import 'package:flutter_test/flutter_test.dart';
import 'package:mfb_think_tank/features/readers_digest/data/research_result.dart';

void main() {
  test('decodes the none shape and the raw stored document', () {
    expect(ResearchResult.fromJson({'state': 'none'}).isNone, isTrue);
    final done = ResearchResult.fromJson({
      'state': 'done',
      'markdown': '## Findings',
      'model': 'm',
      'completedAt': '2026-01-01T00:00:00Z',
      'sources': [
        {'title': 'S', 'url': 'https://e.com', 'extra': 1},
        7,
      ],
      'unknown': true,
    });
    expect(done.isDone, isTrue);
    expect(done.sources.single.url, 'https://e.com');
    expect(done.completedAt, isNotNull);
  });

  test('running research may have no sources yet', () {
    final running = ResearchResult.fromJson({
      'state': 'running',
      'stage': 'searching',
      'progress': 10,
    });
    expect(running.isRunning, isTrue);
    expect(running.sources, isEmpty);
  });

  test('decodes updatedAt from the stored document', () {
    final result = ResearchResult.fromJson({
      'state': 'running',
      'updatedAt': '2026-01-01T12:00:00Z',
    });
    expect(result.updatedAt, DateTime.utc(2026, 1, 1, 12).toLocal());
    expect(ResearchResult.fromJson({'state': 'running'}).updatedAt, isNull);
    expect(
      ResearchResult.fromJson({'state': 'running', 'updatedAt': ''}).updatedAt,
      isNull,
    );
  });

  group('isStale', () {
    final now = DateTime.utc(2026, 1, 1, 12);
    final old = now.subtract(const Duration(minutes: 5, seconds: 1));
    final fresh = now.subtract(const Duration(minutes: 4, seconds: 59));

    test('is true only for a running run not updated for five minutes', () {
      expect(
        ResearchResult(state: 'running', updatedAt: old).isStaleAt(now),
        isTrue,
      );
      expect(
        ResearchResult(state: 'running', updatedAt: fresh).isStaleAt(now),
        isFalse,
      );
    });

    test('is false without updatedAt or when not running', () {
      expect(const ResearchResult(state: 'running').isStaleAt(now), isFalse);
      for (final state in ['none', 'done', 'error']) {
        expect(
          ResearchResult(state: state, updatedAt: old).isStaleAt(now),
          isFalse,
        );
      }
    });

    test('isStale uses the current clock', () {
      final longAgo = DateTime.now().subtract(const Duration(hours: 1));
      expect(
        ResearchResult(state: 'running', updatedAt: longAgo).isStale,
        true,
      );
      expect(
        ResearchResult(state: 'running', updatedAt: DateTime.now()).isStale,
        isFalse,
      );
    });
  });
}
