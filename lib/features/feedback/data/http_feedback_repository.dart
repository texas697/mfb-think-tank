import 'dart:convert';

import 'package:mfb_think_tank/core/config/app_info.dart';
import 'package:mfb_think_tank/core/network/api_client.dart';
import 'package:mfb_think_tank/features/feedback/data/feedback_failure.dart';
import 'package:mfb_think_tank/features/feedback/data/feedback_report.dart';
import 'package:mfb_think_tank/features/feedback/data/feedback_repository.dart';

/// [FeedbackRepository] over `POST /api/feedback`.
class HttpFeedbackRepository implements FeedbackRepository {
  HttpFeedbackRepository({required this.api, required this.appInfo});

  // Both are resolved per call: the API client needs a signed-in user and
  // the app info is loaded lazily on first use.
  final ApiClient Function() api;
  final Future<AppInfo> Function() appInfo;

  @override
  Future<void> submit(FeedbackReport report) async {
    final ApiResponse response;
    try {
      final app = await appInfo();
      response = await api().post(
        'api/feedback',
        body: report.toJson(platform: app.platform, appVersion: app.version),
      );
    } on ApiException catch (e) {
      throw switch (e.kind) {
        ApiFailureKind.timeout => const FeedbackTimeout(),
        ApiFailureKind.unauthorized => const FeedbackUnauthenticated(),
        _ => const FeedbackNetwork(),
      };
    } on StateError {
      throw const FeedbackUnauthenticated();
    }
    if (!response.isSuccess) throw _mapError(response);
  }

  FeedbackFailure _mapError(ApiResponse response) {
    final message = _errorMessage(response.body);
    return switch (response.statusCode) {
      401 => const FeedbackUnauthenticated(),
      429 => FeedbackRateLimited(
        message ?? const FeedbackRateLimited().message,
      ),
      400 || 413 => FeedbackRejected(message ?? 'Feedback was rejected.'),
      _ => FeedbackUnknown(message ?? const FeedbackUnknown().message),
    };
  }

  String? _errorMessage(String body) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic>) {
        final error = decoded['error'];
        if (error is String && error.isNotEmpty) return error;
      }
    } on FormatException {
      // Non-JSON error body; ignore.
    }
    return null;
  }
}
