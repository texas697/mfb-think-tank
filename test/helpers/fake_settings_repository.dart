import 'dart:async';

import 'package:mfb_think_tank/features/digest_settings/data/ai_provider_meta.dart';
import 'package:mfb_think_tank/features/digest_settings/data/ai_settings.dart';
import 'package:mfb_think_tank/features/digest_settings/data/digest_settings_failure.dart';
import 'package:mfb_think_tank/features/digest_settings/data/digest_settings_repository.dart';
import 'package:mfb_think_tank/features/digest_settings/data/me_profile.dart';

const fakeProviders = [
  AiProviderMeta(id: 'anthropic', label: 'Anthropic', defaultModel: 'claude'),
  AiProviderMeta(id: 'openai', label: 'OpenAI', defaultModel: 'gpt'),
  AiProviderMeta(id: 'gemini', label: 'Gemini', defaultModel: 'gem'),
  AiProviderMeta(
    id: 'openai-compatible',
    label: 'Custom',
    isKeyRequired: false,
    isBaseUrlRequired: true,
  ),
];

/// In-memory [DigestSettingsRepository] that records saved inputs.
class FakeSettingsRepository implements DigestSettingsRepository {
  FakeSettingsRepository({
    this.llm,
    this.isByokEnabled = true,
    this.fetchError,
  });

  AiSettings? llm;
  final bool isByokEnabled;

  /// Thrown by [fetchMe] while set; clear it before a retry.
  DigestSettingsFailure? fetchError;
  DigestSettingsFailure? saveError;

  /// While set, save/test/remove wait on it so tests can observe the
  /// in-progress state.
  Completer<void>? gate;

  final saved = <AiSettingsInput>[];
  var removed = 0;
  var tests = 0;

  @override
  Future<MeProfile> fetchMe() async {
    final error = fetchError;
    if (error != null) throw error;
    return MeProfile(
      uid: 'u1',
      email: 'ann@example.com',
      llm: llm,
      providers: fakeProviders,
      isByokEnabled: isByokEnabled,
    );
  }

  @override
  Future<AiSettings> saveLlm(AiSettingsInput input) async {
    await _wait();
    final error = saveError;
    if (error != null) throw error;
    saved.add(input);
    return llm = AiSettings(
      provider: input.provider,
      model: input.model,
      baseUrl: input.baseUrl,
      hasKey: true,
      keyHint: '…1234',
    );
  }

  @override
  Future<void> removeLlm() async {
    await _wait();
    removed++;
    llm = null;
  }

  @override
  Future<void> testLlm() async {
    await _wait();
    tests++;
  }

  Future<void> _wait() async {
    final gate = this.gate;
    if (gate != null) await gate.future;
  }
}
