import 'dart:convert';
import 'dart:typed_data';

import 'package:mfb_think_tank/core/network/api_client.dart';
import 'package:mfb_think_tank/core/network/id_token_provider.dart';
import 'package:mfb_think_tank/features/telegram/data/telegram_dialog.dart';
import 'package:mfb_think_tank/features/telegram/data/telegram_failure.dart';
import 'package:mfb_think_tank/features/telegram/data/telegram_message.dart';
import 'package:mfb_think_tank/features/telegram/data/telegram_repository.dart';
import 'package:mfb_think_tank/features/telegram/data/telegram_status.dart';

/// HTTP implementation with typed failures and bounded private images.
class HttpTelegramRepository implements TelegramRepository {
  HttpTelegramRepository({
    required this._api,
    required this._base,
    required this._tokens,
  });
  final ApiClient _api;
  final Uri _base;
  final IdTokenProvider _tokens;

  @override
  Future<TelegramStatus> fetchStatus() => _guard(
    () async => TelegramStatus.fromJson(await _get('api/telegram/status')),
  );
  @override
  Future<List<TelegramDialog>> fetchDialogs() => _guard(() async {
    final json = await _get('api/telegram/dialogs', query: {'limit': '200'});
    return (json['dialogs'] as List)
        .map((x) => TelegramDialog.fromJson(x as Map<String, dynamic>))
        .toList();
  });
  @override
  Future<List<TelegramMessage>> fetchMessages(String chatId) =>
      _guard(() async {
        final json = await _get(
          'api/telegram/messages/${Uri.encodeComponent(chatId)}',
          query: {'limit': '100'},
        );
        return (json['messages'] as List)
            .map((x) => TelegramMessage.fromJson(x as Map<String, dynamic>))
            .toList();
      });

  Future<Map<String, dynamic>> _get(
    String path, {
    Map<String, String>? query,
  }) async {
    final response = await _api.get(
      path,
      query: query,
      timeout: const Duration(seconds: 75),
    );
    if (!response.isSuccess) throw _failure(response.statusCode);
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  @override
  Future<Uint8List> fetchImage(String path) => _guard(() async {
    final uri = Uri.parse(path);
    _checkPath(uri);
    final response = await _api.getBytes(uri.path, query: uri.queryParameters);
    if (!response.isSuccess) throw _failure(response.statusCode);
    if (!response.contentType.startsWith('image/')) {
      throw const TelegramFailure('This image is unavailable.');
    }
    return response.bytes;
  });

  @override
  Uri mediaUri(String path) {
    final uri = Uri.parse(path);
    _checkPath(uri);
    return _base.resolve(path);
  }

  void _checkPath(Uri uri) {
    if (uri.hasScheme ||
        uri.hasAuthority ||
        !RegExp(r'^api/telegram/(media|avatar)/[-\w%]+(?:/\d+)?$')
            .hasMatch(uri.path)) {
      throw const TelegramFailure('Invalid attachment location.');
    }
  }

  @override
  Future<Map<String, String>> mediaHeaders({bool forceRefresh = false}) =>
      _guard(
        () async => {
          'Authorization':
              'Bearer ${await _tokens.getIdToken(forceRefresh: forceRefresh)}',
        },
      );

  TelegramFailure _failure(int status) => TelegramFailure(switch (status) {
    401 => 'Your session could not be verified. Please try again.',
    403 => 'This Telegram feed is not available to your account.',
    404 => 'This channel or attachment is no longer published.',
    429 => 'Telegram is busy. Wait a moment before refreshing.',
    _ =>
      'The Telegram server could not complete this request. Try again shortly.',
  }, statusCode: status);

  Future<T> _guard<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on TelegramFailure {
      rethrow;
    } on ApiException catch (e) {
      throw TelegramFailure(switch (e.kind) {
        ApiFailureKind.timeout =>
          'Telegram took too long to respond. Try again.',
        ApiFailureKind.unauthorized =>
          'Your session could not be verified. Please try again.',
        ApiFailureKind.malformed => 'This attachment is too large to display.',
        _ => 'Could not reach Telegram. Check your connection and try again.',
      });
    } catch (_) {
      throw const TelegramFailure('Telegram returned an unreadable response.');
    }
  }
}
