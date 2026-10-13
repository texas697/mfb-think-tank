import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mfb_think_tank/features/digest_settings/application/digest_settings_providers.dart';
import 'package:mfb_think_tank/features/digest_settings/application/me_profile_provider.dart';
import 'package:mfb_think_tank/features/digest_settings/data/ai_settings.dart';
import 'package:mfb_think_tank/features/digest_settings/data/digest_settings_failure.dart';

/// Status of the account sheet's save/test/remove actions.
@immutable
class SettingsActionState {
  const SettingsActionState({this.isBusy = false, this.notice});

  final bool isBusy;

  /// Success or error message to surface once.
  final String? notice;

  SettingsActionState copyWith({bool? isBusy, String? notice}) =>
      SettingsActionState(isBusy: isBusy ?? this.isBusy, notice: notice);
}

/// Runs account-sheet actions serially. Raw keys are passed straight to the
/// repository and never stored in this state.
final settingsActionProvider =
    NotifierProvider<SettingsActionNotifier, SettingsActionState>(
      SettingsActionNotifier.new,
    );

class SettingsActionNotifier extends Notifier<SettingsActionState> {
  @override
  SettingsActionState build() => const SettingsActionState();

  /// Saves/updates the AI configuration and refreshes the profile.
  Future<bool> save(AiSettingsInput input) => _run(() async {
    final saved = await ref
        .read(digestSettingsRepositoryProvider)
        .saveLlm(input);
    ref.read(meProfileProvider.notifier).applyLlm(saved);
  }, success: 'Key saved.');

  /// Removes the stored configuration.
  Future<bool> remove() => _run(() async {
    await ref.read(digestSettingsRepositoryProvider).removeLlm();
    ref.read(meProfileProvider.notifier).applyLlm(null);
  }, success: 'Key removed.');

  /// Round-trips a tiny completion to verify the saved key.
  Future<bool> test() => _run(
    () => ref.read(digestSettingsRepositoryProvider).testLlm(),
    success: 'Key verified.',
  );

  void clearNotice() {
    if (state.notice == null) return;
    state = state.copyWith();
  }

  Future<bool> _run(
    Future<void> Function() action, {
    required String success,
  }) async {
    if (state.isBusy) return false;
    state = const SettingsActionState(isBusy: true);
    try {
      await action();
      state = SettingsActionState(notice: success);
      return true;
    } catch (error) {
      state = SettingsActionState(notice: _message(error));
      return false;
    }
  }

  String _message(Object error) => error is DigestSettingsFailure
      ? error.message
      : 'Something went wrong. Try again.';
}
