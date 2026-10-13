import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mfb_think_tank/features/digest_settings/data/digest_settings_repository.dart';
import 'package:mfb_think_tank/features/digest_settings/data/http_digest_settings_repository.dart';
import 'package:mfb_think_tank/features/readers_digest/application/digest_api_providers.dart';

/// AI settings API contract over HTTP.
final digestSettingsRepositoryProvider = Provider<DigestSettingsRepository>(
  (ref) => HttpDigestSettingsRepository(api: ref.watch(apiClientProvider)),
);
