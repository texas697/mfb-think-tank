import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:mfb_think_tank/core/network/api_bytes_response.dart';
import 'package:mfb_think_tank/core/network/api_response.dart';
import 'package:mfb_think_tank/core/network/api_transport.dart';
import 'package:mfb_think_tank/core/network/id_token_provider.dart';

export 'api_exception.dart';
export 'api_response.dart';

/// Authenticated JSON and bounded binary transport with one 401 refresh.
class ApiClient {
  ApiClient({
    required http.Client http,
    required Uri base,
    required IdTokenProvider tokens,
  }) : _transport = ApiTransport(http: http, base: base, tokens: tokens);
  final ApiTransport _transport;

  Future<ApiResponse> get(
    String path, {
    Map<String, String>? query,
    Duration timeout = const Duration(seconds: 15),
  }) => _send('GET', path, query: query, timeout: timeout);

  Future<ApiBytesResponse> getBytes(
    String path, {
    Map<String, String>? query,
    int maxBytes = 12 * 1024 * 1024,
    Duration timeout = const Duration(seconds: 30),
  }) async {
    final response = await _transport.send(
      'GET',
      path,
      query: query,
      timeout: timeout,
      maxBytes: maxBytes,
    );
    return ApiBytesResponse(
      statusCode: response.statusCode,
      bytes: response.bodyBytes,
      contentType: response.headers['content-type'] ?? '',
    );
  }

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
    Object? body,
    Map<String, String>? query,
    required Duration timeout,
  }) async {
    final response = await _transport.send(
      method,
      path,
      query: query,
      body: body,
      timeout: timeout,
      maxBytes: 16 * 1024 * 1024,
    );
    return ApiResponse(
      statusCode: response.statusCode,
      body: utf8.decode(response.bodyBytes, allowMalformed: true),
    );
  }
}
