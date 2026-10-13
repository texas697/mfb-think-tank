import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mfb_think_tank/features/auth/application/api_client_providers.dart';
import 'package:mfb_think_tank/features/digest_settings/data/digest_settings_repository.dart';
import 'package:mfb_think_tank/features/digest_settings/data/http_digest_settings_repository.dart';

/// AI settings API contract over HTTP.
final digestSettingsRepositoryProvider = Provider<DigestSettingsRepository>(
  (ref) => HttpDigestSettingsRepository(api: ref.watch(apiClientProvider)),
);
