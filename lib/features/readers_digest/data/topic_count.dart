import 'package:flutter/foundation.dart';

/// Topic with its library-wide occurrence count.
@immutable
class TopicCount {
  const TopicCount({required this.topic, required this.count});

  factory TopicCount.fromJson(Map<String, dynamic> json) => TopicCount(
    topic: json['topic'] as String? ?? '',
    count: (json['count'] as num? ?? 0).toInt(),
  );

  final String topic;
  final int count;
}
