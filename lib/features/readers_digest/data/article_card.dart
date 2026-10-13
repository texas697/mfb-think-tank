import 'package:flutter/foundation.dart';

/// Library card for one digest article.
@immutable
class ArticleCard {
  const ArticleCard({
    required this.id,
    required this.url,
    required this.title,
    required this.source,
    required this.kind,
    required this.description,
    required this.topics,
    required this.hasWriteup,
    required this.vote,
    this.sourceKey,
    this.publishedAt,
    this.fetchedAt,
    this.image,
  });

  /// Decodes a card from the server JSON. Missing fields become safe defaults.
  factory ArticleCard.fromJson(Map<String, dynamic> json) => ArticleCard(
    id: json['id'] as String? ?? '',
    url: json['url'] as String? ?? '',
    title: json['title'] as String? ?? '',
    source: json['source'] as String? ?? '',
    kind: json['kind'] as String? ?? 'news',
    description: json['description'] as String? ?? '',
    topics: _stringList(json['topics']),
    hasWriteup: json['hasWriteup'] as bool? ?? false,
    vote: (json['vote'] as num? ?? 0).toInt().clamp(-1, 1),
    sourceKey: json['sourceKey'] as String?,
    publishedAt: _date(json['publishedAt']),
    fetchedAt: _date(json['fetchedAt']),
    image: json['image'] as String?,
  );

  final String id;
  final String url;
  final String title;
  final String source;
  final String? sourceKey;

  /// Server kind: `thinktank` or `news`.
  final String kind;
  final String description;
  final DateTime? publishedAt;
  final DateTime? fetchedAt;
  final String? image;
  final List<String> topics;
  final bool hasWriteup;
  final int vote;

  bool get isThinkTank => kind == 'thinktank';

  /// Copy with a new vote after a confirmed server rating.
  ArticleCard withVote(int rating) => ArticleCard(
    id: id,
    url: url,
    title: title,
    source: source,
    sourceKey: sourceKey,
    kind: kind,
    description: description,
    publishedAt: publishedAt,
    fetchedAt: fetchedAt,
    image: image,
    topics: topics,
    hasWriteup: hasWriteup,
    vote: rating,
  );

  /// Copy with write-up presence updated after a generated summary.
  ArticleCard withWriteup(bool value) => ArticleCard(
    id: id,
    url: url,
    title: title,
    source: source,
    sourceKey: sourceKey,
    kind: kind,
    description: description,
    publishedAt: publishedAt,
    fetchedAt: fetchedAt,
    image: image,
    topics: topics,
    hasWriteup: value,
    vote: vote,
  );
}

List<String> _stringList(Object? value) =>
    value is List ? value.whereType<String>().toList() : const [];

DateTime? _date(Object? value) {
  if (value is! String || value.isEmpty) return null;
  return DateTime.tryParse(value)?.toLocal();
}
