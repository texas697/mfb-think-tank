import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mfb_think_tank/features/feedback/application/feedback_action_provider.dart';
import 'package:mfb_think_tank/features/feedback/data/feedback_report.dart';
import 'package:mfb_think_tank/features/feedback/presentation/feedback_category_chips.dart';

/// Opens the feedback sheet. The current route is recorded with the report.
Future<void> showFeedbackSheet(BuildContext context) {
  final page = GoRouter.maybeOf(context)?.state.uri.toString();
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => FeedbackSheet(page: page),
  );
}

/// Category chips, a description field and a Send button.
class FeedbackSheet extends ConsumerStatefulWidget {
  const FeedbackSheet({this.page, super.key});

  final String? page;

  @override
  ConsumerState<FeedbackSheet> createState() => _FeedbackSheetState();
}

class _FeedbackSheetState extends ConsumerState<FeedbackSheet> {
  static const _minLength = 3;

  var _category = FeedbackCategory.bug;
  final _description = TextEditingController();
  String? _validation;

  @override
  void initState() {
    super.initState();
    Future(() {
      if (mounted) ref.read(feedbackActionProvider.notifier).clearNotice();
    });
  }

  @override
  void dispose() {
    _description.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _description.text.trim();
    if (text.length < _minLength) {
      return setState(() => _validation = 'Tell us a bit more.');
    }
    setState(() => _validation = null);
    final messenger = ScaffoldMessenger.maybeOf(context);
    final navigator = Navigator.of(context);
    final sent = await ref
        .read(feedbackActionProvider.notifier)
        .send(
          FeedbackReport(
            category: _category,
            description: text,
            page: widget.page,
          ),
        );
    if (!sent || !mounted) return;
    navigator.pop();
    messenger?.showSnackBar(
      const SnackBar(content: Text('Thanks, your feedback was sent.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final action = ref.watch(feedbackActionProvider);
    final notice = _validation ?? action.notice;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        16,
        16,
        16,
        16 + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Send feedback', style: theme.textTheme.titleLarge),
            const SizedBox(height: 4),
            Text(
              'Found a bug, a wrong fact, or have an idea? It goes straight '
              'to the team.',
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            FeedbackCategoryChips(
              selected: _category,
              onSelected: action.isBusy
                  ? null
                  : (c) => setState(() => _category = c),
            ),
            const SizedBox(height: 12),
            TextField(
              key: const Key('feedback-description'),
              controller: _description,
              enabled: !action.isBusy,
              minLines: 3,
              maxLines: 6,
              autofocus: true,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'What happened?',
                alignLabelWithHint: true,
              ),
            ),
            if (notice != null) ...[
              const SizedBox(height: 8),
              Text(
                notice,
                key: const Key('feedback-notice'),
                style: TextStyle(color: theme.colorScheme.error),
              ),
            ],
            const SizedBox(height: 12),
            FilledButton(
              key: const Key('feedback-send'),
              onPressed: action.isBusy ? null : _send,
              child: Text(action.isBusy ? 'Sending…' : 'Send'),
            ),
            TextButton(
              key: const Key('feedback-cancel'),
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
          ],
        ),
      ),
    );
  }
}
