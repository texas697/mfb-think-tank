import 'package:mfb_think_tank/features/telegram/data/telegram_media.dart';
import 'package:mfb_think_tank/features/telegram/data/telegram_translation.dart';
import 'package:mfb_think_tank/features/telegram/data/telegram_webpage.dart';

/// A read-only message including its original text and optional attachments.
class TelegramMessage {
  const TelegramMessage({
    required this.id,
    this.text = '',
    this.date,
    this.senderId,
    this.isOutgoing = false,
    this.mediaType,
    this.replyToMsgId,
    this.media,
    this.translation,
    this.webpage,
  });
  factory TelegramMessage.fromJson(Map<String, dynamic> json) =>
      TelegramMessage(
        id: (json['id'] as num).toInt(),
        text: json['text'] as String? ?? '',
        date: DateTime.tryParse(json['date'] as String? ?? ''),
        senderId: json['senderId'] as String?,
        isOutgoing: json['out'] as bool? ?? false,
        mediaType: json['mediaType'] as String?,
        replyToMsgId: (json['replyToMsgId'] as num?)?.toInt(),
        media: json['media'] == null
            ? null
            : TelegramMedia.fromJson(json['media'] as Map<String, dynamic>),
        translation: json['translation'] == null
            ? null
            : TelegramTranslation.fromJson(
                json['translation'] as Map<String, dynamic>,
              ),
        webpage: json['webpage'] == null
            ? null
            : TelegramWebpage.fromJson(json['webpage'] as Map<String, dynamic>),
      );
  final int id;
  final String text;
  final DateTime? date;
  final String? senderId;
  final bool isOutgoing;
  final String? mediaType;
  final int? replyToMsgId;
  final TelegramMedia? media;
  final TelegramTranslation? translation;
  final TelegramWebpage? webpage;
}
