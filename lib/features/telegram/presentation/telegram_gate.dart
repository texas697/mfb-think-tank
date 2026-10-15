import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mfb_think_tank/features/readers_digest/application/digest_api_providers.dart';
import 'package:mfb_think_tank/features/readers_digest/presentation/widgets/feed_message.dart';
import 'package:mfb_think_tank/features/telegram/application/telegram_providers.dart';
import 'package:mfb_think_tank/features/telegram/data/telegram_failure.dart';

/// Distinguishes server availability from empty chats and request failures.
class TelegramGate extends ConsumerWidget {
  const TelegramGate({required this.child, super.key});
  final Widget child;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final uid = ref.watch(currentUidProvider);
    final status = ref.watch(telegramStatusProvider(uid));
    if (status.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (status.hasError) {
      return FeedMessage(
        title: 'Could not connect to Telegram',
        body: status.error is TelegramFailure
            ? (status.error! as TelegramFailure).message
            : 'Try again shortly.',
        actionLabel: 'Retry',
        onAction: () => ref.invalidate(telegramStatusProvider),
      );
    }
    if (!status.requireValue.canRead) {
      return FeedMessage(
        title: 'Telegram is unavailable',
        body: status.requireValue.message,
        actionLabel: 'Refresh',
        onAction: () => ref.invalidate(telegramStatusProvider),
      );
    }
    return child;
  }
}
