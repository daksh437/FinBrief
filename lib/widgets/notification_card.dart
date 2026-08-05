import 'package:flutter/material.dart';
import '../models/notification_item.dart';
import '../theme/app_colors.dart';

const _typeIcons = {
  'breaking_news': Icons.bolt_rounded,
  'morning_brief': Icons.wb_sunny_outlined,
  'evening_summary': Icons.nights_stay_outlined,
  'portfolio_alert': Icons.show_chart,
  'premium_alert': Icons.workspace_premium_outlined,
  'ai_recommendation': Icons.auto_awesome,
  'market_update': Icons.trending_up,
};

const _typeColors = {
  'breaking_news': AppColors.danger,
  'ai_recommendation': AppColors.primary,
  'portfolio_alert': AppColors.success,
};

class NotificationCard extends StatelessWidget {
  final NotificationItem item;

  const NotificationCard({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    final color = _typeColors[item.type] ?? AppColors.secondary;

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: color.withValues(alpha: 0.12),
        child: Icon(_typeIcons[item.type] ?? Icons.notifications_outlined, color: color, size: 18),
      ),
      title: Text(item.title, style: TextStyle(fontWeight: item.read ? FontWeight.normal : FontWeight.bold)),
      subtitle: Text(item.body, maxLines: 2, overflow: TextOverflow.ellipsis),
    );
  }
}
