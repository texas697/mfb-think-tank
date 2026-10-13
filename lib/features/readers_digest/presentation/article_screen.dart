import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mfb_think_tank/app/router.dart';
import 'package:mfb_think_tank/features/readers_digest/application/article_detail_provider.dart';
import 'package:mfb_think_tank/features/readers_digest/data/digest_failure.dart';
import 'package:mfb_think_tank/features/readers_digest/presentation/digest_theme.dart';
import 'package:mfb_think_tank/features/readers_digest/presentation/widgets/feed_message.dart';
import 'package:mfb_think_tank/features/readers_digest/presentation/widgets/open_external_link.dart';
import 'package:mfb_think_tank/features/readers_digest/presentation/widgets/rating_buttons.dart';
import 'package:mfb_think_tank/features/readers_digest/presentation/widgets/reader_header.dart';
import 'package:mfb_think_tank/features/readers_digest/presentation/widgets/research_section.dart';
import 'package:mfb_think_tank/features/readers_digest/presentation/widgets/writeup_section.dart';

/// Full-screen reader for one article.
class ArticleScreen extends ConsumerWidget {
  const ArticleScreen({required this.id, super.key});

  final String id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final article = ref.watch(articleDetailProvider(id));
    final detail = article.value;
    return Theme(
      data: DigestTheme.data,
      child: Scaffold(
        appBar: AppBar(
          leading: BackButton(
            key: const Key('reader-back'),
            // A cold deep link has nothing to pop to.
            onPressed: () =>
                context.canPop() ? context.pop() : context.go(AppRoutes.home),
          ),
          actions: [
            RatingButtons(id: id),
            IconButton(
              key: const Key('reader-original'),
              tooltip: 'Open original',
              icon: const Icon(Icons.open_in_new),
              onPressed: detail == null
                  ? null
                  : () => openExternalLink(context, ref, detail.card.url),
            ),
          ],
        ),
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: detail == null
                  ? _Placeholder(
                      error: article.error,
                      onRetry: () => ref.invalidate(articleDetailProvider(id)),
                    )
                  : ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        ReaderHeader(detail: detail),
                        const SizedBox(height: 16),
                        WriteupSection(detail: detail),
                        const SizedBox(height: 24),
                        ResearchSection(detail: detail),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Placeholder extends StatelessWidget {
  const _Placeholder({required this.error, required this.onRetry});

  final Object? error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    if (error == null) {
      return const Center(child: CircularProgressIndicator());
    }
    final isMissing = error is DigestNotFound;
    return FeedMessage(
      title: isMissing ? 'Article not found' : 'Could not load the article',
      body: error is DigestFailure ? (error! as DigestFailure).message : null,
      actionLabel: isMissing ? null : 'Retry',
      onAction: onRetry,
    );
  }
}
