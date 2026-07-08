/// Tiny "3h ago" style formatter so we don't need to pull in the intl
/// package just for the Recent list.
String relativeTime(DateTime? time) {
  if (time == null) return '';
  final Duration diff = DateTime.now().difference(time);

  if (diff.inSeconds < 60) return 'Just now';
  if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
  if (diff.inHours < 24) return '${diff.inHours}h ago';
  if (diff.inDays < 7) return '${diff.inDays}d ago';

  return '${time.day}/${time.month}/${time.year}';
}