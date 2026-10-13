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
    this.isByokEnabled = false,
    this.sharedLlmModel,
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
    isByokEnabled: json['byokEnabled'] as bool? ?? false,
    sharedLlmModel: json['sharedLlm'] is Map<String, dynamic>
        ? (json['sharedLlm'] as Map<String, dynamic>)['model'] as String?
        : null,
  );

  final String uid;
  final String email;
  final AiSettings? llm;
  final List<AiProviderMeta> providers;
  final bool isByokEnabled;

  /// Model the server uses on the operator's key when the user has none.
  /// Null when every write-up needs the user's own key.
  final String? sharedLlmModel;

  /// True when write-ups work without the user saving a key.
  bool get hasSharedLlm => sharedLlmModel != null;

  /// True when the server holds a configuration. A provider that needs no
  /// key (`openai-compatible`) is saved with `hasKey == false`, so this does
  /// not depend on [AiSettings.hasKey].
  bool get hasLlm => llm != null;

  /// Copy with a replaced or removed AI configuration.
  MeProfile withLlm(AiSettings? value) => MeProfile(
    uid: uid,
    email: email,
    llm: value,
    providers: providers,
    isByokEnabled: isByokEnabled,
    sharedLlmModel: sharedLlmModel,
  );
}
