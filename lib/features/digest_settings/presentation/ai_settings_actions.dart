import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mfb_think_tank/features/digest_settings/application/settings_action_provider.dart';

/// Save/update, test and remove buttons for the AI settings form.
class AiSettingsActions extends ConsumerWidget {
  const AiSettingsActions({
    required this.canEdit,
    required this.hasSavedKey,
    required this.isUpdate,
    required this.onSave,
    super.key,
  });

  final bool canEdit;
  final bool hasSavedKey;
  final bool isUpdate;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final actions = ref.read(settingsActionProvider.notifier);
    return Column(
      children: [
        FilledButton(
          key: const Key('ai-save'),
          onPressed: canEdit ? onSave : null,
          child: Text(isUpdate ? 'Update' : 'Save'),
        ),
        if (hasSavedKey) ...[
          const SizedBox(height: 8),
          OutlinedButton(
            key: const Key('ai-test'),
            onPressed: canEdit ? actions.test : null,
            child: const Text('Test saved key'),
          ),
          TextButton(
            key: const Key('ai-remove'),
            onPressed: canEdit ? actions.remove : null,
            child: const Text('Remove key'),
          ),
        ],
      ],
    );
  }
}
