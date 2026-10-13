import 'package:flutter/foundation.dart';
import 'package:mfb_think_tank/features/digest_settings/data/ai_provider_meta.dart';
import 'package:mfb_think_tank/features/digest_settings/data/ai_settings.dart';

/// `GET /api/me` profile: identity, saved AI config, provider catalog.
@immutable
class MeProfile {
  const MeProfile({
    required this.uid,
    required this.email,
    this.llm,
    this.providers = const [],
    this.byokEnabled = false,
  });

  factory MeProfile.fromJson(Map<String, dynamic> json) => MeProfile(
    uid: json['uid'] as String? ?? '',
    email: json['email'] as String? ?? '',
    llm: json['llm'] is Map<String, dynamic>
        ? AiSettings.fromJson(json['llm'] as Map<String, dynamic>)
        : null,
    providers: json['providers'] is List
        ? (json['providers'] as List)
              .whereType<Map<String, dynamic>>()
              .map(AiProviderMeta.fromJson)
              .toList()
        : const [],
    byokEnabled: json['byokEnabled'] as bool? ?? false,
  );

  final String uid;
  final String email;
  final AiSettings? llm;
  final List<AiProviderMeta> providers;
  final bool byokEnabled;

  bool get hasLlm => llm?.hasKey ?? false;

  /// Copy with a replaced or removed AI configuration.
  MeProfile withLlm(AiSettings? value) => MeProfile(
    uid: uid,
    email: email,
    llm: value,
    providers: providers,
    byokEnabled: byokEnabled,
  );
}
