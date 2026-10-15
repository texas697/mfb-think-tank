/// Encoded private media paths; credentials are always sent as headers.
abstract final class TelegramPaths {
  static String avatar(String chatId) =>
      'api/telegram/avatar/${Uri.encodeComponent(chatId)}';
  static String media(String chatId, int id, String kind) {
    if (!const {'photo', 'full', 'thumb', 'file', 'webpage'}.contains(kind)) {
      throw ArgumentError.value(kind, 'kind');
    }
    return 'api/telegram/media/${Uri.encodeComponent(chatId)}/$id?kind=$kind';
  }
}
