import 'package:flutter/foundation.dart';

/// Provider metadata from `GET /api/me` (`SUPPORTED_PROVIDERS`).
@immutable
class AiProviderMeta {
  const AiProviderMeta({
    required this.id,
    required this.label,
    this.isKeyRequired = true,
    this.isBaseUrlRequired = false,
    this.defaultModel = '',
  });

  factory AiProviderMeta.fromJson(Map<String, dynamic> json) => AiProviderMeta(
    id: json['id'] as String? ?? '',
    label: json['label'] as String? ?? '',
    isKeyRequired: json['needsKey'] as bool? ?? true,
    isBaseUrlRequired: json['needsBaseUrl'] as bool? ?? false,
    defaultModel: json['defaultModel'] as String? ?? '',
  );

  final String id;
  final String label;
  final bool isKeyRequired;

  /// True for `openai-compatible`, which requires a custom base URL.
  final bool isBaseUrlRequired;
  final String defaultModel;
}
