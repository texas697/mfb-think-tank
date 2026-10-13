import 'dart:convert';

import 'package:mfb_think_tank/core/network/api_client.dart';
import 'package:mfb_think_tank/features/digest_settings/data/ai_settings.dart';
import 'package:mfb_think_tank/features/digest_settings/data/digest_settings_failure.dart';
import 'package:mfb_think_tank/features/digest_settings/data/digest_settings_repository.dart';
import 'package:mfb_think_tank/features/digest_settings/data/me_profile.dart';

/// [DigestSettingsRepository] over the Crucix HTTP API.
class HttpDigestSettingsRepository implements DigestSettingsRepository {
  HttpDigestSettingsRepository({required this._api});

  final ApiClient _api;

  @override
  Future<MeProfile> fetchMe() async {
    final json = await _decode(await _call(() => _api.get('api/me')));
    return _parse(json, MeProfile.fromJson);
  }

  @override
  Future<AiSettings> saveLlm(AiSettingsInput input) async {
    final response = await _call(
      () => _api.put('api/me/llm', body: input.toJson()),
    );
    final json = await _decode(response);
    final llm = json['llm'];
    if (llm is! Map<String, dynamic>) throw const SettingsMalformed();
    return _parse(llm, AiSettings.fromJson);
  }

  @override
  Future<void> removeLlm() async {
    await _decode(await _call(() => _api.delete('api/me/llm')));
  }

  // The server waits up to 20 s on the provider before answering 502 with a
  // diagnostic; the client must outlast that so the message arrives.
  static const _testLlmTimeout = Duration(seconds: 30);

  @override
  Future<void> testLlm() async {
    final response = await _call(
      () => _api.post(
        'api/me/llm/test',
        body: const {},
        timeout: _testLlmTimeout,
      ),
    );
    if (!response.isSuccess) throw _mapError(response);
  }

  /// Maps transport failures and a missing session to feature failures.
  Future<ApiResponse> _call(Future<ApiResponse> Function() request) async {
    try {
      return await request();
    } on ApiException catch (e) {
      throw switch (e.kind) {
        ApiFailureKind.timeout => const SettingsTimeout(),
        ApiFailureKind.unauthorized => const SettingsUnauthenticated(),
        _ => const SettingsNetwork(),
      };
    } on StateError {
      throw const SettingsUnauthenticated();
    }
  }

  Future<Map<String, dynamic>> _decode(ApiResponse response) async {
    if (!response.isSuccess) throw _mapError(response);
    try {
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic>) return decoded;
      throw const FormatException('expected object');
    } on FormatException {
      throw const SettingsMalformed();
    }
  }

  T _parse<T>(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic>) fromJson,
  ) {
    try {
      return fromJson(json);
    } catch (_) {
      throw const SettingsMalformed();
    }
  }

  DigestSettingsFailure _mapError(ApiResponse response) {
    final message = _errorMessage(response.body);
    return switch (response.statusCode) {
      401 => const SettingsUnauthenticated(),
      403 => const SettingsForbidden(),
      503 => const SettingsUnavailable(),
      400 || 502 => SettingsRejected(
        message ?? const SettingsRejected('Request rejected').message,
      ),
      _ => SettingsUnknown(message ?? const SettingsUnknown().message),
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
