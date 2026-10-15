/// Attachment metadata; the server never streams files larger than 60 MiB.
class TelegramMedia {
  const TelegramMedia({
    required this.kind,
    this.mime = '',
    this.size,
    this.width,
    this.height,
    this.duration,
    this.isTooLarge = false,
  });
  factory TelegramMedia.fromJson(Map<String, dynamic> json) => TelegramMedia(
    kind: json['kind'] as String,
    mime: json['mime'] as String? ?? '',
    size: (json['size'] as num?)?.toInt(),
    width: (json['width'] as num?)?.toInt(),
    height: (json['height'] as num?)?.toInt(),
    duration: (json['duration'] as num?)?.toDouble(),
    isTooLarge: json['tooLarge'] as bool? ?? false,
  );
  final String kind;
  final String mime;
  final int? size;
  final int? width;
  final int? height;
  final double? duration;
  final bool isTooLarge;
  bool get canPlay =>
      !isTooLarge &&
      (size ?? 0) <= 60 * 1024 * 1024 &&
      const {'video', 'audio'}.contains(kind);
  String get sizeLabel =>
      size == null ? '' : '${(size! / 1024 / 1024).toStringAsFixed(1)} MB';
}
