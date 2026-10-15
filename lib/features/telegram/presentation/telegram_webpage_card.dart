import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mfb_think_tank/app/theme.dart';
import 'package:mfb_think_tank/features/readers_digest/application/external_link_provider.dart';
import 'package:mfb_think_tank/features/readers_digest/presentation/widgets/open_external_link.dart';
import 'package:mfb_think_tank/features/telegram/data/telegram_paths.dart';
import 'package:mfb_think_tank/features/telegram/data/telegram_webpage.dart';
import 'package:mfb_think_tank/features/telegram/presentation/telegram_image.dart';

/// Server-provided link preview; only safe HTTP(S) destinations are tappable.
class TelegramWebpageCard extends ConsumerWidget {
  const TelegramWebpageCard({
    required this.webpage,
    required this.chatId,
    required this.messageId,
    super.key,
  });
  final TelegramWebpage webpage;
  final String chatId;
  final int messageId;
  @override
  Widget build(BuildContext context, WidgetRef ref) => Card(
    margin: const EdgeInsets.only(top: 12),
    color: AppTheme.raised,
    clipBehavior: Clip.antiAlias,
    child: InkWell(
      key: Key('telegram-link-$messageId'),
      onTap: parseHttpUrl(webpage.url) == null
          ? null
          : () => openExternalLink(context, ref, webpage.url),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (webpage.hasPhoto)
            TelegramImage(
              path: TelegramPaths.media(chatId, messageId, 'webpage'),
            ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (webpage.siteName case final site?)
                  Text(site, style: Theme.of(context).textTheme.labelSmall),
                Text(
                  webpage.title ?? webpage.displayUrl,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                if (webpage.description case final description?)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      description,
                      maxLines: 4,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                const SizedBox(height: 6),
                Text(
                  webpage.displayUrl,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}
