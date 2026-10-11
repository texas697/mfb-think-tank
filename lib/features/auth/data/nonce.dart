import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';

const _nonceCharset =
    '0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._';

/// A cryptographically secure random nonce, used to bind an Apple ID token to
/// one sign-in attempt.
String generateNonce([int length = 32]) {
  final random = Random.secure();
  return List.generate(
    length,
    (_) => _nonceCharset[random.nextInt(_nonceCharset.length)],
  ).join();
}

/// Hex-encoded SHA-256 of [input]. Apple receives the hash, Firebase the raw
/// nonce.
String sha256OfString(String input) =>
    sha256.convert(utf8.encode(input)).toString();
