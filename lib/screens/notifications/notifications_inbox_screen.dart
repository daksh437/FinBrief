import 'package:flutter/material.dart';
import '../../models/notification_item.dart';
import '../../services/notification_service.dart';
import '../../theme/app_spacing.dart';
import '../../widgets/category_chip.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/error_state.dart';
import '../../widgets/notification_card.dart';
import 'notification_settings_screen.dart';

const _filters = ['All', 'Breaking News', 'Portfolio Alerts', 'AI Recommendations', 'Market Updates'];
const _filterTypes = {
  'Breaking News': 'breaking_news',
  'Portfolio Alerts': 'portfolio_alert',
  'AI Recommendations': 'ai_recommendation',
  'Market Updates': 'market_update',
};

class NotificationsInboxScreen extends StatefulWidget {
  const NotificationsInboxScreen({super.key});

  @override
  State<NotificationsInboxScreen> createState() => _NotificationsInboxScreenState();
}

class _NotificationsInboxScreenState extends State<NotificationsInboxScreen> {
  late Future<List<NotificationItem>> _inbox;
  String _filter = 'All';

  @override
  void initState() {
    super.initState();
    _inbox = NotificationService.instance.getInbox();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const NotificationSettingsScreen()),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
            child: SizedBox(
              height: 40,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                itemCount: _filters.length,
                separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.sm),
                itemBuilder: (context, i) => CategoryChip(
                  label: _filters[i],
                  selected: _filter == _filters[i],
                  onTap: () => setState(() => _filter = _filters[i]),
                ),
              ),
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: FutureBuilder<List<NotificationItem>>(
              future: _inbox,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return ErrorState(onRetry: () => setState(() => _inbox = NotificationService.instance.getInbox()));
                }
                var items = snapshot.data ?? [];
                if (_filter != 'All') {
                  items = items.where((n) => n.type == _filterTypes[_filter]).toList();
                }
                if (items.isEmpty) {
                  return const EmptyState(
                    message: 'No notifications yet — breaking news and alerts will show up here.',
                    icon: Icons.notifications_none,
                  );
                }
                return ListView.separated(
                  itemCount: items.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (context, i) => NotificationCard(item: items[i]),
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
