import 'package:flutter/foundation.dart';

/// One topic preference derived from the user's votes.
@immutable
class TasteEntry {
  const TasteEntry({required this.topic, required this.score, this.votes});

  factory TasteEntry.fromJson(Map<String, dynamic> json) => TasteEntry(
    topic: json['topic'] as String? ?? '',
    score: (json['score'] as num? ?? 0).toDouble(),
    votes: (json['votes'] as num?)?.toInt(),
  );

  final String topic;
  final double score;
  final int? votes;
}

/// Personalization summary from the server (liked and disliked topics).
@immutable
class TasteSummary {
  const TasteSummary({this.likes = const [], this.dislikes = const []});

  factory TasteSummary.fromJson(Map<String, dynamic> json) => TasteSummary(
    likes: _entries(json['likes']),
    dislikes: _entries(json['dislikes']),
  );

  final List<TasteEntry> likes;
  final List<TasteEntry> dislikes;

  bool get isEmpty => likes.isEmpty && dislikes.isEmpty;

  static List<TasteEntry> _entries(Object? value) => value is List
      ? value
            .whereType<Map<String, dynamic>>()
            .map(TasteEntry.fromJson)
            .toList()
      : const [];
}
