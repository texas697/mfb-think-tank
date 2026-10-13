import 'package:mfb_think_tank/features/digest_settings/data/ai_settings.dart';
import 'package:mfb_think_tank/features/digest_settings/data/me_profile.dart';

/// Settings API contract. Implementations throw `DigestSettingsFailure` only.
abstract interface class DigestSettingsRepository {
  Future<MeProfile> fetchMe();

  /// Saves or updates the single active AI configuration and returns the
  /// server's public view of it.
  Future<AiSettings> saveLlm(AiSettingsInput input);

  /// Removes the stored AI configuration.
  Future<void> removeLlm();

  /// Round-trips a tiny completion to prove the saved key works.
  Future<void> testLlm();
}
