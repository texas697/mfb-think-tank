import 'package:mfb_think_tank/features/feedback/data/feedback_report.dart';
import 'package:mfb_think_tank/features/feedback/data/feedback_repository.dart';

/// Sends uncaught errors to the feedback endpoint so they land in the same
/// triage list as user reports. Pure Dart; no Flutter types.
///
/// The same error is reported once per process, and at most
/// [maxPerSession] distinct errors are sent, so a crash loop cannot eat the
/// server's per-user feedback quota. Reporting itself never throws.
class ErrorReporter {
  ErrorReporter({required this.repository, this.maxPerSession = 5});

  static const _maxDescription = 500;
  static const _maxStack = 4000;

  /// Resolved per report so a signed-in API client is picked up lazily.
  final FeedbackRepository Function() repository;
  final int maxPerSession;

  final _seen = <String>{};
  var _sent = 0;

  /// Distinct errors sent so far.
  int get sentCount => _sent;

  /// Reports [error] unless it was already seen or the session cap is hit.
  /// [context] names where it was caught (`flutter`, `dart`, a library).
  Future<void> report(
    Object error,
    StackTrace? stack, {
    String context = 'dart',
    String? page,
  }) async {
    if (_sent >= maxPerSession || !_seen.add(_signature(error, stack))) {
      return;
    }
    _sent++;
    final message = error.toString();
    final report = FeedbackReport(
      category: FeedbackCategory.error,
      description: _clip('[$context] $message', _maxDescription),
      page: page,
      state: {
        'type': error.runtimeType.toString(),
        'message': _clip(message, _maxDescription * 4),
        'context': context,
        if (stack != null) 'stack': _clip(stack.toString(), _maxStack),
      },
    );
    try {
      await repository().submit(report);
    } catch (_) {
      // Nobody signed in, offline, or the server refused: drop it.
    }
  }

  static String _signature(Object error, StackTrace? stack) {
    final firstFrame = stack
        ?.toString()
        .split('\n')
        .firstWhere((l) => l.trim().isNotEmpty, orElse: () => '');
    return '${error.runtimeType}|${_clip(error.toString(), 200)}|$firstFrame';
  }

  static String _clip(String text, int max) =>
      text.length <= max ? text : '${text.substring(0, max)}…';
}
