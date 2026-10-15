import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mfb_think_tank/features/readers_digest/application/digest_api_providers.dart';
import 'package:mfb_think_tank/features/readers_digest/presentation/widgets/feed_message.dart';
import 'package:mfb_think_tank/features/telegram/application/telegram_providers.dart';
import 'package:mfb_think_tank/features/telegram/data/telegram_dialog.dart';
import 'package:mfb_think_tank/features/telegram/data/telegram_failure.dart';
import 'package:mfb_think_tank/features/telegram/presentation/telegram_dialog_tile.dart';

/// Searchable published channels in the server’s region/group ordering.
class TelegramDirectory extends ConsumerWidget {
  const TelegramDirectory({required this.query, super.key});
  final String query;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final uid = ref.watch(currentUidProvider);
    final result = ref.watch(telegramDialogsProvider(uid));
    if (result.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    final dialogs = result.value;
    if (dialogs == null) {
      return FeedMessage(
        title: 'Could not load channels',
        body: result.error is TelegramFailure
            ? (result.error! as TelegramFailure).message
            : null,
        actionLabel: 'Retry',
        onAction: () => ref.invalidate(telegramDialogsProvider),
      );
    }
    final visible = dialogs
        .where(
          (d) => d.title.toLowerCase().contains(query.trim().toLowerCase()),
        )
        .toList();
    if (visible.isEmpty) {
      return FeedMessage(
        title: dialogs.isEmpty
            ? 'No channels published yet'
            : 'No matching channels',
        body: dialogs.isEmpty
            ? 'Channels appear here when the server publishes them.'
            : 'Try a different channel name.',
      );
    }
    final groups = <String, List<TelegramDialog>>{};
    for (final dialog in visible) {
      (groups[dialog.group ?? 'Channels'] ??= []).add(dialog);
    }
    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(telegramDialogsProvider);
        try {
          await ref.read(
            telegramDialogsProvider(ref.read(currentUidProvider)).future,
          );
        } catch (_) {
          /* UI renders failure. */
        }
      },
      child: ListView(
        key: const PageStorageKey('telegram-directory'),
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          if (result.hasError)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text('Could not refresh. Showing the previous channels.'),
            ),
          for (final group in groups.entries) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
              child: Text(
                group.key.toUpperCase(),
                style: Theme.of(context).textTheme.labelMedium,
              ),
            ),
            for (final dialog in group.value)
              TelegramDialogTile(dialog: dialog),
          ],
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
