/// Availability of the operator’s read-only Telegram connection.
class TelegramStatus {
  const TelegramStatus({
    required this.isConfigured,
    required this.isAuthenticated,
    required this.isConnected,
  });
  factory TelegramStatus.fromJson(Map<String, dynamic> json) => TelegramStatus(
    isConfigured: json['configured'] as bool,
    isAuthenticated: json['authenticated'] as bool,
    isConnected: json['connected'] as bool,
  );
  final bool isConfigured;
  final bool isAuthenticated;
  final bool isConnected;
  bool get canRead => isConfigured && isAuthenticated && isConnected;
  String get message => !isConfigured
      ? 'Telegram is not configured on the intelligence server.'
      : !isAuthenticated
      ? 'The server’s Telegram session needs to be connected.'
      : 'The Telegram connection is temporarily offline. Try refreshing shortly.';
}
