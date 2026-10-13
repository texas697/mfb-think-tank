import 'package:mfb_think_tank/features/feedback/data/feedback_report.dart';

/// Sends feedback and error reports to the server.
///
/// Throws only `FeedbackFailure`.
abstract class FeedbackRepository {
  Future<void> submit(FeedbackReport report);
}
