import 'package:flutter_test/flutter_test.dart';
import 'package:mfb_think_tank/features/digest_settings/data/ai_settings.dart';

void main() {
  test('a null key is omitted so the stored key is kept', () {
    final json = const AiSettingsInput(
      provider: 'openai-compatible',
      baseUrl: 'https://llm.example.com',
    ).toJson();
    expect(json.containsKey('apiKey'), isFalse);
    expect(json['baseUrl'], 'https://llm.example.com');
  });

  test('a key is sent when provided', () {
    expect(
      const AiSettingsInput(provider: 'openai', apiKey: 'k').toJson()['apiKey'],
      'k',
    );
  });
}
