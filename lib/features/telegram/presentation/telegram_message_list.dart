import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mfb_think_tank/features/readers_digest/application/digest_api_providers.dart';
import 'package:mfb_think_tank/features/readers_digest/presentation/widgets/feed_message.dart';
import 'package:mfb_think_tank/features/telegram/application/telegram_providers.dart';
import 'package:mfb_think_tank/features/telegram/data/telegram_failure.dart';
import 'package:mfb_think_tank/features/telegram/presentation/telegram_message_bubble.dart';

/// Latest bounded message window; there is no cursor API or implied history.
class TelegramMessageList extends ConsumerWidget {
  const TelegramMessageList({required this.chatId, super.key});
  final String chatId;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final uid = ref.watch(currentUidProvider);
    final result = ref.watch(telegramMessagesProvider((uid, chatId)));
    if (result.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    final messages = result.value;
    if (messages == null) {
      return FeedMessage(
        title: 'Could not load messages',
        body: result.error is TelegramFailure
            ? (result.error! as TelegramFailure).message
            : null,
        actionLabel: 'Retry',
        onAction: () => ref.invalidate(
          telegramMessagesProvider((ref.read(currentUidProvider), chatId)),
        ),
      );
    }
    if (messages.isEmpty) {
      return const FeedMessage(
        title: 'No messages yet',
        body: 'Use Refresh to check for new messages.',
      );
    }
    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(
          telegramMessagesProvider((ref.read(currentUidProvider), chatId)),
        );
        try {
          await ref.read(
            telegramMessagesProvider((ref.read(currentUidProvider), chatId))
                .future,
          );
        } catch (_) {
          /* UI renders failure. */
        }
      },
      child: ListView.builder(
        key: PageStorageKey('telegram-messages-$chatId'),
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        itemCount: messages.length + 1,
        itemBuilder: (context, index) => index == 0
            ? Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  result.hasError
                      ? 'Could not refresh. Showing the previous messages.'
                      : 'Latest ${messages.length} messages · Read only',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              )
            : Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 760),
                  child: TelegramMessageBubble(
                    key: ValueKey('$chatId:${messages[index - 1].id}'),
                    chatId: chatId,
                    message: messages[index - 1],
                  ),
                ),
              ),
      ),
    );
  }
}
