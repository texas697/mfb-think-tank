import 'package:mfb_think_tank/core/network/api_failure_kind.dart';

export 'api_failure_kind.dart';

/// Transport-level failure. Feature repositories map this to their own
/// failure types; UI never sees it.
class ApiException implements Exception {
  const ApiException(this.kind, {this.statusCode, this.body});

  final ApiFailureKind kind;
  final int? statusCode;
  final String? body;

  @override
  String toString() => 'ApiException(${kind.name}, $statusCode)';
}
