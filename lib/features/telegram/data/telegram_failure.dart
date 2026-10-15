/// User-facing failure at the Telegram repository boundary.
class TelegramFailure implements Exception {
  const TelegramFailure(this.message, {this.statusCode});
  final String message;
  final int? statusCode;
  @override
  String toString() => message;
}
