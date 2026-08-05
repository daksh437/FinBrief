import 'dart:async';

import 'package:flutter/material.dart';
import '../../models/news_article.dart';
import '../../services/news_service.dart';
import '../../services/squawk_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/error_state.dart';
import '../../widgets/loading_skeleton.dart';
import '../../widgets/tape_row.dart';
import '../news/article_detail_screen.dart';

/// Live headline tape — a squawk-style feed.
///
/// Two modes: "All" (everything) and "My Portfolio" (only news affecting the
/// user's holdings). The portfolio mode is the part a broadcast service can't
/// replicate, so it's given equal billing rather than buried.
enum _TapeMode { all, portfolio }

class LiveTapeScreen extends StatefulWidget {
  const LiveTapeScreen({super.key});

  @override
  State<LiveTapeScreen> createState() => _LiveTapeScreenState();
}

class _LiveTapeScreenState extends State<LiveTapeScreen> {
  static const _refreshInterval = Duration(minutes: 2);

  _TapeMode _mode = _TapeMode.all;
  List<NewsArticle> _articles = [];
  bool _loading = true;
  bool _squawkOn = false;
  String? _error;
  Timer? _timer;
  DateTime? _lastUpdated;

  @override
  void initState() {
    super.initState();
    _initSquawk();
    _load(initial: true);
    // Auto-refresh keeps the tape live without the user pulling to refresh.
    _timer = Timer.periodic(_refreshInterval, (_) => _load());
  }

  Future<void> _initSquawk() async {
    await SquawkService.instance.init();
    if (mounted) setState(() => _squawkOn = SquawkService.instance.isEnabled);
  }

  @override
  void dispose() {
    _timer?.cancel();
    SquawkService.instance.stop();
    super.dispose();
  }

  Future<void> _load({bool initial = false}) async {
    if (initial) setState(() => _loading = true);

    try {
      final fetched = _mode == _TapeMode.portfolio
          ? await NewsService.instance.getPersonalisedFeed()
          : await NewsService.instance.getBreaking(pageSize: 40);

      if (!mounted) return;

      // Announce genuinely new headlines only — SquawkService dedupes by id,
      // and we skip the very first load so enabling squawk doesn't dump the
      // entire backlog at the user.
      if (!initial && _squawkOn) {
        final knownIds = _articles.map((a) => a.id).toSet();
        for (final a in fetched.where((a) => !knownIds.contains(a.id)).take(3)) {
          await SquawkService.instance.announce(id: a.id, headline: a.title);
        }
      } else if (initial) {
        for (final a in fetched) {
          SquawkService.instance.announce(id: a.id, headline: a.title);
        }
        await SquawkService.instance.stop();
      }

      setState(() {
        _articles = fetched;
        _loading = false;
        _error = null;
        _lastUpdated = DateTime.now();
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Could not load the tape.';
      });
    }
  }

  void _switchMode(_TapeMode mode) {
    if (_mode == mode) return;
    setState(() {
      _mode = mode;
      _articles = [];
    });
    _load(initial: true);
  }

  Future<void> _toggleSquawk() async {
    final next = !_squawkOn;
    await SquawkService.instance.setEnabled(next);
    if (!mounted) return;
    setState(() => _squawkOn = next);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(next ? 'Squawk on — new headlines will be read aloud' : 'Squawk off'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        titleSpacing: AppSpacing.md,
        title: Row(
          children: [
            Container(width: 8, height: 8, decoration: const BoxDecoration(color: AppColors.danger, shape: BoxShape.circle)),
            const SizedBox(width: 6),
            const Text('LIVE'),
            if (_lastUpdated != null) ...[
              const SizedBox(width: AppSpacing.sm),
              Text(
                '· updated ${TimeOfDay.fromDateTime(_lastUpdated!).format(context)}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ],
        ),
        actions: [
          IconButton(
            tooltip: _squawkOn ? 'Turn squawk off' : 'Read headlines aloud',
            icon: Icon(
              _squawkOn ? Icons.volume_up : Icons.volume_off_outlined,
              color: _squawkOn ? AppColors.primary : null,
            ),
            onPressed: _toggleSquawk,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.md, 0, AppSpacing.md, AppSpacing.sm),
            child: SegmentedButton<_TapeMode>(
              segments: const [
                ButtonSegment(value: _TapeMode.all, label: Text('All News'), icon: Icon(Icons.public, size: 16)),
                ButtonSegment(
                  value: _TapeMode.portfolio,
                  label: Text('My Portfolio'),
                  icon: Icon(Icons.account_balance_wallet_outlined, size: 16),
                ),
              ],
              selected: {_mode},
              onSelectionChanged: (s) => _switchMode(s.first),
            ),
          ),
          const Divider(height: 1),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: const [
          LoadingSkeleton(height: 14, width: 120),
          SizedBox(height: 8),
          LoadingSkeleton(height: 14, width: double.infinity),
          SizedBox(height: 16),
          LoadingSkeleton(height: 14, width: 120),
          SizedBox(height: 8),
          LoadingSkeleton(height: 14, width: double.infinity),
        ],
      );
    }

    if (_error != null) {
      return ErrorState(message: _error!, onRetry: () => _load(initial: true));
    }

    if (_articles.isEmpty) {
      return EmptyState(
        message: _mode == _TapeMode.portfolio
            ? 'No news affecting your holdings right now.\nAdd stocks to your Portfolio or Watchlist to see more.'
            : 'No headlines right now. Pull to refresh.',
        icon: _mode == _TapeMode.portfolio ? Icons.account_balance_wallet_outlined : Icons.bolt_outlined,
      );
    }

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.separated(
        itemCount: _articles.length,
        separatorBuilder: (_, _) => const Divider(height: 1),
        itemBuilder: (context, i) => TapeRow(
          article: _articles[i],
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => ArticleDetailScreen(article: _articles[i])),
          ),
        ),
      ),
    );
  }
}
