import 'dart:async';

import 'package:http/http.dart' as http;
import 'package:mfb_think_tank/features/auth/data/account_deletion_gateway.dart';
import 'package:mfb_think_tank/features/auth/data/app_user.dart';
import 'package:mfb_think_tank/features/auth/data/auth_failure.dart';
import 'package:mfb_think_tank/features/auth/data/auth_repository.dart';
import 'package:mfb_think_tank/features/auth/data/backend_auth_api.dart';
import 'package:mfb_think_tank/features/auth/data/backend_session.dart';

/// [AuthRepository] backed by the Crucix auth endpoints.
///
/// Implements the contract in `docs/FDROID_BACKEND_AUTH.md`; all errors reach
/// callers as an [AuthFailure].
class BackendAuthRepository implements AuthRepository {
  BackendAuthRepository({
    required this._session,
    required this._api,
    required this._deletion,
  });

  final BackendSession _session;
  final BackendAuthApi _api;
  final AccountDeletionGateway _deletion;

  @override
  Stream<AppUser?> authStateChanges() => _stateChanges();

  @override
  Stream<AppUser?> userChanges() => _stateChanges();

  Stream<AppUser?> _stateChanges() async* {
    await _session.restore();
    yield _session.currentUser;
    yield* _session.changes;
  }

  @override
  AppUser? get currentUser => _session.currentUser;

  @override
  Future<void> signInWithEmail({
    required String email,
    required String password,
  }) async => _storeSession(
    await _api.post('api/auth/signin', {
      'email': email.trim(),
      'password': password,
    }),
  );

  @override
  Future<void> signUpWithEmail({
    required String email,
    required String password,
    String? displayName,
  }) async {
    final name = displayName?.trim();
    await _storeSession(
      await _api.post('api/auth/signup', {
        'email': email.trim(),
        'password': password,
        if (name != null && name.isNotEmpty) 'displayName': name,
      }),
    );
  }

  @override
  Future<void> sendPasswordResetEmail(String email) =>
      _api.post('api/auth/reset-password', {'email': email.trim()});

  @override
  Future<void> sendEmailVerification() => _api.post(
    'api/auth/verify-email',
    const <String, Object?>{},
    token: _requireToken(),
  );

  @override
  Future<void> reloadUser() async {
    final body = await _api.get('api/me', token: _requireToken());
    await _session.setUser(_userFrom(body));
  }

  @override
  Future<void> signOut() => _session.clear();

  @override
  Future<void> deleteAccount({String? password}) async {
    await _deletion.deleteAccount();
    await _session.clear();
  }

  @override
  Future<void> signInWithGoogle() async => throw const AuthFailure(
    'unsupported',
    'Google Sign-In is not available in this build.',
  );

  @override
  Future<void> signInWithApple() async => throw const AuthFailure(
    'unsupported',
    'Sign in with Apple is not available in this build.',
  );

  Future<void> _storeSession(Map<String, dynamic> body) => _session.setSignedIn(
    token: body['token'] as String,
    refreshToken: body['refreshToken'] as String,
    user: _userFrom(body['user'] as Map<String, dynamic>),
  );

  String _requireToken() {
    final token = _session.currentToken;
    if (token == null || token.isEmpty) {
      throw const AuthFailure('no-current-user', 'You are not signed in.');
    }
    return token;
  }

  static AppUser _userFrom(Map<String, dynamic> json) => AppUser(
    uid: json['uid'] as String,
    email: json['email'] as String?,
    displayName: json['displayName'] as String?,
    emailVerified: json['emailVerified'] as bool? ?? false,
    providerIds: [
      for (final id in (json['providerIds'] as List? ?? const [])) id as String,
    ],
  );
}

/// Builds the Crucix-backed [AuthRepository] the app runs on.
AuthRepository createBackendAuthRepository({
  required BackendSession session,
  required http.Client http,
  required Uri baseUrl,
  required AccountDeletionGateway deletion,
}) => BackendAuthRepository(
  session: session,
  api: BackendAuthApi(http: http, baseUrl: baseUrl),
  deletion: deletion,
);
