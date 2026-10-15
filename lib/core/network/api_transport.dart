import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:mfb_think_tank/core/network/api_exception.dart';
import 'package:mfb_think_tank/core/network/id_token_provider.dart';

/// Shared authenticated request and response-body handling for JSON and bytes.
class ApiTransport {
  ApiTransport({
    required this._http,
    required this._base,
    required this._tokens,
  });
  final http.Client _http;
  final Uri _base;
  final IdTokenProvider _tokens;

  Future<http.Response> send(
    String method,
    String path, {
    Map<String, String>? query,
    Object? body,
    required Duration timeout,
    required int maxBytes,
  }) async {
    final first = await _attempt(
      method,
      path,
      query: query,
      body: body,
      timeout: timeout,
      maxBytes: maxBytes,
      forceRefresh: false,
    );
    if (first.statusCode != 401) return first;
    return _attempt(
      method,
      path,
      query: query,
      body: body,
      timeout: timeout,
      maxBytes: maxBytes,
      forceRefresh: true,
    );
  }

  Future<http.Response> _attempt(
    String method,
    String path, {
    Map<String, String>? query,
    Object? body,
    required Duration timeout,
    required int maxBytes,
    required bool forceRefresh,
  }) async {
    final abort = Completer<void>();
    try {
      return await _request(
        method,
        path,
        query: query,
        body: body,
        maxBytes: maxBytes,
        forceRefresh: forceRefresh,
        abortTrigger: abort.future,
      ).timeout(
        timeout,
        onTimeout: () {
          if (!abort.isCompleted) abort.complete();
          throw TimeoutException('Request deadline elapsed');
        },
      );
    } on TimeoutException {
      throw const ApiException(ApiFailureKind.timeout);
    } on http.ClientException catch (e) {
      throw ApiException(ApiFailureKind.network, body: e.message);
    } on ApiException {
      rethrow;
    } on StateError {
      throw const ApiException(ApiFailureKind.unauthorized);
    } catch (_) {
      throw const ApiException(ApiFailureKind.network);
    } finally {
      if (!abort.isCompleted) abort.complete();
    }
  }

  Future<http.Response> _request(
    String method,
    String path, {
    Map<String, String>? query,
    Object? body,
    required int maxBytes,
    required bool forceRefresh,
    required Future<void> abortTrigger,
  }) async {
    final token = await _tokens.getIdToken(forceRefresh: forceRefresh);
    final url = _base.replace(
      path: '${_base.path}${_base.path.endsWith('/') ? '' : '/'}$path',
      queryParameters: query == null || query.isEmpty ? null : query,
    );
    final request =
        http.AbortableRequest(method, url, abortTrigger: abortTrigger)
          ..headers.addAll({
            'Authorization': 'Bearer $token',
            'Accept': 'application/json',
          });
    if (body != null) {
      request.headers['Content-Type'] = 'application/json';
      request.body = body is String ? body : jsonEncode(body);
    }
    final response = await _http.send(request);
    if ((response.contentLength ?? 0) > maxBytes) {
      await response.stream.listen(null).cancel();
      throw const ApiException(ApiFailureKind.malformed);
    }
    final bytes = <int>[];
    await for (final chunk in response.stream) {
      if (bytes.length + chunk.length > maxBytes) {
        throw const ApiException(ApiFailureKind.malformed);
      }
      bytes.addAll(chunk);
    }
    return http.Response.bytes(
      bytes,
      response.statusCode,
      headers: response.headers,
    );
  }
}
