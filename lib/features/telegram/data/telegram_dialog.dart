/// One channel or chat published by the server’s allowlist.
class TelegramDialog {
  const TelegramDialog({
    required this.id,
    required this.title,
    this.group,
    this.type = 'channel',
    this.unreadCount = 0,
    this.hasPhoto = false,
    this.lastMessage = '',
    this.date,
  });
  factory TelegramDialog.fromJson(Map<String, dynamic> json) => TelegramDialog(
    id: json['id'] as String,
    title: json['title'] as String,
    group: json['group'] as String?,
    type: json['type'] as String? ?? 'chat',
    unreadCount: (json['unreadCount'] as num?)?.toInt() ?? 0,
    hasPhoto: json['hasPhoto'] as bool? ?? false,
    lastMessage:
        (json['lastMessage'] as Map<String, dynamic>?)?['text'] as String? ??
        '',
    date: DateTime.tryParse(json['date'] as String? ?? ''),
  );
  final String id;
  final String title;
  final String? group;
  final String type;
  final int unreadCount;
  final bool hasPhoto;
  final String lastMessage;
  final DateTime? date;
}
