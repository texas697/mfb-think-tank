import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:mfb_think_tank/core/network/id_token_provider.dart';

/// Why a low-level API call failed, before feature-level mapping.
enum ApiFailureKind { network, timeout, unauthorized, http, malformed }

/// Transport-level failure. Feature repositories map this to their own
/// failure types; UI never sees it.
class ApiException implements Exception {
  const ApiException(this.kind, {this.statusCode, this.body});

  final ApiFailureKind kind;
  final int? statusCode;
  final String? body;

  @override
  String toString() => 'ApiException(${kind.name}, $statusCode)';
}

/// A decoded HTTP response body with its status code.
class ApiResponse {
  const ApiResponse({required this.statusCode, required this.body});

  final int statusCode;
  final String body;

  bool get isSuccess => statusCode >= 200 && statusCode < 300;
}

/// Authenticated JSON transport for the Crucix API.
///
/// Attaches `Authorization: Bearer <Firebase ID token>` to every request.
/// A 401 triggers exactly one forced token refresh and a single retry; a
/// second 401 is surfaced as [ApiResponse.statusCode] 401 for the caller
/// (never treated as a Firebase sign-out).
class ApiClient {
  ApiClient({required this._http, required this._base, required this._tokens});

  static const _defaultTimeout = Duration(seconds: 15);

  final http.Client _http;
  final Uri _base;
  final IdTokenProvider _tokens;

  Future<ApiResponse> get(
    String path, {
    Map<String, String>? query,
    Duration timeout = _defaultTimeout,
  }) => _send('GET', path, query: query, timeout: timeout);

  Future<ApiResponse> post(
    String path, {
    Object? body,
    Duration timeout = const Duration(seconds: 20),
  }) => _send('POST', path, body: body, timeout: timeout);

  Future<ApiResponse> put(
    String path, {
    Object? body,
    Duration timeout = const Duration(seconds: 20),
  }) => _send('PUT', path, body: body, timeout: timeout);

  Future<ApiResponse> delete(
    String path, {
    Duration timeout = const Duration(seconds: 20),
  }) => _send('DELETE', path, timeout: timeout);

  Future<ApiResponse> _send(
    String method,
    String path, {
    Map<String, String>? query,
    Object? body,
    required Duration timeout,
  }) async {
    final response = await _attempt(
      method,
      path,
      query: query,
      body: body,
      timeout: timeout,
      forceRefresh: false,
    );
    if (response.statusCode != 401) return response;
    return _attempt(
      method,
      path,
      query: query,
      body: body,
      timeout: timeout,
      forceRefresh: true,
    );
  }

  Future<ApiResponse> _attempt(
    String method,
    String path, {
    Map<String, String>? query,
    Object? body,
    required Duration timeout,
    required bool forceRefresh,
  }) async {
    final token = await _tokens.getIdToken(forceRefresh: forceRefresh);
    final url = _base.replace(
      path: '${_base.path}${_base.path.endsWith('/') ? '' : '/'}$path',
      queryParameters: (query == null || query.isEmpty) ? null : query,
    );
    final request = http.Request(method, url)
      ..headers.addAll({
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      });
    if (body != null) {
      request.headers['Content-Type'] = 'application/json';
      request.body = body is String ? body : jsonEncode(body);
    }
    try {
      final streamed = await _http.send(request).timeout(timeout);
      final response = await http.Response.fromStream(streamed);
      return ApiResponse(statusCode: response.statusCode, body: response.body);
    } on TimeoutException {
      throw const ApiException(ApiFailureKind.timeout);
    } on http.ClientException catch (e) {
      throw ApiException(ApiFailureKind.network, body: e.message);
    } on ApiException {
      rethrow;
    } catch (_) {
      throw const ApiException(ApiFailureKind.network);
    }
  }
}
