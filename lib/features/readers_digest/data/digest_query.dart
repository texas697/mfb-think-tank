import 'package:flutter/foundation.dart';

/// Feed query: filter, topic, search, limit. Caps mirror the server.
@immutable
class DigestQuery {
  const DigestQuery({
    this.filter = filterAll,
    this.topic = '',
    this.q = '',
    this.limit = 300,
  });

  static const filterAll = 'all';
  static const filterForYou = 'foryou';
  static const filterThinkTank = 'thinktank';
  static const filterNews = 'news';

  static const _filters = {
    filterAll,
    filterForYou,
    filterThinkTank,
    filterNews,
  };

  /// Server truncates `q` to 100 characters.
  static const maxQueryLength = 100;

  /// Server truncates `topic` to 40 characters.
  static const maxTopicLength = 40;

  /// Server caps `limit` at 300; default request is the full cap.
  static const maxLimit = 300;

  /// Sanitizes raw values; unknown filters become [filterAll].
  factory DigestQuery.sanitized({
    String filter = filterAll,
    String topic = '',
    String q = '',
    int limit = maxLimit,
  }) => DigestQuery(
    filter: _filters.contains(filter) ? filter : filterAll,
    topic: _trim(topic, maxTopicLength),
    q: _trim(q, maxQueryLength),
    limit: limit.clamp(1, maxLimit),
  );

  final String filter;
  final String topic;
  final String q;
  final int limit;

  bool get hasSearch => q.isNotEmpty;
  bool get hasTopic => topic.isNotEmpty;
  bool get isForYou => filter == filterForYou;

  DigestQuery copyWith({
    String? filter,
    String? topic,
    String? q,
    int? limit,
  }) => DigestQuery.sanitized(
    filter: filter ?? this.filter,
    topic: topic ?? this.topic,
    q: q ?? this.q,
    limit: limit ?? this.limit,
  );

  /// Query parameters for `GET /api/digest/list`; empty values are omitted.
  Map<String, String> toQueryParameters() => {
    if (filter != filterAll) 'filter': filter,
    if (topic.isNotEmpty) 'topic': topic,
    if (q.isNotEmpty) 'q': q,
    'limit': '$limit',
  };

  @override
  bool operator ==(Object other) =>
      other is DigestQuery &&
      other.filter == filter &&
      other.topic == topic &&
      other.q == q &&
      other.limit == limit;

  @override
  int get hashCode => Object.hash(filter, topic, q, limit);
}

String _trim(String value, int max) {
  final trimmed = value.trim();
  return trimmed.length <= max ? trimmed : trimmed.substring(0, max);
}
