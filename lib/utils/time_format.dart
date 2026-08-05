String timeAgo(String? iso) {
  if (iso == null) return '';
  final parsed = DateTime.tryParse(iso);
  if (parsed == null) return '';

  final diff = DateTime.now().toUtc().difference(parsed.toUtc());
  if (diff.inMinutes < 1) return 'just now';
  if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
  if (diff.inHours < 24) return '${diff.inHours}h ago';
  return '${diff.inDays}d ago';
}
