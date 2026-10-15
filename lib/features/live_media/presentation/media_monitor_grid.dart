import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mfb_think_tank/core/playback/playback_request.dart';
import 'package:mfb_think_tank/features/live_media/data/media_channels.dart';
import 'package:mfb_think_tank/features/live_media/presentation/stream_player.dart';
import 'package:mfb_think_tank/features/readers_digest/application/app_lifecycle_provider.dart';

/// Four deliberately muted broadcasters, released when the monitor is hidden.
class MediaMonitorGrid extends ConsumerWidget {
  const MediaMonitorGrid({required this.isActive, super.key});
  final bool isActive;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isVisible =
        isActive &&
        ref.watch(appLifecycleProvider) == AppLifecycleState.resumed;
    if (!isVisible) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 24),
        Text(
          'Monitor · all muted',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 12),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.25,
          children: [
            for (final channel in mediaChannels.take(4))
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  StreamPlayer(
                    key: Key('grid-${channel.id}'),
                    request: PlaybackRequest(
                      uri: Uri.parse(channel.hls),
                      title: channel.name,
                      isLive: true,
                      isPreview: true,
                      volume: 0,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Flexible(
                    child: Text(
                      channel.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.labelMedium,
                    ),
                  ),
                ],
              ),
          ],
        ),
      ],
    );
  }
}
