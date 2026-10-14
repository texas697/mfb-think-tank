import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:mfb_think_tank/features/auth/data/auth_failure.dart';

/// Low-level transport for the Crucix auth endpoints.
///
/// Implements the wire contract in `docs/FDROID_BACKEND_AUTH.md`: JSON in and
/// out, `{error: {code, message}}` mapped to [AuthFailure], and every
/// transport failure mapped to `network-request-failed`.
class BackendAuthApi {
  BackendAuthApi({required this._http, required this._baseUrl});

  static const _timeout = Duration(seconds: 20);

  final http.Client _http;
  final Uri _baseUrl;

  /// GET [path], optionally authenticated with a bearer [token].
  Future<Map<String, dynamic>> get(String path, {String? token}) =>
      _send('GET', path, token: token);

  /// POST [path] with a JSON [body], optionally authenticated.
  Future<Map<String, dynamic>> post(
    String path,
    Object? body, {
    String? token,
  }) => _send('POST', path, body: body, token: token);

  Future<Map<String, dynamic>> _send(
    String method,
    String path, {
    Object? body,
    String? token,
  }) async {
    final headers = <String, String>{'Accept': 'application/json'};
    if (body != null) headers['Content-Type'] = 'application/json';
    if (token != null) headers['Authorization'] = 'Bearer $token';

    final http.Response response;
    try {
      final uri = _url(path);
      response = method == 'GET'
          ? await _http.get(uri, headers: headers).timeout(_timeout)
          : await _http
                .post(
                  uri,
                  headers: headers,
                  body: body == null ? null : jsonEncode(body),
                )
                .timeout(_timeout);
    } on http.ClientException {
      throw _networkFailure();
    } on TimeoutException {
      throw _networkFailure();
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return _decodeBody(response.body);
    }
    throw _failureFrom(response);
  }

  static Map<String, dynamic> _decodeBody(String body) {
    if (body.isEmpty) return const {};
    try {
      final decoded = jsonDecode(body);
      return decoded is Map<String, dynamic> ? decoded : const {};
    } on FormatException {
      throw const AuthFailure.unknown();
    }
  }

  static AuthFailure _failureFrom(http.Response response) {
    final code =
        _errorCode(response.body) ?? _codeForStatus(response.statusCode);
    return AuthFailure(code, AuthFailure.messageForCode(code));
  }

  static String? _errorCode(String body) {
    if (body.isEmpty) return null;
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic>) {
        final error = decoded['error'];
        if (error is Map<String, dynamic> && error['code'] is String) {
          return error['code'] as String;
        }
      }
    } on FormatException {
      return null;
    }
    return null;
  }

  static String _codeForStatus(int statusCode) => switch (statusCode) {
    401 || 403 => 'invalid-credential',
    404 => 'user-not-found',
    409 => 'email-already-in-use',
    429 => 'too-many-requests',
    _ => 'unknown',
  };

  static AuthFailure _networkFailure() => AuthFailure(
    'network-request-failed',
    AuthFailure.messageForCode('network-request-failed'),
  );

  Uri _url(String path) => _baseUrl.replace(
    path: '${_baseUrl.path}${_baseUrl.path.endsWith('/') ? '' : '/'}$path',
  );
}
