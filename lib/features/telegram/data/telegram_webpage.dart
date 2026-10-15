/// Safe text metadata for a linked webpage preview.
class TelegramWebpage {
  const TelegramWebpage({
    required this.url,
    this.displayUrl = '',
    this.siteName,
    this.title,
    this.description,
    this.hasPhoto = false,
  });
  factory TelegramWebpage.fromJson(Map<String, dynamic> json) =>
      TelegramWebpage(
        url: json['url'] as String,
        displayUrl: json['displayUrl'] as String? ?? '',
        siteName: json['siteName'] as String?,
        title: json['title'] as String?,
        description: json['description'] as String?,
        hasPhoto: json['hasPhoto'] as bool? ?? false,
      );
  final String url;
  final String displayUrl;
  final String? siteName;
  final String? title;
  final String? description;
  final bool hasPhoto;
}
