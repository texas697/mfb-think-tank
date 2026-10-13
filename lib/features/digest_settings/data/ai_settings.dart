import 'package:flutter/foundation.dart';

/// The user's saved AI configuration, as exposed by the server.
///
/// The server stores one active configuration; switching providers requires
/// an appropriate replacement key. Raw keys never appear here.
@immutable
class AiSettings {
  const AiSettings({
    required this.provider,
    this.model,
    this.baseUrl,
    this.hasKey = false,
    this.keyHint,
    this.updatedAt,
  });

  factory AiSettings.fromJson(Map<String, dynamic> json) => AiSettings(
    provider: json['provider'] as String? ?? '',
    model: json['model'] as String?,
    baseUrl: json['baseUrl'] as String?,
    hasKey: json['hasKey'] as bool? ?? false,
    keyHint: json['keyHint'] as String?,
    updatedAt: _date(json['updatedAt']),
  );

  final String provider;
  final String? model;
  final String? baseUrl;
  final bool hasKey;
  final String? keyHint;
  final DateTime? updatedAt;

  static DateTime? _date(Object? value) {
    if (value is! String || value.isEmpty) return null;
    return DateTime.tryParse(value)?.toLocal();
  }
}

/// Input for `PUT /api/me/llm`.
///
/// [apiKey] semantics: null omits the field (keep the stored key for a
/// same-provider update), a non-empty string replaces it, and `''` removes it.
@immutable
class AiSettingsInput {
  const AiSettingsInput({
    required this.provider,
    this.model,
    this.baseUrl,
    this.apiKey,
  });

  final String provider;
  final String? model;
  final String? baseUrl;
  final String? apiKey;

  /// JSON body. Always resend [baseUrl] so `openai-compatible` keeps working;
  /// omit [apiKey] when it is null.
  Map<String, Object?> toJson() => {
    'provider': provider,
    if (model != null && model!.isNotEmpty) 'model': model,
    if (baseUrl != null && baseUrl!.isNotEmpty) 'baseUrl': baseUrl,
    if (apiKey != null) 'apiKey': apiKey,
  };
}
