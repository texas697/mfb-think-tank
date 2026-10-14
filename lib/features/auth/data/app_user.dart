import 'package:flutter/foundation.dart';

/// The signed-in user, as the app needs it.
///
/// A provider-agnostic view of the account so UI code never names a Firebase,
/// Google or Apple type. Built in `data` from the SDK user.
@immutable
class AppUser {
  const AppUser({
    required this.uid,
    this.email,
    this.displayName,
    this.emailVerified = false,
    this.providerIds = const [],
  });

  /// Stable, provider-issued account id.
  final String uid;

  /// Email address, if the provider shared one.
  final String? email;

  /// Display name, if the provider shared one.
  final String? displayName;

  /// Whether the user has confirmed their email address.
  final bool emailVerified;

  /// Sign-in provider ids, e.g. `['password']` or `['google.com']`.
  final List<String> providerIds;

  /// Whether the account can sign in with [providerId].
  bool hasProvider(String providerId) => providerIds.contains(providerId);

  @override
  bool operator ==(Object other) =>
      other is AppUser &&
      other.uid == uid &&
      other.email == email &&
      other.displayName == displayName &&
      other.emailVerified == emailVerified &&
      listEquals(other.providerIds, providerIds);

  @override
  int get hashCode => Object.hash(
    uid,
    email,
    displayName,
    emailVerified,
    Object.hashAll(providerIds),
  );

  @override
  String toString() =>
      'AppUser(uid: $uid, email: $email, displayName: $displayName, '
      'emailVerified: $emailVerified, providerIds: $providerIds)';
}
