import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mfb_think_tank/features/digest_settings/data/ai_settings.dart';
import 'package:mfb_think_tank/features/digest_settings/data/me_profile.dart';
import 'package:mfb_think_tank/features/readers_digest/application/digest_api_providers.dart';

/// The signed-in user's profile and AI settings from `/api/me`.
final meProfileProvider = AsyncNotifierProvider<MeProfileNotifier, MeProfile>(
  MeProfileNotifier.new,
);

class MeProfileNotifier extends AsyncNotifier<MeProfile> {
  @override
  Future<MeProfile> build() {
    // Discard cached profile when the signed-in user changes.
    final uid = ref.watch(currentUidProvider);
    if (uid == null) {
      throw StateError('No signed-in user');
    }
    return ref.read(digestSettingsRepositoryProvider).fetchMe();
  }

  /// Applies a server-confirmed settings save/remove.
  void applyLlm(AiSettings? value) {
    final current = state.value;
    if (current == null) return;
    state = AsyncData(current.withLlm(value));
  }
}
