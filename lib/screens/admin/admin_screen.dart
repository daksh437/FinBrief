import 'package:flutter/material.dart';
import '../../services/admin_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';

/// Operator dashboard.
///
/// Every figure here previously required running a script against Firestore by
/// hand — including the AI call count that turned out to explain the Gemini
/// bill. Having it on a screen is the difference between noticing a problem
/// and noticing it a week later.
///
/// Access is enforced on the server; this screen being hidden is presentation.
class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> with SingleTickerProviderStateMixin {
  late final TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin'),
        bottom: TabBar(
          controller: _tabs,
          tabs: const [
            Tab(text: 'Overview'),
            Tab(text: 'Users'),
            Tab(text: 'Errors'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabs,
        children: const [_OverviewTab(), _UsersTab(), _ErrorsTab()],
      ),
    );
  }
}

class _OverviewTab extends StatefulWidget {
  const _OverviewTab();

  @override
  State<_OverviewTab> createState() => _OverviewTabState();
}

class _OverviewTabState extends State<_OverviewTab> {
  late Future<Map<String, dynamic>?> _future;

  @override
  void initState() {
    super.initState();
    _future = AdminService.instance.overview();
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async => setState(() => _future = AdminService.instance.overview()),
      child: FutureBuilder<Map<String, dynamic>?>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final d = snapshot.data;
          if (d == null) {
            return ListView(
              children: const [
                SizedBox(height: 120),
                Center(child: Text("Couldn't load. Pull to retry.")),
              ],
            );
          }

          final limits = (d['limits'] as Map?) ?? {};

          return ListView(
            padding: const EdgeInsets.all(AppSpacing.md),
            children: [
              _section('Users'),
              _row('Total', d['users']),
              _row('Premium', d['premium']),
              _row('Free', d['free']),
              _row('Active today', d['activeToday']),
              _row('Push enabled', d['withPushToken']),

              _section('AI — last 24 hours'),
              // This is the number that matters for spend: it counts cron work
              // too, which per-user usage does not.
              _row('Model calls', d['aiCalls24h'], highlight: true),
              _row('Cache hits', d['cacheHits24h']),
              _row('Failures', d['aiFailures24h'],
                  warn: ((d['aiFailures24h'] as num?) ?? 0) > 20),
              _row('User actions today', d['aiUsedToday']),
              _row('Daily limit (free / premium)', '${limits['free']} / ${limits['premium']}'),

              _section('Content'),
              _row('News stored', d['newsStored']),
              _row('Archived', d['archived']),

              const SizedBox(height: AppSpacing.lg),
              Text(
                'Model calls drive the Gemini bill. If this climbs without users '
                'climbing, something is looping.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).hintColor,
                    ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _section(String title) => Padding(
        padding: const EdgeInsets.only(top: AppSpacing.md, bottom: AppSpacing.sm),
        child: Text(title, style: Theme.of(context).textTheme.titleSmall),
      );

  Widget _row(String label, Object? value, {bool highlight = false, bool warn = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            '${value ?? '—'}',
            style: TextStyle(
              fontWeight: highlight || warn ? FontWeight.bold : FontWeight.w600,
              color: warn ? AppColors.danger : (highlight ? AppColors.primary : null),
            ),
          ),
        ],
      ),
    );
  }
}

class _UsersTab extends StatefulWidget {
  const _UsersTab();

  @override
  State<_UsersTab> createState() => _UsersTabState();
}

class _UsersTabState extends State<_UsersTab> {
  late Future<List<Map<String, dynamic>>> _future;

  @override
  void initState() {
    super.initState();
    _future = AdminService.instance.users();
  }

  void _reload() => setState(() => _future = AdminService.instance.users());

  Future<void> _togglePlan(Map<String, dynamic> user) async {
    final next = user['plan'] == 'premium' ? 'free' : 'premium';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text(next == 'premium' ? 'Grant Premium?' : 'Remove Premium?'),
        content: Text(
          '${user['email'] ?? user['uid']}\n\n'
          '${next == 'premium' ? 'They get unlimited AI and no ads, with no payment taken.' : 'They drop back to the free daily limit.'}',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(c, true), child: const Text('Confirm')),
        ],
      ),
    );

    if (confirmed != true) return;
    await AdminService.instance.setPlan(user['uid'] as String, next);
    _reload();
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async => _reload(),
      child: FutureBuilder<List<Map<String, dynamic>>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final users = snapshot.data ?? [];

          return ListView.separated(
            itemCount: users.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (context, i) {
              final u = users[i];
              final premium = u['plan'] == 'premium';

              return ListTile(
                title: Text(u['email'] as String? ?? u['uid'] as String),
                subtitle: Text(
                  '${u['plan']}'
                  '${u['isAdmin'] == true ? ' · admin' : ''}'
                  ' · ${u['usedToday']} AI today'
                  '${u['hasPushToken'] == true ? ' · push' : ''}',
                ),
                trailing: TextButton(
                  onPressed: () => _togglePlan(u),
                  child: Text(premium ? 'Make free' : 'Make premium'),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _ErrorsTab extends StatefulWidget {
  const _ErrorsTab();

  @override
  State<_ErrorsTab> createState() => _ErrorsTabState();
}

class _ErrorsTabState extends State<_ErrorsTab> {
  late Future<List<Map<String, dynamic>>> _future;

  @override
  void initState() {
    super.initState();
    _future = AdminService.instance.errors();
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async => setState(() => _future = AdminService.instance.errors()),
      child: FutureBuilder<List<Map<String, dynamic>>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final errors = snapshot.data ?? [];
          if (errors.isEmpty) {
            return ListView(
              children: const [
                SizedBox(height: 120),
                Center(child: Text('No errors in the last 48 hours.')),
              ],
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(AppSpacing.md),
            itemCount: errors.length,
            separatorBuilder: (_, _) => const Divider(),
            itemBuilder: (context, i) {
              final e = errors[i];
              final at = e['createdAt'] as int?;
              final when = at != null ? DateTime.fromMillisecondsSinceEpoch(at) : null;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${e['event'] ?? 'error'}'
                    '${when != null ? '  ·  ${when.hour.toString().padLeft(2, '0')}:${when.minute.toString().padLeft(2, '0')}' : ''}',
                    style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.danger),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${e['meta'] ?? e['data'] ?? ''}',
                    maxLines: 4,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}
