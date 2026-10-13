import 'package:flutter/foundation.dart';

/// What kind of feedback the server receives. Ids match the API.
enum FeedbackCategory {
  bug('bug', 'Bug'),
  idea('idea', 'Idea'),
  data('data', 'Wrong data'),
  other('other', 'Other'),

  /// Sent by the error reporter, never picked by the user.
  error('error', 'Error');

  const FeedbackCategory(this.id, this.label);

  final String id;
  final String label;

  /// Categories a person can choose in the feedback sheet.
  static const userChoices = [bug, idea, data, other];
}

/// Input for `POST /api/feedback`. Platform and version are added by the
/// repository, so callers only describe what happened.
@immutable
class FeedbackReport {
  const FeedbackReport({
    required this.category,
    required this.description,
    this.page,
    this.state,
  });

  final FeedbackCategory category;
  final String description;

  /// Route the user was on, if known.
  final String? page;

  /// Arbitrary client state kept with the report (stack trace, query, ...).
  final Map<String, Object?>? state;

  Map<String, Object?> toJson({
    required String platform,
    required String appVersion,
  }) => {
    'category': category.id,
    'description': description,
    'platform': platform,
    'appVersion': appVersion,
    if (page case final page? when page.isNotEmpty) 'page': page,
    if (state case final state? when state.isNotEmpty) 'state': state,
  };
}
