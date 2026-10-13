import 'package:firebase_auth/firebase_auth.dart';

/// Supplies Firebase ID tokens for authenticated API calls.
///
/// SDK types stay behind this seam so feature code never imports Firebase.
abstract interface class IdTokenProvider {
  /// Returns a valid ID token, refreshing it first when [forceRefresh].
  ///
  /// Throws [StateError] when nobody is signed in.
  Future<String> getIdToken({bool forceRefresh = false});
}

/// [IdTokenProvider] backed by `firebase_auth`.
class FirebaseAuthIdTokenProvider implements IdTokenProvider {
  FirebaseAuthIdTokenProvider({required this._auth});

  final FirebaseAuth _auth;

  @override
  Future<String> getIdToken({bool forceRefresh = false}) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw StateError('No signed-in user');
    }
    final token = await user.getIdToken(forceRefresh);
    if (token == null || token.isEmpty) {
      throw StateError('Firebase returned an empty ID token');
    }
    return token;
  }
}
