import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mfb_think_tank/features/digest_settings/presentation/account_sheet.dart';
import 'package:mfb_think_tank/features/readers_digest/application/article_action_provider.dart';
import 'package:mfb_think_tank/features/readers_digest/data/article_detail.dart';
import 'package:mfb_think_tank/features/readers_digest/presentation/digest_colors.dart';
import 'package:mfb_think_tank/features/readers_digest/presentation/widgets/digest_markdown.dart';

/// The AI write-up, or the real excerpt with a generate action.
class WriteupSection extends ConsumerWidget {
  const WriteupSection({required this.detail, super.key});

  final ArticleDetail detail;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final muted = DigestColors.of(context).muted;
    final summary = detail.summaryMd?.trim() ?? '';
    if (summary.isNotEmpty) {
      final model = detail.summaryModel;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (model != null && model.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                'Written by $model',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: muted,
                  fontFamily: 'GeistMono',
                ),
              ),
            ),
          DigestMarkdown(data: summary),
        ],
      );
    }
    final action = ref.watch(articleActionProvider(detail.id));
    final excerpt = detail.textPreview.isNotEmpty
        ? detail.textPreview
        : detail.card.description;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (excerpt.isNotEmpty) Text(excerpt, style: theme.textTheme.bodyLarge),
        if (!detail.extracted)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              'Only part of this article could be read. Open the original for '
              'the full text.',
              style: theme.textTheme.bodySmall?.copyWith(color: muted),
            ),
          ),
        const SizedBox(height: 16),
        FilledButton(
          key: const Key('writeup-generate'),
          onPressed: action.isSummarizing
              ? null
              : () => ref
                    .read(articleActionProvider(detail.id).notifier)
                    .summarize(),
          child: Text(action.isSummarizing ? 'Writing…' : 'Write this up'),
        ),
        if (action.error != null) ...[
          const SizedBox(height: 8),
          Text(
            action.error!,
            key: const Key('writeup-error'),
            style: TextStyle(color: DigestColors.of(context).danger),
          ),
          TextButton(
            key: const Key('writeup-ai-settings'),
            onPressed: () => showAccountSheet(context),
            child: const Text('AI settings'),
          ),
        ],
      ],
    );
  }
}
