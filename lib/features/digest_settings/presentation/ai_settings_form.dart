import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mfb_think_tank/features/digest_settings/application/settings_action_provider.dart';
import 'package:mfb_think_tank/features/digest_settings/data/ai_provider_meta.dart';
import 'package:mfb_think_tank/features/digest_settings/data/ai_settings.dart';
import 'package:mfb_think_tank/features/digest_settings/data/me_profile.dart';
import 'package:mfb_think_tank/features/digest_settings/presentation/ai_settings_actions.dart';

/// Provider, model and key form. The server keeps one active configuration,
/// so switching providers always needs a replacement key.
class AiSettingsForm extends ConsumerStatefulWidget {
  const AiSettingsForm({required this.profile, super.key});

  final MeProfile profile;

  @override
  ConsumerState<AiSettingsForm> createState() => _AiSettingsFormState();
}

class _AiSettingsFormState extends ConsumerState<AiSettingsForm> {
  /// The three designed providers; a saved provider outside them is kept.
  static const _designed = ['anthropic', 'openai', 'gemini'];

  late String _providerId = widget.profile.llm?.provider ?? _designed.first;
  late final _model = TextEditingController(text: widget.profile.llm?.model);
  late final _baseUrl = TextEditingController(
    text: widget.profile.llm?.baseUrl,
  );
  final _key = TextEditingController();
  String? _validation;

  AiSettings? get _saved => widget.profile.llm;
  bool get _isSameProvider => _saved?.provider == _providerId;

  AiProviderMeta? get _meta =>
      widget.profile.providers.where((p) => p.id == _providerId).firstOrNull;

  @override
  void initState() {
    super.initState();
    Future(() {
      if (mounted) ref.read(settingsActionProvider.notifier).clearNotice();
    });
  }

  @override
  void dispose() {
    _model.dispose();
    _baseUrl.dispose();
    _key.dispose();
    super.dispose();
  }

  void _selectProvider(String? id) {
    if (id == null || id == _providerId) return;
    setState(() {
      _providerId = id;
      _validation = null;
      _model.text = _isSameProvider ? _saved?.model ?? '' : '';
      _baseUrl.text = _isSameProvider ? _saved?.baseUrl ?? '' : '';
      _key.clear();
    });
  }

  Future<void> _save() async {
    final meta = _meta;
    final key = _key.text.trim();
    final needsNewKey =
        (meta?.needsKey ?? true) && !(_isSameProvider && _saved!.hasKey);
    if (needsNewKey && key.isEmpty) {
      return setState(() => _validation = 'Enter an API key.');
    }
    if ((meta?.needsBaseUrl ?? false) && _baseUrl.text.trim().isEmpty) {
      return setState(() => _validation = 'Enter the base URL.');
    }
    setState(() => _validation = null);
    final saved = await ref
        .read(settingsActionProvider.notifier)
        .save(
          AiSettingsInput(
            provider: _providerId,
            model: _model.text.trim(),
            baseUrl: _baseUrl.text.trim(),
            // Null keeps the stored key for a same-provider update.
            apiKey: key.isEmpty ? null : key,
          ),
        );
    if (saved) _key.clear();
  }

  @override
  Widget build(BuildContext context) {
    final action = ref.watch(settingsActionProvider);
    final meta = _meta;
    final ids = {..._designed, if (_saved != null) _saved!.provider};
    final options = [
      for (final p in widget.profile.providers)
        if (ids.contains(p.id)) p,
    ]..sort((a, b) => _rank(a.id).compareTo(_rank(b.id)));
    final canEdit = widget.profile.byokEnabled && !action.isBusy;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!widget.profile.byokEnabled)
          const Text('Key storage is not enabled on this server.')
        else
          const Text('Your key is encrypted before it is stored.'),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          key: ValueKey(_providerId),
          initialValue: _providerId,
          decoration: const InputDecoration(labelText: 'Provider'),
          items: [
            for (final p in options)
              DropdownMenuItem(value: p.id, child: Text(p.label)),
          ],
          onChanged: canEdit ? _selectProvider : null,
        ),
        const SizedBox(height: 12),
        TextField(
          key: const Key('ai-model'),
          controller: _model,
          decoration: InputDecoration(
            labelText: 'Model',
            hintText: meta?.defaultModel,
          ),
        ),
        if (meta?.needsBaseUrl ?? false) ...[
          const SizedBox(height: 12),
          TextField(
            key: const Key('ai-base-url'),
            controller: _baseUrl,
            keyboardType: TextInputType.url,
            decoration: const InputDecoration(labelText: 'Base URL'),
          ),
        ],
        if (meta?.needsKey ?? true) ...[
          const SizedBox(height: 12),
          TextField(
            key: const Key('ai-key'),
            controller: _key,
            obscureText: true,
            autocorrect: false,
            enableSuggestions: false,
            decoration: InputDecoration(
              labelText: 'API key',
              helperText: _isSameProvider && _saved!.hasKey
                  ? 'Saved ${_saved!.keyHint ?? ''} · leave blank to keep'
                  : null,
            ),
          ),
        ],
        if (_validation != null || action.notice != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              _validation ?? action.notice!,
              key: const Key('ai-notice'),
            ),
          ),
        const SizedBox(height: 12),
        AiSettingsActions(
          canEdit: canEdit,
          hasSavedKey: widget.profile.hasLlm,
          isUpdate: _isSameProvider,
          onSave: _save,
        ),
      ],
    );
  }

  int _rank(String id) {
    final index = _designed.indexOf(id);
    return index < 0 ? _designed.length : index;
  }
}
