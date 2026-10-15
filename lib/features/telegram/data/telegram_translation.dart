/// Optional server-generated translation, preserving the original message.
class TelegramTranslation {
  const TelegramTranslation({required this.text, this.from});
  factory TelegramTranslation.fromJson(Map<String, dynamic> json) =>
      TelegramTranslation(
        text: json['text'] as String,
        from: json['from'] as String?,
      );
  final String text;
  final String? from;

  /// Human-readable language where the server provides a recognized code.
  String? get sourceLanguage => switch (from) {
    'fa' => 'Persian',
    'ru' => 'Russian',
    'uk' => 'Ukrainian',
    'ar' => 'Arabic',
    'he' => 'Hebrew',
    'en' => 'English',
    _ => from,
  };
}
