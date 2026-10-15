import 'dart:typed_data';

import 'package:mfb_think_tank/features/telegram/data/telegram_dialog.dart';
import 'package:mfb_think_tank/features/telegram/data/telegram_message.dart';
import 'package:mfb_think_tank/features/telegram/data/telegram_status.dart';

/// Published Telegram snapshots and private media. Throws only TelegramFailure.
abstract interface class TelegramRepository {
  Future<TelegramStatus> fetchStatus();
  Future<List<TelegramDialog>> fetchDialogs();
  Future<List<TelegramMessage>> fetchMessages(String chatId);
  Future<Uint8List> fetchImage(String path);
  Uri mediaUri(String path);
  Future<Map<String, String>> mediaHeaders({bool forceRefresh = false});
}
