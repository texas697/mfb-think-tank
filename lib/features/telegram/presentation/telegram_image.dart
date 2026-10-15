import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mfb_think_tank/app/theme.dart';
import 'package:mfb_think_tank/features/readers_digest/application/digest_api_providers.dart';
import 'package:mfb_think_tank/features/telegram/application/telegram_providers.dart';

/// Account-scoped private image with eviction when removed from the screen.
class TelegramImage extends ConsumerStatefulWidget {
  const TelegramImage({
    required this.path,
    this.height = 180,
    this.fit = BoxFit.cover,
    this.label = 'Telegram image',
    super.key,
  });
  final String path;
  final double height;
  final BoxFit fit;
  final String label;
  @override
  ConsumerState<TelegramImage> createState() => _TelegramImageState();
}

class _TelegramImageState extends ConsumerState<TelegramImage> {
  ImageProvider<Object>? _image;
  Uint8List? _bytes;
  @override
  void dispose() {
    _image?.evict();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final uid = ref.watch(currentUidProvider);
    final result = ref.watch(telegramImageProvider((uid, widget.path)));
    final bytes = result.isLoading ? null : result.value;
    if (bytes != _bytes) {
      _image?.evict();
      _bytes = bytes;
      final bound = (widget.height * MediaQuery.devicePixelRatioOf(context) * 2)
          .round()
          .clamp(128, 2048);
      _image = bytes == null
          ? null
          : ResizeImage(
              MemoryImage(bytes),
              width: bound,
              height: bound,
              policy: ResizeImagePolicy.fit,
            );
    }
    return SizedBox(
      height: widget.height,
      width: double.infinity,
      child: _image == null
          ? ColoredBox(
              color: AppTheme.raised,
              child: Center(
                child: result.hasError
                    ? IconButton(
                        key: Key('image-retry-${widget.path}'),
                        tooltip: 'Retry image',
                        onPressed: () => ref.invalidate(
                          telegramImageProvider((
                            ref.read(currentUidProvider),
                            widget.path,
                          )),
                        ),
                        icon: const Icon(Icons.broken_image_outlined),
                      )
                    : const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
              ),
            )
          : Image(
              image: _image!,
              fit: widget.fit,
              semanticLabel: widget.label,
              errorBuilder: (_, _, _) =>
                  const Center(child: Icon(Icons.broken_image_outlined)),
            ),
    );
  }
}
