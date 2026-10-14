import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:mfb_think_tank/features/auth/data/app_user.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The signed-in backend session: the bearer token, the rotating refresh
/// token and the current [AppUser].
///
/// The single source of truth shared by `BackendAuthRepository` and
/// `BackendIdTokenProvider`: the repository writes it on sign-in/out, the
/// token provider reads it for every authenticated request. Tokens and the
/// cached user are persisted with `shared_preferences` so a restart restores
/// the session without a network round trip.
class BackendSession {
  BackendSession({required this._http, required this._baseUrl});

  static const _tokenKey = 'auth.token';
  static const _refreshTokenKey = 'auth.refreshToken';
  static const _userKey = 'auth.user';
  static const _refreshTimeout = Duration(seconds: 20);

  final http.Client _http;
  final Uri _baseUrl;
  final Future<SharedPreferences> _prefs = SharedPreferences.getInstance();
  final _changes = StreamController<AppUser?>.broadcast();

  String? _token;
  String? _refreshToken;
  AppUser? _user;
  bool _isRestored = false;

  /// Emits on sign-in, sign-out and profile changes.
  Stream<AppUser?> get changes => _changes.stream;

  AppUser? get currentUser => _user;

  String? get currentToken => _token;

  /// Loads the persisted session and emits the restored user, if any.
  ///
  /// Safe to call more than once; only the first call does work.
  Future<void> restore() async {
    if (_isRestored) return;
    _isRestored = true;
    final prefs = await _prefs;
    _token = prefs.getString(_tokenKey);
    _refreshToken = prefs.getString(_refreshTokenKey);
    final json = prefs.getString(_userKey);
    if (_token == null || json == null) return;
    _user = _decodeUser(json);
    _changes.add(_user);
  }

  /// Stores a freshly signed-in session and notifies listeners.
  Future<void> setSignedIn({
    required String token,
    required String refreshToken,
    required AppUser user,
  }) async {
    _token = token;
    _refreshToken = refreshToken;
    _user = user;
    final prefs = await _prefs;
    await prefs.setString(_tokenKey, token);
    await prefs.setString(_refreshTokenKey, refreshToken);
    await _persistUser(prefs);
    _changes.add(user);
  }

  /// Replaces the cached user (e.g. after a profile reload) and notifies.
  Future<void> setUser(AppUser user) async {
    _user = user;
    await _persistUser(await _prefs);
    _changes.add(user);
  }

  /// Clears the session and notifies listeners with `null`.
  Future<void> clear() async {
    _token = null;
    _refreshToken = null;
    _user = null;
    final prefs = await _prefs;
    await prefs.remove(_tokenKey);
    await prefs.remove(_refreshTokenKey);
    await prefs.remove(_userKey);
    _changes.add(null);
  }

  /// Exchanges the refresh token for a new access token.
  ///
  /// Throws [StateError] when there is no signed-in user or the server
  /// rejects the refresh.
  Future<void> refresh() async {
    final refreshToken = _refreshToken;
    if (refreshToken == null) {
      throw StateError('No signed-in user');
    }
    final http.Response response;
    try {
      response = await _http
          .post(
            _url('api/auth/refresh'),
            headers: const {'Content-Type': 'application/json'},
            body: jsonEncode({'refreshToken': refreshToken}),
          )
          .timeout(_refreshTimeout);
    } on http.ClientException {
      throw StateError('Could not refresh the session');
    }
    if (response.statusCode != 200) {
      throw StateError('Could not refresh the session');
    }
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    _token = body['token'] as String;
    _refreshToken = body['refreshToken'] as String? ?? refreshToken;
    final prefs = await _prefs;
    await prefs.setString(_tokenKey, _token!);
    await prefs.setString(_refreshTokenKey, _refreshToken!);
  }

  Future<void> _persistUser(SharedPreferences prefs) async {
    final user = _user;
    if (user == null) {
      await prefs.remove(_userKey);
      return;
    }
    await prefs.setString(_userKey, jsonEncode(_encodeUser(user)));
  }

  Uri _url(String path) => _baseUrl.replace(
    path: '${_baseUrl.path}${_baseUrl.path.endsWith('/') ? '' : '/'}$path',
  );

  static Map<String, Object?> _encodeUser(AppUser user) => {
    'uid': user.uid,
    'email': user.email,
    'displayName': user.displayName,
    'emailVerified': user.emailVerified,
    'providerIds': user.providerIds,
  };

  static AppUser _decodeUser(String json) {
    final map = jsonDecode(json) as Map<String, dynamic>;
    return AppUser(
      uid: map['uid'] as String,
      email: map['email'] as String?,
      displayName: map['displayName'] as String?,
      emailVerified: map['emailVerified'] as bool? ?? false,
      providerIds: [
        for (final id in (map['providerIds'] as List? ?? const []))
          id as String,
      ],
    );
  }
}
