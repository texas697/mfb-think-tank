import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mfb_think_tank/features/digest_settings/application/settings_action_provider.dart';

enum _Action { save, test, remove }

/// Notice line plus save/update, test and remove buttons for the AI settings
/// form. The button whose action is in flight shows a progress label.
class AiSettingsActions extends ConsumerStatefulWidget {
  const AiSettingsActions({
    required this.canEdit,
    this.notice,
    required this.isBusy,
    required this.hasSaved,
    required this.isUpdate,
    required this.onSave,
    super.key,
  });

  /// Validation, success or error text shown above the buttons.
  final String? notice;
  final bool canEdit;
  final bool isBusy;

  /// True when the server holds a configuration, with or without a key.
  final bool hasSaved;
  final bool isUpdate;
  final VoidCallback onSave;

  @override
  ConsumerState<AiSettingsActions> createState() => _AiSettingsActionsState();
}

class _AiSettingsActionsState extends ConsumerState<AiSettingsActions> {
  // Actions run serially, so the last tapped one is the busy one.
  _Action? _active;

  VoidCallback? _tap(_Action action, VoidCallback run) {
    if (!widget.canEdit) return null;
    return () {
      setState(() => _active = action);
      run();
    };
  }

  String _label(_Action action, String idle, String busy) =>
      widget.isBusy && _active == action ? busy : idle;

  @override
  Widget build(BuildContext context) {
    final actions = ref.read(settingsActionProvider.notifier);
    return Column(
      children: [
        if (widget.notice case final notice?)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            // Full width so the notice starts at the form's left edge.
            child: SizedBox(
              width: double.infinity,
              child: Text(notice, key: const Key('ai-notice')),
            ),
          ),
        FilledButton(
          key: const Key('ai-save'),
          onPressed: _tap(_Action.save, widget.onSave),
          child: Text(
            _label(
              _Action.save,
              widget.isUpdate ? 'Update' : 'Save',
              'Saving…',
            ),
          ),
        ),
        if (widget.hasSaved) ...[
          const SizedBox(height: 8),
          OutlinedButton(
            key: const Key('ai-test'),
            onPressed: _tap(_Action.test, actions.test),
            child: Text(
              _label(_Action.test, 'Test saved settings', 'Testing…'),
            ),
          ),
          TextButton(
            key: const Key('ai-remove'),
            onPressed: _tap(_Action.remove, actions.remove),
            child: Text(_label(_Action.remove, 'Remove settings', 'Removing…')),
          ),
        ],
      ],
    );
  }
}
