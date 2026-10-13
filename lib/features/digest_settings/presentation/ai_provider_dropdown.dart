import 'package:material_ui/material_ui.dart';
import 'package:mfb_think_tank/features/digest_settings/data/ai_provider_meta.dart';

/// Picks the AI provider. Shows the three designed providers in a fixed
/// order, plus [savedId] when the saved provider is outside them.
class AiProviderDropdown extends StatelessWidget {
  const AiProviderDropdown({
    required this.providers,
    required this.selectedId,
    required this.onChanged,
    this.savedId,
    super.key,
  });

  /// The three designed providers; a saved provider outside them is kept.
  static const designed = ['anthropic', 'openai', 'gemini'];

  final List<AiProviderMeta> providers;
  final String selectedId;
  final String? savedId;

  /// Null disables the control.
  final ValueChanged<String?>? onChanged;

  List<AiProviderMeta> get _options {
    final ids = {...designed, ?savedId};
    return [
      for (final p in providers)
        if (ids.contains(p.id)) p,
    ]..sort((a, b) => _rank(a.id).compareTo(_rank(b.id)));
  }

  static int _rank(String id) {
    final index = designed.indexOf(id);
    return index < 0 ? designed.length : index;
  }

  @override
  Widget build(BuildContext context) {
    // Rebuilt from scratch on a change so the field reflects the selection.
    return KeyedSubtree(
      key: ValueKey(selectedId),
      child: DropdownButtonFormField<String>(
        key: const Key('ai-provider'),
        initialValue: selectedId,
        decoration: const InputDecoration(labelText: 'Provider'),
        items: [
          for (final p in _options)
            DropdownMenuItem(
              key: Key('ai-provider-${p.id}'),
              value: p.id,
              child: Text(p.label),
            ),
        ],
        onChanged: onChanged,
      ),
    );
  }
}
