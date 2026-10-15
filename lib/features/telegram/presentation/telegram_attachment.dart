import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mfb_think_tank/app/destination_scope.dart';
import 'package:mfb_think_tank/core/playback/playback_request.dart';
import 'package:mfb_think_tank/features/live_media/presentation/stream_player.dart';
import 'package:mfb_think_tank/features/telegram/application/telegram_playback_provider.dart';
import 'package:mfb_think_tank/features/telegram/application/telegram_providers.dart';
import 'package:mfb_think_tank/features/telegram/data/telegram_media.dart';
import 'package:mfb_think_tank/features/telegram/data/telegram_paths.dart';
import 'package:mfb_think_tank/features/telegram/presentation/telegram_image.dart';
import 'package:mfb_think_tank/features/telegram/presentation/telegram_photo_screen.dart';

/// Private attachment previews; audio/video are fetched only after a play tap.
class TelegramAttachment extends ConsumerWidget {
  const TelegramAttachment({
    required this.chatId,
    required this.messageId,
    required this.media,
    super.key,
  });
  final String chatId;
  final int messageId;
  final TelegramMedia media;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (media.kind == 'photo') {
      return InkWell(
        key: Key('telegram-photo-$messageId'),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => TelegramPhotoScreen(
              path: TelegramPaths.media(chatId, messageId, 'full'),
            ),
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: TelegramImage(
            path: TelegramPaths.media(chatId, messageId, 'photo'),
          ),
        ),
      );
    }
    final path = TelegramPaths.media(chatId, messageId, 'file');
    final isPlaying = ref.watch(telegramPlaybackProvider) == path;
    if (media.canPlay && isPlaying) {
      final repository = ref.watch(telegramRepositoryProvider);
      return StreamPlayer(
        key: ValueKey(path),
        isActive: DestinationScope.isActive(context, 3),
        request: PlaybackRequest(
          uri: repository.mediaUri(path),
          title: 'Telegram ${media.kind}',
          isAudio: media.kind == 'audio',
          volume: 1,
          headers: (force) => repository.mediaHeaders(forceRefresh: force),
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (media.kind == 'video')
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: TelegramImage(
              path: TelegramPaths.media(chatId, messageId, 'thumb'),
            ),
          ),
        if (media.canPlay)
          TextButton.icon(
            key: Key('telegram-play-$messageId'),
            onPressed: () =>
                ref.read(telegramPlaybackProvider.notifier).play(path),
            icon: const Icon(Icons.play_circle_outline),
            label: Text('Play ${media.kind} · ${media.sizeLabel}'),
          )
        else
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(
              '${media.kind} ${media.sizeLabel}${media.isTooLarge ? ' · Too large to stream' : ' · Preview unavailable'}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
      ],
    );
  }
}
