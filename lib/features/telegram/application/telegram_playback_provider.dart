import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mfb_think_tank/features/readers_digest/application/digest_api_providers.dart';

/// Only the explicitly selected Telegram attachment owns a player.
final telegramPlaybackProvider =
    NotifierProvider.autoDispose<TelegramPlaybackNotifier, String?>(
      TelegramPlaybackNotifier.new,
    );

class TelegramPlaybackNotifier extends Notifier<String?> {
  @override
  String? build() {
    ref.watch(currentUidProvider);
    return null;
  }

  void play(String path) => state = path;
}
