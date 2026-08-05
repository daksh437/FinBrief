class NotificationItem {
  final String id;
  final String title;
  final String body;
  final String type; // breaking_news | morning_brief | evening_summary | portfolio_alert | premium_alert
  final int createdAt;
  final bool read;

  NotificationItem({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    required this.createdAt,
    this.read = false,
  });

  factory NotificationItem.fromJson(Map<String, dynamic> json) {
    return NotificationItem(
      id: json['id'] as String,
      title: (json['title'] as String?) ?? '',
      body: (json['body'] as String?) ?? '',
      type: (json['type'] as String?) ?? 'breaking_news',
      createdAt: (json['createdAt'] as num?)?.toInt() ?? 0,
      read: json['read'] as bool? ?? false,
    );
  }
}
