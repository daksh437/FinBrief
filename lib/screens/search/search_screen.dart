import 'dart:async';

import 'package:flutter/material.dart';
import '../../models/news_article.dart';
import '../../services/analytics_service.dart';
import '../../services/news_service.dart';
import '../../services/search_history_service.dart';
import '../../theme/app_spacing.dart';
import '../../widgets/category_chip.dart';
import '../../widgets/empty_state.dart';
import '../news/article_detail_screen.dart';

const _filters = ['Stocks', 'Crypto', 'Gold', 'Forex', 'IPO', 'Economy'];

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _controller = TextEditingController();
  Timer? _debounce;
  List<NewsArticle> _results = [];
  List<String> _recent = [];
  List<String> _trending = [];
  String? _selectedFilter;
  bool _loading = false;
  bool _searched = false;

  @override
  void initState() {
    super.initState();
    _loadRecentAndTrending();
  }

  Future<void> _loadRecentAndTrending() async {
    final recent = await SearchHistoryService.getRecent();
    final trending = await NewsService.instance.getTrendingSearches();
    if (mounted) {
      setState(() {
        _recent = recent;
        _trending = trending;
      });
    }
  }

  void _onQueryChanged(String value) {
    _debounce?.cancel();
    if (value.trim().isEmpty) {
      setState(() {
        _results = [];
        _searched = false;
      });
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 400), () => _search(value));
  }

  Future<void> _search(String query) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return;

    setState(() {
      _loading = true;
      _searched = true;
      _selectedFilter = null;
    });
    final results = await NewsService.instance.search(trimmed);
    unawaited(AnalyticsService.instance.logSearch(trimmed));
    await SearchHistoryService.add(trimmed);
    final recent = await SearchHistoryService.getRecent();
    if (!mounted) return;
    setState(() {
      _results = results;
      _recent = recent;
      _loading = false;
    });
  }

  Future<void> _selectFilter(String filter) async {
    _controller.clear();
    _debounce?.cancel();
    setState(() {
      _selectedFilter = filter;
      _loading = true;
      _searched = true;
    });
    final results = await NewsService.instance.getFeed(category: filter.toLowerCase());
    if (!mounted) return;
    setState(() {
      _results = results;
      _loading = false;
    });
  }

  void _runQuery(String query) {
    _controller.text = query;
    _search(query);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _controller,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'Search financial news...', border: InputBorder.none),
          onChanged: _onQueryChanged,
          onSubmitted: _search,
        ),
        actions: [IconButton(onPressed: () => _search(_controller.text), icon: const Icon(Icons.search))],
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
                  selected: _selectedFilter == _filters[i],
                  onTap: () => _selectFilter(_filters[i]),
                ),
              ),
            ),
          ),
          const Divider(height: 1),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) return const Center(child: CircularProgressIndicator());

    if (!_searched) {
      return ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          if (_recent.isNotEmpty) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Recent Searches', style: Theme.of(context).textTheme.titleLarge),
                TextButton(
                  onPressed: () async {
                    await SearchHistoryService.clear();
                    if (mounted) setState(() => _recent = []);
                  },
                  child: const Text('Clear'),
                ),
              ],
            ),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: _recent.map((q) => ActionChip(label: Text(q), onPressed: () => _runQuery(q))).toList(),
            ),
            const SizedBox(height: AppSpacing.lg),
          ],
          if (_trending.isNotEmpty) ...[
            Text('Trending Searches', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: _trending.map((q) => ActionChip(label: Text(q), onPressed: () => _runQuery(q))).toList(),
            ),
          ],
        ],
      );
    }

    if (_results.isEmpty) {
      return const EmptyState(message: 'No results found.', icon: Icons.search_off);
    }

    return ListView.separated(
      itemCount: _results.length,
      separatorBuilder: (_, _) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final article = _results[index];
        return ListTile(
          title: Text(article.title, maxLines: 2, overflow: TextOverflow.ellipsis),
          subtitle: Text(article.source ?? ''),
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => ArticleDetailScreen(article: article)),
          ),
        );
      },
    );
  }
}
