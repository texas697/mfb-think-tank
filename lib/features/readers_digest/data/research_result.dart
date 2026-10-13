import 'package:flutter/foundation.dart';

/// Cited source attached to a finished research run.
@immutable
class ResearchSource {
  const ResearchSource({
    required this.title,
    required this.url,
    this.domain,
    this.date,
  });

  factory ResearchSource.fromJson(Map<String, dynamic> json) => ResearchSource(
    title: json['title'] as String? ?? '',
    url: json['url'] as String? ?? '',
    domain: json['domain'] as String?,
    date: json['date'] as String?,
  );

  final String title;
  final String url;
  final String? domain;
  final String? date;
}

/// Research run for one article and one user.
///
/// One decoder accepts both server shapes: the trimmed projection embedded in
/// the article endpoint and the raw stored document from the research GET
/// (or `{state: 'none'}`). Unknown fields are ignored.
@immutable
class ResearchResult {
  const ResearchResult({
    this.state = 'none',
    this.stage,
    this.progress,
    this.error,
    this.markdown,
    this.sources = const [],
    this.model,
    this.completedAt,
  });

  factory ResearchResult.fromJson(Map<String, dynamic> json) => ResearchResult(
    state: json['state'] as String? ?? 'none',
    stage: json['stage'] as String?,
    progress: (json['progress'] as num?)?.toInt(),
    error: json['error'] as String?,
    markdown: json['markdown'] as String?,
    sources: json['sources'] is List
        ? (json['sources'] as List)
              .whereType<Map<String, dynamic>>()
              .map(ResearchSource.fromJson)
              .toList()
        : const [],
    model: json['model'] as String?,
    completedAt: _date(json['completedAt']),
  );

  /// `none` | `running` | `done` | `error`.
  final String state;
  final String? stage;
  final int? progress;
  final String? error;
  final String? markdown;

  /// Empty while `searching`/`reading`; written at `synthesizing`.
  final List<ResearchSource> sources;
  final String? model;
  final DateTime? completedAt;

  bool get isNone => state == 'none';
  bool get isRunning => state == 'running';
  bool get isDone => state == 'done';
  bool get isError => state == 'error';
}

DateTime? _date(Object? value) {
  if (value is! String || value.isEmpty) return null;
  return DateTime.tryParse(value)?.toLocal();
}
