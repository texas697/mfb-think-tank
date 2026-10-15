import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mfb_think_tank/app/router.dart';
import 'package:mfb_think_tank/features/auth/presentation/widgets/verify_email_banner.dart';
import 'package:mfb_think_tank/features/readers_digest/application/digest_feed_provider.dart';
import 'package:mfb_think_tank/features/readers_digest/application/digest_query_provider.dart';
import 'package:mfb_think_tank/features/readers_digest/application/search_debounce.dart';
import 'package:mfb_think_tank/features/readers_digest/data/digest_query.dart';
import 'package:mfb_think_tank/features/readers_digest/presentation/digest_theme.dart';
import 'package:mfb_think_tank/features/readers_digest/presentation/widgets/digest_controls.dart';
import 'package:mfb_think_tank/features/readers_digest/presentation/widgets/digest_feed_body.dart';
import 'package:mfb_think_tank/features/readers_digest/presentation/widgets/digest_header.dart';

/// Signed-in landing screen: the MFB Think Tank library for [query], which
/// comes from the route's `filter`, `topic` and `q` parameters.
class DigestScreen extends ConsumerStatefulWidget {
  const DigestScreen({required this.query, super.key});

  final DigestQuery query;

  @override
  ConsumerState<DigestScreen> createState() => _DigestScreenState();
}

class _DigestScreenState extends ConsumerState<DigestScreen> {
  late final TextEditingController _search = TextEditingController(
    text: widget.query.q,
  );
  late final SearchDebounce _debounce = SearchDebounce(
    onDebounce: (text) => _go(widget.query.copyWith(q: text), replace: true),
  );

  @override
  void initState() {
    super.initState();
    _sync();
  }

  @override
  void didUpdateWidget(DigestScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.query == widget.query) return;
    if (oldWidget.query.q != widget.query.q &&
        _search.text.trim() != widget.query.q) {
      _search.text = widget.query.q;
    }
    _sync();
  }

  @override
  void dispose() {
    _debounce.dispose();
    _search.dispose();
    super.dispose();
  }

  // Providers cannot be modified while the widget tree builds. A post-frame
  // callback (not a zero-delay Future) keeps the sync inside the frame
  // pipeline, so the resulting rebuild is scheduled deterministically.
  void _sync() => WidgetsBinding.instance.addPostFrameCallback((_) {
    if (!mounted) return;
    ref.read(digestQueryProvider.notifier).sync(widget.query);
  });

  void _go(DigestQuery next, {bool replace = false}) {
    if (!mounted) return;
    // A debounced replace must not swap out a reader pushed over this screen.
    if (replace &&
        (!(ModalRoute.of(context)?.isCurrent ?? true) ||
            GoRouter.of(context).state.uri.path != AppRoutes.home)) {
      return;
    }
    final params = {
      if (next.filter != DigestQuery.filterAll) 'filter': next.filter,
      if (next.hasTopic) 'topic': next.topic,
      if (next.hasSearch) 'q': next.q,
    };
    final location = Uri(
      path: AppRoutes.home,
      queryParameters: params.isEmpty ? null : params,
    ).toString();
    replace ? context.replace(location) : context.go(location);
  }

  void _clearFilters() {
    _debounce.cancel();
    _search.clear();
    _go(const DigestQuery());
  }

  void _onFilter(String filter) => _go(widget.query.copyWith(filter: filter));

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: DigestTheme.data,
      child: Scaffold(
        body: SafeArea(
          child: RefreshIndicator(
            onRefresh: () => ref.read(digestFeedProvider.notifier).refresh(),
            child: CustomScrollView(
              slivers: [
                const SliverToBoxAdapter(child: DigestHeader()),
                const SliverToBoxAdapter(child: VerifyEmailBanner()),
                DigestControls(
                  searchController: _search,
                  onSearchChanged: _debounce.schedule,
                  selectedFilter: widget.query.filter,
                  onFilterSelected: _onFilter,
                ),
                DigestFeedBody(
                  query: widget.query,
                  onTopic: (topic) => _go(widget.query.copyWith(topic: topic)),
                  onClearFilters: _clearFilters,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
