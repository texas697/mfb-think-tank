import 'package:material_ui/material_ui.dart';
import 'package:mfb_think_tank/app/theme.dart';
import 'package:mfb_think_tank/features/telegram/data/telegram_message.dart';
import 'package:mfb_think_tank/features/telegram/presentation/telegram_attachment.dart';
import 'package:mfb_think_tank/features/telegram/presentation/telegram_text.dart';
import 'package:mfb_think_tank/features/telegram/presentation/telegram_webpage_card.dart';

/// Original provenance, translated-first text, and private rich attachments.
class TelegramMessageBubble extends StatefulWidget {
  const TelegramMessageBubble({
    required this.chatId,
    required this.message,
    super.key,
  });
  final String chatId;
  final TelegramMessage message;
  @override
  State<TelegramMessageBubble> createState() => _TelegramMessageBubbleState();
}

class _TelegramMessageBubbleState extends State<TelegramMessageBubble> {
  bool _isOriginalShown = false;
  @override
  Widget build(BuildContext context) {
    final message = widget.message;
    final translation = message.translation;
    final date = message.date?.toLocal();
    final timestamp = date == null
        ? ''
        : '${date.month}/${date.day}/${date.year} '
              '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: message.isOutgoing ? AppTheme.raised : AppTheme.surface,
        border: Border.all(color: AppTheme.border),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (message.replyToMsgId != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                'In reply to an earlier post',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          if (message.media case final media?)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: TelegramAttachment(
                chatId: widget.chatId,
                messageId: message.id,
                media: media,
              ),
            )
          else if (message.mediaType != null && message.mediaType != 'webpage')
            Text('[${message.mediaType}]'),
          if ((translation?.text ?? message.text).isNotEmpty)
            TelegramText(text: translation?.text ?? message.text),
          if (message.webpage case final webpage?)
            TelegramWebpageCard(
              webpage: webpage,
              chatId: widget.chatId,
              messageId: message.id,
            ),
          if (translation != null)
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton(
                key: Key('telegram-original-${message.id}'),
                onPressed: () =>
                    setState(() => _isOriginalShown = !_isOriginalShown),
                child: Text(
                  'Translated${translation.sourceLanguage == null ? '' : ' from ${translation.sourceLanguage}'} · '
                  '${_isOriginalShown ? 'Hide original' : 'Show original'}',
                ),
              ),
            ),
          if (_isOriginalShown && translation != null)
            TelegramText(text: message.text),
          const SizedBox(height: 8),
          Text(
            timestamp,
            textAlign: TextAlign.end,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}
