import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mfb_think_tank/features/digest_settings/application/settings_action_provider.dart';
import 'package:mfb_think_tank/features/digest_settings/data/ai_provider_meta.dart';
import 'package:mfb_think_tank/features/digest_settings/data/ai_settings.dart';
import 'package:mfb_think_tank/features/digest_settings/data/me_profile.dart';
import 'package:mfb_think_tank/features/digest_settings/presentation/ai_provider_dropdown.dart';
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
  AiSettings? get _saved => widget.profile.llm;

  late String _providerId =
      _saved?.provider ?? AiProviderDropdown.designed.first;
  late final _model = TextEditingController(text: _saved?.model);
  late final _baseUrl = TextEditingController(text: _saved?.baseUrl);
  final _key = TextEditingController();
  String? _validation;

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
        (meta?.isKeyRequired ?? true) && !(_isSameProvider && _saved!.hasKey);
    if (needsNewKey && key.isEmpty) {
      return setState(() => _validation = 'Enter an API key.');
    }
    if ((meta?.isBaseUrlRequired ?? false) && _baseUrl.text.trim().isEmpty) {
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
    final canEdit = widget.profile.isByokEnabled && !action.isBusy;
    final canType = !action.isBusy;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!widget.profile.isByokEnabled)
          const Text('Key storage is not enabled on this server.')
        else
          const Text('Your key is encrypted before it is stored.'),
        const SizedBox(height: 12),
        AiProviderDropdown(
          providers: widget.profile.providers,
          selectedId: _providerId,
          savedId: _saved?.provider,
          onChanged: canEdit ? _selectProvider : null,
        ),
        const SizedBox(height: 12),
        TextField(
          key: const Key('ai-model'),
          controller: _model,
          enabled: canType,
          decoration: InputDecoration(
            labelText: 'Model',
            hintText: meta?.defaultModel,
          ),
        ),
        if (meta?.isBaseUrlRequired ?? false) ...[
          const SizedBox(height: 12),
          TextField(
            key: const Key('ai-base-url'),
            controller: _baseUrl,
            enabled: canType,
            keyboardType: TextInputType.url,
            decoration: const InputDecoration(labelText: 'Base URL'),
          ),
        ],
        if (meta?.isKeyRequired ?? true) ...[
          const SizedBox(height: 12),
          TextField(
            key: const Key('ai-key'),
            controller: _key,
            enabled: canType,
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
        const SizedBox(height: 12),
        AiSettingsActions(
          notice: _validation ?? action.notice,
          canEdit: canEdit,
          isBusy: action.isBusy,
          hasSaved: widget.profile.hasLlm,
          isUpdate: _isSameProvider,
          onSave: _save,
        ),
      ],
    );
  }
}
