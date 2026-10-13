/// Display label for a server topic tag. Display only; filters always use the
/// original tag.
String topicLabel(String topic) => topic
    .split(RegExp(r'[-_\s]+'))
    .where((word) => word.isNotEmpty)
    .map((word) => word[0].toUpperCase() + word.substring(1))
    .join(' ');
