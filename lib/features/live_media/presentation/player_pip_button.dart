import 'package:better_player_plus/better_player_plus.dart';
import 'package:material_ui/material_ui.dart';

/// Exposes supported-device PiP independently of the player's overflow menu.
class PlayerPipButton extends StatefulWidget {
  const PlayerPipButton({
    required this.controller,
    required this.playerKey,
    super.key,
  });
  final BetterPlayerController controller;
  final GlobalKey playerKey;
  @override
  State<PlayerPipButton> createState() => _PlayerPipButtonState();
}

class _PlayerPipButtonState extends State<PlayerPipButton> {
  late Future<bool> _supported;
  @override
  void initState() {
    super.initState();
    _supported = _supportsPip();
  }

  @override
  void didUpdateWidget(PlayerPipButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      _supported = _supportsPip();
    }
  }

  Future<bool> _supportsPip() async {
    final video = widget.controller.videoPlayerController;
    return video != null && await video.isPictureInPictureSupported() == true;
  }

  Future<void> _enter() async {
    try {
      await widget.controller.enablePictureInPicture(widget.playerKey);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Picture-in-picture is unavailable.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<bool>(
    future: _supported,
    builder: (context, result) => result.data != true
        ? const SizedBox.shrink()
        : IconButton.filledTonal(
            key: const Key('player-pip'),
            tooltip: 'Picture-in-picture',
            onPressed: _enter,
            icon: const Icon(Icons.picture_in_picture_outlined),
          ),
  );
}
