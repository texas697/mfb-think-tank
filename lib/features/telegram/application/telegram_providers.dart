import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mfb_think_tank/core/config/app_config.dart';
import 'package:mfb_think_tank/features/auth/application/api_client_providers.dart';
import 'package:mfb_think_tank/features/telegram/data/http_telegram_repository.dart';
import 'package:mfb_think_tank/features/telegram/data/telegram_dialog.dart';
import 'package:mfb_think_tank/features/telegram/data/telegram_failure.dart';
import 'package:mfb_think_tank/features/telegram/data/telegram_message.dart';
import 'package:mfb_think_tank/features/telegram/data/telegram_repository.dart';
import 'package:mfb_think_tank/features/telegram/data/telegram_status.dart';

/// Injectable read-only Telegram contract.
final telegramRepositoryProvider = Provider<TelegramRepository>(
  (ref) => HttpTelegramRepository(
    api: ref.watch(apiClientProvider),
    tokens: ref.watch(idTokenProvider),
    base: Uri.parse(ref.watch(appConfigProvider).crucixApiBaseUrl),
  ),
);

/// Each family key includes the account so previous AsyncValue data cannot cross users.
final telegramStatusProvider = FutureProvider.autoDispose
    .family<TelegramStatus, String?>((ref, uid) {
      _requireUser(uid);
      return ref.watch(telegramRepositoryProvider).fetchStatus();
    }, retry: (_, _) => null);

final telegramDialogsProvider = FutureProvider.autoDispose
    .family<List<TelegramDialog>, String?>((ref, uid) async {
      _requireUser(uid);
      final status = await ref.watch(telegramStatusProvider(uid).future);
      if (!status.canRead) return const [];
      return ref.watch(telegramRepositoryProvider).fetchDialogs();
    }, retry: (_, _) => null);

final telegramMessagesProvider = FutureProvider.autoDispose
    .family<List<TelegramMessage>, (String?, String)>((ref, key) async {
      final (uid, chatId) = key;
      _requireUser(uid);
      final status = await ref.watch(telegramStatusProvider(uid).future);
      if (!status.canRead) return const [];
      return ref.watch(telegramRepositoryProvider).fetchMessages(chatId);
    }, retry: (_, _) => null);

/// Private bytes live only while an image is mounted in the keyed account.
final telegramImageProvider = FutureProvider.autoDispose
    .family<Uint8List, (String?, String)>((ref, key) {
      final (uid, path) = key;
      _requireUser(uid);
      return ref.watch(telegramRepositoryProvider).fetchImage(path);
    }, retry: (_, _) => null);

void _requireUser(String? uid) {
  if (uid == null) throw const TelegramFailure('Sign in to read Telegram.');
}
