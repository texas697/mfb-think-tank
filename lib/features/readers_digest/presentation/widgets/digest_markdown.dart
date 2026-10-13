import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mfb_think_tank/features/readers_digest/presentation/digest_colors.dart';
import 'package:mfb_think_tank/features/readers_digest/presentation/widgets/open_external_link.dart';

/// Selectable Markdown styled for the reader; links open externally.
class DigestMarkdown extends ConsumerWidget {
  const DigestMarkdown({required this.data, super.key});

  final String data;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colors = DigestColors.of(context);
    final body = theme.textTheme.bodyLarge?.copyWith(
      height: 1.5,
      color: colors.text,
    );
    // Built explicitly: the package's `fromTheme` takes the stock Material
    // ThemeData, which differs from material_ui's.
    return MarkdownBody(
      data: data,
      selectable: true,
      onTapLink: (text, href, title) => openExternalLink(context, ref, href),
      styleSheet: MarkdownStyleSheet(
        p: body,
        h1: theme.textTheme.titleLarge?.copyWith(color: colors.text),
        h2: theme.textTheme.titleMedium?.copyWith(color: colors.accent),
        h3: theme.textTheme.titleSmall?.copyWith(color: colors.text),
        strong: body?.copyWith(fontWeight: FontWeight.w700),
        em: body?.copyWith(fontStyle: FontStyle.italic),
        a: body?.copyWith(color: colors.accent),
        listBullet: body,
        code: body?.copyWith(fontFamily: 'GeistMono', fontSize: 14),
        blockquote: body?.copyWith(color: colors.muted),
        blockquoteDecoration: BoxDecoration(
          border: Border(left: BorderSide(color: colors.border, width: 3)),
        ),
      ),
    );
  }
}
