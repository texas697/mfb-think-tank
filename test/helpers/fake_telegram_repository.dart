import 'dart:convert';
import 'dart:typed_data';

import 'package:mfb_think_tank/features/telegram/data/telegram_dialog.dart';
import 'package:mfb_think_tank/features/telegram/data/telegram_message.dart';
import 'package:mfb_think_tank/features/telegram/data/telegram_repository.dart';
import 'package:mfb_think_tank/features/telegram/data/telegram_status.dart';

class FakeTelegramRepository implements TelegramRepository {
  TelegramStatus status = const TelegramStatus(
    isConfigured: true,
    isAuthenticated: true,
    isConnected: true,
  );
  List<TelegramDialog> dialogs = const [
    TelegramDialog(
      id: '-1001',
      title: 'Iran updates',
      group: 'Iran',
      lastMessage: 'Morning update',
    ),
    TelegramDialog(id: '-1002', title: 'Europe news', group: 'Europe'),
  ];
  List<TelegramMessage> messages = const [];
  Exception? error;
  Future<TelegramStatus> Function()? onStatus;
  int dialogCalls = 0;
  final messageCalls = <String>[];
  Future<List<TelegramMessage>> Function(String)? onMessages;
  @override
  Future<TelegramStatus> fetchStatus() async =>
      onStatus == null ? status : await onStatus!();
  @override
  Future<List<TelegramDialog>> fetchDialogs() async {
    dialogCalls++;
    if (error != null) throw error!;
    return dialogs;
  }

  @override
  Future<List<TelegramMessage>> fetchMessages(String chatId) async {
    messageCalls.add(chatId);
    if (onMessages != null) return onMessages!(chatId);
    if (error != null) throw error!;
    return messages;
  }

  @override
  Future<Uint8List> fetchImage(String path) async => base64Decode(
    'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR4nGNQ8Ej6DwADIAHKrnNmngAAAABJRU5ErkJggg==',
  );
  @override
  Future<Map<String, String>> mediaHeaders({bool forceRefresh = false}) async =>
      {'Authorization': 'Bearer fixture'};
  @override
  Uri mediaUri(String path) => Uri.parse('https://fixture.example/$path');
}
