import 'dart:convert';

import 'package:mfb_think_tank/core/network/api_client.dart';
import 'package:mfb_think_tank/features/auth/data/auth_failure.dart';

/// Server-side account deletion: wipes the user's data and account in one
/// request, so nothing is left behind after a local delete.
abstract class AccountDeletionGateway {
  /// Deletes the signed-in user's account and all of its data.
  ///
  /// Throws [AuthFailure] when the server could not complete the deletion;
  /// the account is then still intact and the user can retry.
  Future<void> deleteAccount();
}

/// Calls `DELETE /api/me` on the Crucix API.
class HttpAccountDeletionGateway implements AccountDeletionGateway {
  HttpAccountDeletionGateway({required this._api});

  static const failureCode = 'account-deletion-failed';
  static const _retryMessage =
      'Account deletion failed. Check your connection and try again.';

  // Resolved lazily so building the auth repository never requires the API
  // base URL to be configured.
  final ApiClient Function() _api;

  @override
  Future<void> deleteAccount() async {
    final ApiResponse response;
    try {
      response = await _api().delete('api/me', timeout: _timeout);
    } on ApiException catch (e) {
      throw AuthFailure(failureCode, _messageFor(e));
    }
    if (response.isSuccess) return;
    throw AuthFailure(
      failureCode,
      _serverMessage(response.body) ?? _retryMessage,
    );
  }

  // The server deletes Firestore data recursively before the Auth user.
  static const _timeout = Duration(seconds: 30);

  static String _messageFor(ApiException e) => switch (e.kind) {
    ApiFailureKind.timeout =>
      'The server took too long to delete your account. Please try again.',
    ApiFailureKind.unauthorized =>
      'For your security, sign out and sign back in, then try again.',
    _ => _retryMessage,
  };

  static String? _serverMessage(String body) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic>) {
        final error = decoded['error'];
        if (error is String && error.isNotEmpty) return error;
      }
    } on FormatException {
      // Non-JSON body; fall back to the generic message.
    }
    return null;
  }
}
