import 'dart:convert';

import 'package:mfb_think_tank/core/network/api_client.dart';
import 'package:mfb_think_tank/features/readers_digest/data/article_detail.dart';
import 'package:mfb_think_tank/features/readers_digest/data/digest_error_mapper.dart';
import 'package:mfb_think_tank/features/readers_digest/data/digest_failure.dart';
import 'package:mfb_think_tank/features/readers_digest/data/digest_feed.dart';
import 'package:mfb_think_tank/features/readers_digest/data/digest_query.dart';
import 'package:mfb_think_tank/features/readers_digest/data/digest_repository.dart';
import 'package:mfb_think_tank/features/readers_digest/data/research_result.dart';

/// [DigestRepository] over the Crucix HTTP API.
class HttpDigestRepository implements DigestRepository {
  HttpDigestRepository({required this._api});

  final ApiClient _api;

  @override
  Future<DigestFeed> fetchFeed(DigestQuery query) async {
    final json = await _getJson(
      'api/digest/list',
      query: query.toQueryParameters(),
    );
    return _decode(json, DigestFeed.fromJson);
  }

  @override
  Future<ArticleDetail> fetchArticle(String id) async {
    final json = await _getJson('api/digest/article/${_id(id)}');
    return _decode(json, ArticleDetail.fromJson);
  }

  @override
  Future<int> sendRating(String id, int rating) async {
    final json = await _postJson('api/digest/${_id(id)}/feedback', {
      'rating': rating.clamp(-1, 1),
    });
    return ((json['rating'] as num?) ?? 0).toInt().clamp(-1, 1);
  }

  // The server answers only after the LLM finishes and allows it 60 s; a
  // shorter client timeout reports failure for a write-up that was stored.
  static const _summarizeTimeout = Duration(seconds: 75);

  @override
  Future<ArticleDetail> summarize(String id) async {
    final response = await _call(
      () => _api.post(
        'api/digest/${_id(id)}/summarize',
        timeout: _summarizeTimeout,
      ),
    );
    return _decode(_decodeJson(response), ArticleDetail.fromJson);
  }

  @override
  Future<void> startResearch(String id) async {
    final response = await _call(
      () => _api.post('api/digest/${_id(id)}/research'),
    );
    if (!response.isSuccess) throw mapDigestError(response);
  }

  @override
  Future<ResearchResult> fetchResearch(String id) async {
    final json = await _getJson('api/digest/${_id(id)}/research');
    return _decode(json, ResearchResult.fromJson);
  }

  Future<Map<String, dynamic>> _getJson(
    String path, {
    Map<String, String>? query,
  }) async {
    final response = await _call(() => _api.get(path, query: query));
    return _decodeJson(response);
  }

  Future<Map<String, dynamic>> _postJson(String path, Object? body) async {
    final response = await _call(() => _api.post(path, body: body));
    return _decodeJson(response);
  }

  /// Maps transport failures and a missing session to feature failures.
  Future<ApiResponse> _call(Future<ApiResponse> Function() request) async {
    try {
      return await request();
    } on ApiException catch (e) {
      throw switch (e.kind) {
        ApiFailureKind.timeout => const DigestTimeout(),
        ApiFailureKind.unauthorized => const DigestUnauthenticated(),
        _ => const DigestNetwork(),
      };
    } on StateError {
      throw const DigestUnauthenticated();
    }
  }

  Map<String, dynamic> _decodeJson(ApiResponse response) {
    if (!response.isSuccess) throw mapDigestError(response);
    try {
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic>) return decoded;
      throw const FormatException('expected object');
    } on FormatException {
      throw const DigestMalformed();
    }
  }

  T _decode<T>(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic>) fromJson,
  ) {
    try {
      return fromJson(json);
    } catch (_) {
      throw const DigestMalformed();
    }
  }

  String _id(String id) => id.length <= 40 ? id : id.substring(0, 40);
}
