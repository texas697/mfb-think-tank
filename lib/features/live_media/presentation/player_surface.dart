import 'package:better_player_plus/better_player_plus.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mfb_think_tank/app/theme.dart';
import 'package:mfb_think_tank/core/playback/playback_engine.dart';
import 'package:mfb_think_tank/core/playback/playback_request.dart';
import 'package:mfb_think_tank/features/live_media/presentation/player_error.dart';
import 'package:mfb_think_tank/features/live_media/presentation/player_pip_button.dart';

/// Common visual surface for native video, audio and muted monitors.
class PlayerSurface extends StatelessWidget {
  const PlayerSurface({
    required this.engine,
    required this.request,
    required this.isActive,
    required this.playerKey,
    required this.onRetry,
    super.key,
  });
  final PlaybackEngine? engine;
  final PlaybackRequest request;
  final bool isActive;
  final GlobalKey playerKey;
  final VoidCallback onRetry;
  @override
  Widget build(BuildContext context) {
    final handle = engine?.viewHandle;
    if (handle is BetterPlayerController) {
      handle.setBetterPlayerGlobalKey(playerKey);
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: ColoredBox(
        color: AppTheme.surface,
        child: AspectRatio(
          aspectRatio: request.isAudio ? 3 : 16 / 9,
          child: engine?.error != null
              ? PlayerError(
                  message: engine!.error!,
                  isPreview: request.isPreview,
                  onRetry: onRetry,
                )
              : Stack(
                  fit: StackFit.expand,
                  children: [
                    if (handle is BetterPlayerController)
                      BetterPlayer(key: playerKey, controller: handle),
                    if (engine?.isReady != true && isActive)
                      const Center(child: CircularProgressIndicator()),
                    if (engine?.isReady == true && handle == null)
                      Center(child: Text(request.title)),
                    if (engine?.isReady == true &&
                        handle is BetterPlayerController &&
                        !request.isPreview &&
                        !request.isAudio)
                      Positioned(
                        top: 4,
                        right: 4,
                        child: PlayerPipButton(
                          controller: handle,
                          playerKey: playerKey,
                        ),
                      ),
                  ],
                ),
        ),
      ),
    );
  }
}
