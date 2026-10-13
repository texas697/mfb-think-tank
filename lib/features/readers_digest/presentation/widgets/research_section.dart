import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mfb_think_tank/features/readers_digest/application/research_provider.dart';
import 'package:mfb_think_tank/features/readers_digest/data/article_detail.dart';
import 'package:mfb_think_tank/features/readers_digest/data/research_result.dart';
import 'package:mfb_think_tank/features/readers_digest/presentation/digest_colors.dart';
import 'package:mfb_think_tank/features/readers_digest/presentation/relative_time.dart';
import 'package:mfb_think_tank/features/readers_digest/presentation/widgets/digest_markdown.dart';
import 'package:mfb_think_tank/features/readers_digest/presentation/widgets/open_external_link.dart';

/// Cited research: start, progress, result with sources, error and retry.
class ResearchSection extends ConsumerWidget {
  const ResearchSection({required this.detail, super.key});

  final ArticleDetail detail;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colors = DigestColors.of(context);
    final controller = ref.watch(researchProvider(detail.id));
    final result = controller.result.isNone
        ? detail.research
        : controller.result;
    final notifier = ref.read(researchProvider(detail.id).notifier);
    final isBusy = controller.isStarting || result.isRunning;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Research', style: theme.textTheme.titleMedium),
        const SizedBox(height: 8),
        if (result.isRunning) ...[
          LinearProgressIndicator(
            key: const Key('research-progress'),
            value: result.progress == null ? null : result.progress! / 100,
          ),
          const SizedBox(height: 8),
          Text(
            'Researching… ${result.stage ?? 'searching'}',
            style: theme.textTheme.bodySmall?.copyWith(color: colors.muted),
          ),
        ],
        if (result.isError)
          Text(
            result.error ?? 'Research failed.',
            key: const Key('research-error'),
            style: TextStyle(color: colors.danger),
          ),
        if (result.isDone) ...[
          DigestMarkdown(data: result.markdown ?? ''),
          for (final (index, source) in result.sources.indexed)
            ListTile(
              key: Key('research-source-$index'),
              contentPadding: EdgeInsets.zero,
              title: Text(source.title.isEmpty ? source.url : source.title),
              subtitle: Text(source.domain ?? ''),
              trailing: const Icon(Icons.open_in_new, size: 18),
              onTap: () => openExternalLink(context, ref, source.url),
            ),
          Text(_footer(result), style: theme.textTheme.labelSmall),
        ],
        if (controller.error != null)
          Text(controller.error!, style: TextStyle(color: colors.danger)),
        const SizedBox(height: 8),
        OutlinedButton(
          key: const Key('research-start'),
          onPressed: isBusy ? null : notifier.start,
          child: Text(
            result.isDone
                ? 'Regenerate research'
                : result.isError
                ? 'Retry research'
                : 'Research this',
          ),
        ),
      ],
    );
  }

  String _footer(ResearchResult result) => [
    if (result.model != null) result.model!,
    if (result.completedAt != null) relativeTime(result.completedAt),
  ].join(' · ');
}
