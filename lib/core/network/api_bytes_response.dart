import 'dart:typed_data';

/// Bounded binary response, without decoding private image bytes as text.
class ApiBytesResponse {
  const ApiBytesResponse({
    required this.statusCode,
    required this.bytes,
    required this.contentType,
  });
  final int statusCode;
  final Uint8List bytes;
  final String contentType;
  bool get isSuccess => statusCode >= 200 && statusCode < 300;
}
