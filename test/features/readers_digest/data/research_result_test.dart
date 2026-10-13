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
}
