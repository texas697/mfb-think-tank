import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mfb_think_tank/core/config/app_info.dart';
import 'package:mfb_think_tank/features/auth/application/api_client_providers.dart';
import 'package:mfb_think_tank/features/feedback/application/error_reporter.dart';
import 'package:mfb_think_tank/features/feedback/data/feedback_repository.dart';
import 'package:mfb_think_tank/features/feedback/data/http_feedback_repository.dart';

/// Feedback API contract over HTTP. Override in tests.
final feedbackRepositoryProvider = Provider<FeedbackRepository>(
  (ref) => HttpFeedbackRepository(
    api: () => ref.read(apiClientProvider),
    appInfo: () => ref.read(appInfoProvider.future),
  ),
);

/// Process-wide reporter for uncaught errors. Reads the repository lazily
/// so it works before a user signs in (reports are then dropped).
final errorReporterProvider = Provider<ErrorReporter>(
  (ref) =>
      ErrorReporter(repository: () => ref.read(feedbackRepositoryProvider)),
);
