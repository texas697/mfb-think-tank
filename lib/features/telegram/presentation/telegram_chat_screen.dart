import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mfb_think_tank/app/app_routes.dart';
import 'package:mfb_think_tank/app/destination_scope.dart';
import 'package:mfb_think_tank/features/readers_digest/application/digest_api_providers.dart';
import 'package:mfb_think_tank/features/telegram/application/telegram_providers.dart';
import 'package:mfb_think_tank/features/telegram/presentation/telegram_gate.dart';
import 'package:mfb_think_tank/features/telegram/presentation/telegram_message_list.dart';

/// Protected channel deep link with native back/refresh controls.
class TelegramChatScreen extends ConsumerWidget {
  const TelegramChatScreen({required this.chatId, super.key});
  final String chatId;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final uid = ref.watch(currentUidProvider);
    final isActive =
        DestinationScope.isActive(context, 3) &&
        (ModalRoute.of(context)?.isCurrent ?? true);
    final dialogs = isActive
        ? ref.watch(telegramDialogsProvider(uid)).value
        : null;
    final title =
        dialogs?.where((d) => d.id == chatId).firstOrNull?.title ??
        'Telegram channel';
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 4, 8, 4),
          child: Row(
            children: [
              BackButton(
                key: const Key('telegram-back'),
                onPressed: () => context.canPop()
                    ? context.pop()
                    : context.go(AppRoutes.telegram),
              ),
              Expanded(
                child: Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              IconButton(
                key: const Key('telegram-messages-refresh'),
                tooltip: 'Refresh messages',
                onPressed: () => ref.invalidate(
                  telegramMessagesProvider((
                    ref.read(currentUidProvider),
                    chatId,
                  )),
                ),
                icon: const Icon(Icons.refresh),
              ),
            ],
          ),
        ),
        Expanded(
          child: isActive
              ? TelegramGate(child: TelegramMessageList(chatId: chatId))
              : const SizedBox.shrink(),
        ),
      ],
    );
  }
}
