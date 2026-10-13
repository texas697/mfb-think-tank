import 'dart:convert';

import 'package:mfb_think_tank/core/network/api_client.dart';
import 'package:mfb_think_tank/features/readers_digest/data/digest_failure.dart';

/// Maps a non-success Crucix API response to a [DigestFailure].
DigestFailure mapDigestError(ApiResponse response) {
  final message = _errorMessage(response.body);
  return switch (response.statusCode) {
    401 => const DigestUnauthenticated(),
    403 => const DigestForbidden(),
    404 => const DigestNotFound(),
    422 => DigestInsufficientText(
      message ?? const DigestInsufficientText().message,
    ),
    429 => const DigestTooManyRequests(),
    400 => _mapBadRequest(message),
    503 => const DigestUnavailable(),
    _ => DigestUnknown(message ?? const DigestUnknown().message),
  };
}

DigestFailure _mapBadRequest(String? message) {
  final lower = message?.toLowerCase() ?? '';
  if (lower.contains('no llm') || lower.contains('api key')) {
    return DigestMissingAiSettings(message!);
  }
  if (lower.contains('enough') && lower.contains('article')) {
    return DigestInsufficientText(message!);
  }
  return DigestInvalidAiSettings(
    message ?? const DigestInvalidAiSettings('Invalid request').message,
  );
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
