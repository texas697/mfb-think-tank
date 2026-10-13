import 'package:flutter/foundation.dart';
import 'package:mfb_think_tank/features/readers_digest/data/article_card.dart';
import 'package:mfb_think_tank/features/readers_digest/data/taste_summary.dart';
import 'package:mfb_think_tank/features/readers_digest/data/topic_count.dart';

/// One configured content source from the server.
@immutable
class DigestSourceInfo {
  const DigestSourceInfo({
    required this.key,
    required this.name,
    required this.kind,
  });

  factory DigestSourceInfo.fromJson(Map<String, dynamic> json) =>
      DigestSourceInfo(
        key: json['key'] as String? ?? '',
        name: json['name'] as String? ?? '',
        kind: json['kind'] as String? ?? '',
      );

  final String key;
  final String name;
  final String kind;
}

/// Feed response from `GET /api/digest/list`.
@immutable
class DigestFeed {
  const DigestFeed({
    this.items = const [],
    this.total = 0,
    this.mode = 'chrono',
    this.votes = 0,
    this.minVotesForAffinity = 5,
    this.topics = const [],
    this.taste = const TasteSummary(),
    this.sources = const [],
    this.storeSize = 0,
  });

  factory DigestFeed.fromJson(Map<String, dynamic> json) => DigestFeed(
    items: json['items'] is List
        ? (json['items'] as List)
              .whereType<Map<String, dynamic>>()
              .map(ArticleCard.fromJson)
              .toList()
        : const [],
    total: (json['total'] as num? ?? 0).toInt(),
    mode: json['mode'] as String? ?? 'chrono',
    votes: (json['votes'] as num? ?? 0).toInt(),
    minVotesForAffinity: (json['minVotesForAffinity'] as num? ?? 5).toInt(),
    topics: json['topics'] is List
        ? (json['topics'] as List)
              .whereType<Map<String, dynamic>>()
              .map(TopicCount.fromJson)
              .toList()
        : const [],
    taste: json['taste'] is Map<String, dynamic>
        ? TasteSummary.fromJson(json['taste'] as Map<String, dynamic>)
        : const TasteSummary(),
    sources: json['sources'] is List
        ? (json['sources'] as List)
              .whereType<Map<String, dynamic>>()
              .map(DigestSourceInfo.fromJson)
              .toList()
        : const [],
    storeSize: (json['storeSize'] as num? ?? 0).toInt(),
  );

  final List<ArticleCard> items;
  final int total;

  /// Server ordering: `chrono` or `affinity`.
  final String mode;
  final int votes;
  final int minVotesForAffinity;
  final List<TopicCount> topics;
  final TasteSummary taste;
  final List<DigestSourceInfo> sources;

  /// Backend's cached library size, not a full historical archive count.
  final int storeSize;

  bool get isRankedByAffinity => mode == 'affinity';

  /// Number of further ratings needed before affinity ranking kicks in.
  int get ratingsUntilAffinity =>
      (minVotesForAffinity - votes).clamp(0, minVotesForAffinity);

  /// Copy with one card's vote reconciled after a confirmed rating.
  DigestFeed withVote(String id, int rating) => copyWith(
    items: [
      for (final item in items)
        if (item.id == id) item.withVote(rating) else item,
    ],
  );

  /// Copy with one card's write-up flag updated after generation.
  DigestFeed withWriteup(String id, bool value) => copyWith(
    items: [
      for (final item in items)
        if (item.id == id) item.withWriteup(value) else item,
    ],
  );

  DigestFeed copyWith({List<ArticleCard>? items, TasteSummary? taste}) =>
      DigestFeed(
        items: items ?? this.items,
        total: total,
        mode: mode,
        votes: votes,
        minVotesForAffinity: minVotesForAffinity,
        topics: topics,
        taste: taste ?? this.taste,
        sources: sources,
        storeSize: storeSize,
      );
}
