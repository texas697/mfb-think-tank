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
    needsKey: false,
    needsBaseUrl: true,
  ),
];

/// In-memory [DigestSettingsRepository] that records saved inputs.
class FakeSettingsRepository implements DigestSettingsRepository {
  FakeSettingsRepository({this.llm, this.byokEnabled = true});

  AiSettings? llm;
  final bool byokEnabled;
  DigestSettingsFailure? saveError;
  final saved = <AiSettingsInput>[];
  var removed = 0;
  var tests = 0;

  @override
  Future<MeProfile> fetchMe() async => MeProfile(
    uid: 'u1',
    email: 'ann@example.com',
    llm: llm,
    providers: fakeProviders,
    byokEnabled: byokEnabled,
  );

  @override
  Future<AiSettings> saveLlm(AiSettingsInput input) async {
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
    removed++;
    llm = null;
  }

  @override
  Future<void> testLlm() async => tests++;
}
