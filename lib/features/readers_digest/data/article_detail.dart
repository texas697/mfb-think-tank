import 'package:flutter/foundation.dart';
import 'package:mfb_think_tank/features/readers_digest/data/article_card.dart';
import 'package:mfb_think_tank/features/readers_digest/data/research_result.dart';

/// Full article payload: card fields plus write-up, excerpt, and research.
@immutable
class ArticleDetail {
  const ArticleDetail({
    required this.card,
    this.summaryMd,
    this.summarizedBy,
    this.summaryModel,
    this.author,
    this.extracted = false,
    this.textPreview = '',
    this.research = const ResearchResult(),
  });

  factory ArticleDetail.fromJson(Map<String, dynamic> json) => ArticleDetail(
    card: ArticleCard.fromJson(json),
    summaryMd: json['summaryMd'] as String?,
    summarizedBy: json['summarizedBy'] as String?,
    summaryModel: json['summaryModel'] as String?,
    author: json['author'] as String?,
    extracted: json['extracted'] as bool? ?? false,
    textPreview: json['textPreview'] as String? ?? '',
    research: json['research'] is Map<String, dynamic>
        ? ResearchResult.fromJson(json['research'] as Map<String, dynamic>)
        : const ResearchResult(),
  );

  final ArticleCard card;
  final String? summaryMd;

  /// Role string `user` or `operator` — never an identity.
  final String? summarizedBy;

  /// `provider/model` attribution string from the server.
  final String? summaryModel;
  final String? author;
  final bool extracted;
  final String textPreview;
  final ResearchResult research;

  String get id => card.id;

  bool get hasWriteup =>
      summaryMd != null && summaryMd!.trim().isNotEmpty || card.hasWriteup;

  /// Copy with an updated vote after a confirmed server rating.
  ArticleDetail withVote(int rating) => _copy(card: card.withVote(rating));

  /// Copy with write-up presence updated after generation.
  ArticleDetail withWriteup(bool value) => _copy(card: card.withWriteup(value));

  /// Copy with a fresh summary from a summarize response.
  ArticleDetail withSummary(ArticleDetail other) => _copy(
    card: other.card,
    summaryMd: other.summaryMd,
    summarizedBy: other.summarizedBy,
    summaryModel: other.summaryModel,
    author: other.author,
    extracted: other.extracted,
    textPreview: other.textPreview,
  );

  /// Copy with a refreshed research projection.
  ArticleDetail withResearch(ResearchResult value) => _copy(research: value);

  ArticleDetail _copy({
    ArticleCard? card,
    String? summaryMd,
    String? summarizedBy,
    String? summaryModel,
    String? author,
    bool? extracted,
    String? textPreview,
    ResearchResult? research,
  }) => ArticleDetail(
    card: card ?? this.card,
    summaryMd: summaryMd ?? this.summaryMd,
    summarizedBy: summarizedBy ?? this.summarizedBy,
    summaryModel: summaryModel ?? this.summaryModel,
    author: author ?? this.author,
    extracted: extracted ?? this.extracted,
    textPreview: textPreview ?? this.textPreview,
    research: research ?? this.research,
  );
}
