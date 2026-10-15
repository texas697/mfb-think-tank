import 'package:material_ui/material_ui.dart';
import 'package:mfb_think_tank/features/telegram/presentation/telegram_image.dart';

/// Full-size private photo, loaded with authentication and pinch zoom.
class TelegramPhotoScreen extends StatelessWidget {
  const TelegramPhotoScreen({required this.path, super.key});
  final String path;
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Photo')),
    body: SafeArea(
      child: InteractiveViewer(
        minScale: 1,
        maxScale: 5,
        child: Center(
          child: TelegramImage(
            path: path,
            fit: BoxFit.contain,
            height: MediaQuery.sizeOf(context).height * .75,
            label: 'Full-size Telegram photo',
          ),
        ),
      ),
    ),
  );
}
