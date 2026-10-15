import 'package:flutter/gestures.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mfb_think_tank/features/readers_digest/presentation/widgets/open_external_link.dart';

/// Selectable plain text with safe links and original-language directionality.
class TelegramText extends ConsumerStatefulWidget {
  const TelegramText({required this.text, super.key});
  final String text;
  @override
  ConsumerState<TelegramText> createState() => _TelegramTextState();
}

class _TelegramTextState extends ConsumerState<TelegramText> {
  final _recognizers = <TapGestureRecognizer>[];
  final _spans = <TextSpan>[];
  @override
  void initState() {
    super.initState();
    _parse();
  }

  @override
  void didUpdateWidget(TelegramText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.text != widget.text) _parse();
  }

  void _parse() {
    for (final recognizer in _recognizers) {
      recognizer.dispose();
    }
    _recognizers.clear();
    _spans.clear();
    var offset = 0;
    for (final match in RegExp(r'https?://[^\s<>]+').allMatches(widget.text)) {
      _spans.add(TextSpan(text: widget.text.substring(offset, match.start)));
      final url = match.group(0)!.replaceFirst(RegExp(r'[.,;!?\)\]}]+$'), '');
      final recognizer = TapGestureRecognizer()
        ..onTap = () => openExternalLink(context, ref, url);
      _recognizers.add(recognizer);
      _spans.add(
        TextSpan(
          text: url,
          recognizer: recognizer,
          style: const TextStyle(decoration: TextDecoration.underline),
        ),
      );
      offset = match.start + url.length;
    }
    _spans.add(TextSpan(text: widget.text.substring(offset)));
  }

  @override
  void dispose() {
    for (final recognizer in _recognizers) {
      recognizer.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final strong = RegExp(r'[A-Za-z\u0590-\u08ff]')
        .firstMatch(widget.text)
        ?.group(0);
    final isRtl = strong != null && strong.codeUnitAt(0) >= 0x0590;
    return SelectableText.rich(
      TextSpan(children: _spans),
      textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
      style: Theme.of(context).textTheme.bodyLarge?.copyWith(height: 1.5),
    );
  }
}
