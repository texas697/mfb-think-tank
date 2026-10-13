import 'dart:async';

import 'package:mfb_think_tank/features/feedback/data/feedback_failure.dart';
import 'package:mfb_think_tank/features/feedback/data/feedback_report.dart';
import 'package:mfb_think_tank/features/feedback/data/feedback_repository.dart';

/// In-memory [FeedbackRepository] that records submitted reports.
class FakeFeedbackRepository implements FeedbackRepository {
  FakeFeedbackRepository({this.error});

  /// Thrown by [submit] while set.
  FeedbackFailure? error;

  /// While set, [submit] waits on it so tests can observe the busy state.
  Completer<void>? gate;

  final submitted = <FeedbackReport>[];

  @override
  Future<void> submit(FeedbackReport report) async {
    final gate = this.gate;
    if (gate != null) await gate.future;
    final error = this.error;
    if (error != null) throw error;
    submitted.add(report);
  }
}
