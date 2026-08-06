import 'dart:async';

import 'package:flutter/material.dart';
import '../../models/ai_insight.dart';
import '../../models/ai_pick.dart';
import '../../models/ipo_event.dart';
import '../../models/market_overview.dart';
import '../../models/news_article.dart';
import '../../services/market_service.dart';
import '../../services/news_service.dart';
import '../../theme/app_spacing.dart';
import '../../widgets/ai_disclaimer.dart';
import '../../widgets/ai_insight_card.dart';
import '../../widgets/ai_pick_tile.dart';
import '../../widgets/breaking_card.dart';
import '../../widgets/category_chip.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/error_state.dart';
import '../../widgets/loading_skeleton.dart';
import '../../widgets/app_logo.dart';
import '../../widgets/market_tile.dart';
import '../../widgets/news_card.dart';
import '../chat/ai_chat_screen.dart';
import '../news/article_detail_screen.dart';
import '../notifications/notifications_inbox_screen.dart';
import '../search/search_screen.dart';

const _categories = ['All', 'World', 'Stocks', 'Crypto', 'Gold', 'Forex', 'IPO', 'Economy'];

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Future<List<NewsArticle>> _newsFuture;
  late Future<List<NewsArticle>> _economyFuture;
  late Future<MarketOverview> _marketFuture;
  late Future<AiInsight?> _insightFuture;
  late Future<List<AiPick>> _aiPicksFuture;
  String _category = 'All';
  final _breakingController = PageController();
  Timer? _breakingTimer;
  int _breakingCount = 0;

  // Additional Latest News pages appended via "Load more". Kept separate from
  // the page-1 future so pull-to-refresh resets cleanly.
  final List<NewsArticle> _morePages = [];
  int _latestPage = 1;
  bool _loadingMore = false;
  bool _hasMore = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  String get _feedCategory => _category == 'All' ? 'business' : _category.toLowerCase();

  void _load() {
    // Any reload starts the Latest News list over from page 1.
    _morePages.clear();
    _latestPage = 1;
    _hasMore = true;
    _newsFuture = NewsService.instance.getFeed(category: _feedCategory);
    _economyFuture = NewsService.instance.getFeed(category: 'economy');
    _marketFuture = MarketService.instance.getOverview();
    _insightFuture = MarketService.instance.getInsight();
    _aiPicksFuture = MarketService.instance.getAiPicks();
  }

  Future<void> _refresh() async {
    setState(_load);
    await Future.wait([_newsFuture, _economyFuture, _marketFuture, _insightFuture, _aiPicksFuture]);
  }

  Future<void> _loadMoreLatest() async {
    if (_loadingMore || !_hasMore) return;
    setState(() => _loadingMore = true);

    final nextPage = _latestPage + 1;
    final more = await NewsService.instance.getFeed(category: _feedCategory, page: nextPage);
    if (!mounted) return;

    // The server paginates a cached pool; if that pool refreshes between pages
    // an article can repeat, so filter against what's already on screen.
    final shown = {
      ...(await _newsFuture).map((a) => a.id),
      ..._morePages.map((a) => a.id),
    };
    final fresh = more.where((a) => !shown.contains(a.id)).toList();
    if (!mounted) return;

    setState(() {
      _loadingMore = false;
      if (fresh.isEmpty) {
        _hasMore = false;
      } else {
        _latestPage = nextPage;
        _morePages.addAll(fresh);
      }
    });
  }

  void _selectCategory(String category) {
    setState(() {
      _category = category;
      _load();
    });
  }

  void _startBreakingAutoScroll(int count) {
    if (_breakingCount == count) return;
    _breakingCount = count;
    _breakingTimer?.cancel();
    if (count <= 1) return;

    _breakingTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (!_breakingController.hasClients) return;
      final next = ((_breakingController.page ?? 0).round() + 1) % count;
      _breakingController.animateToPage(next, duration: const Duration(milliseconds: 400), curve: Curves.easeInOut);
    });
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.lg, AppSpacing.md, AppSpacing.sm),
      child: Text(title, style: Theme.of(context).textTheme.titleLarge),
    );
  }

  Widget _marketRow(List items) {
    if (items.isEmpty) return const SizedBox.shrink();
    return SizedBox(
      // MarketTile's 3 text lines render taller than expected with the
      // Inter font's real metrics on-device — 96 clipped it (see memory).
      height: 120,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        itemCount: items.length,
        separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.sm),
        itemBuilder: (context, i) => MarketTile(item: items[i]),
      ),
    );
  }

  Widget _horizontalNewsRow(List<NewsArticle> articles) {
    if (articles.isEmpty) return const SizedBox.shrink();
    return SizedBox(
      // NewsCard needs room for title (2 lines) + source/time + AI badge +
      // bookmark/share buttons — 110 was sized for the older, simpler card.
      height: 168,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        itemCount: articles.length,
        separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.sm),
        itemBuilder: (context, i) => SizedBox(
          width: 220,
          child: NewsCard(
            article: articles[i],
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => ArticleDetailScreen(article: articles[i])),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _breakingTimer?.cancel();
    _breakingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const AppLogo(size: 28),
            const SizedBox(width: AppSpacing.sm),
            Text('FinBrief', style: Theme.of(context).textTheme.titleLarge),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SearchScreen())),
          ),
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const NotificationsInboxScreen()),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AiChatScreen())),
        child: const Icon(Icons.smart_toy_outlined),
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: FutureBuilder(
          future: Future.wait([_newsFuture, _economyFuture, _marketFuture, _insightFuture, _aiPicksFuture]),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return ListView(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                children: const [
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: AppSpacing.md),
                    child: NewsCardSkeleton(),
                  ),
                  SizedBox(height: AppSpacing.sm),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: AppSpacing.md),
                    child: NewsCardSkeleton(),
                  ),
                ],
              );
            }

            if (snapshot.hasError) {
              return ErrorState(message: 'Could not load your feed.', onRetry: () => setState(_load));
            }

            final articles = snapshot.data![0] as List<NewsArticle>;
            final economy = snapshot.data![1] as List<NewsArticle>;
            final market = snapshot.data![2] as MarketOverview;
            final insight = snapshot.data![3] as AiInsight?;
            final aiPicks = snapshot.data![4] as List<AiPick>;

            if (articles.isEmpty) {
              return const EmptyState(message: 'No news right now. Pull to refresh.', icon: Icons.newspaper_outlined);
            }

            final breaking = articles;
            final trending = articles;
            final latest = [...articles, ..._morePages];

            WidgetsBinding.instance.addPostFrameCallback((_) => _startBreakingAutoScroll(breaking.length));

            return ListView(
              // Bottom padding clears the chat FAB, which otherwise sits on top
              // of the last card and hides its actions.
              padding: const EdgeInsets.only(bottom: 88),
              children: [
                const SizedBox(height: AppSpacing.md),
                SizedBox(
                  height: 120,
                  // ClipRect because the adjacent page was bleeding past the
                  // viewport and showing its card outline at the screen edge.
                  // padEnds is gone with it: it only does anything when
                  // viewportFraction < 1, so here it was noise.
                  child: ClipRect(
                    child: PageView.builder(
                      controller: _breakingController,
                      itemCount: breaking.length,
                      itemBuilder: (context, i) => Padding(
                        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                        child: BreakingCard(
                          article: breaking[i],
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => ArticleDetailScreen(article: breaking[i])),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                if (insight != null)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.md, AppSpacing.md, 0),
                    child: AIInsightCard(insight: insight.insight),
                  ),
                _sectionTitle('Categories'),
                SizedBox(
                  height: 40,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                    itemCount: _categories.length,
                    separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.sm),
                    itemBuilder: (context, i) => CategoryChip(
                      label: _categories[i],
                      selected: _category == _categories[i],
                      onTap: () => _selectCategory(_categories[i]),
                    ),
                  ),
                ),
                _sectionTitle('Trending'),
                _horizontalNewsRow(trending),
                _sectionTitle('Market Indices'),
                _marketRow(market.indices),
                if (aiPicks.isNotEmpty) ...[
                  // Named for what it is: companies the day's news is about.
                  // It is deliberately not "Picks" — naming stocks with a call
                  // attached reads as a recommendation, which this is not.
                  _sectionTitle('In Focus Today'),
                  SizedBox(
                    // Name/sentiment row + 2-line reason — same tight-fit risk
                    // as the market row above.
                    height: 128,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                      itemCount: aiPicks.length,
                      separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.sm),
                      itemBuilder: (context, i) => AiPickTile(pick: aiPicks[i]),
                    ),
                  ),
                  const AiDisclaimer(compact: true),
                ],
                _sectionTitle('Latest News'),
                ...latest.map(
                  (article) => Padding(
                    padding: const EdgeInsets.fromLTRB(AppSpacing.md, 0, AppSpacing.md, AppSpacing.sm),
                    child: NewsCard(
                      article: article,
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => ArticleDetailScreen(article: article)),
                      ),
                    ),
                  ),
                ),
                if (_hasMore)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                    child: OutlinedButton(
                      onPressed: _loadingMore ? null : _loadMoreLatest,
                      child: _loadingMore
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                          : const Text('Load more'),
                    ),
                  ),
                _sectionTitle('Crypto'),
                _marketRow(market.crypto),
                // Only rendered when the backend actually returned data
                // (Finnhub configured) — no empty/fake section otherwise.
                if (market.globalMarkets.isNotEmpty) ...[
                  _sectionTitle('Global Markets'),
                  _marketRow(market.globalMarkets),
                ],
                _sectionTitle('Gold'),
                _marketRow(market.gold),
                _sectionTitle('Forex'),
                _marketRow(market.forex),
                if (economy.isNotEmpty) ...[
                  _sectionTitle('Economy'),
                  _horizontalNewsRow(economy),
                ],
                _sectionTitle('IPO Calendar'),
                ...market.ipoCalendar.map((ipo) => _IpoTile(ipo: ipo)),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _IpoTile extends StatelessWidget {
  final IpoEvent ipo;
  const _IpoTile({required this.ipo});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.fromLTRB(AppSpacing.md, 0, AppSpacing.md, AppSpacing.sm),
      child: ListTile(
        title: Text(ipo.company),
        subtitle: Text('${ipo.openDate} → ${ipo.closeDate}'),
        trailing: Text(ipo.priceRange, style: const TextStyle(fontWeight: FontWeight.w600)),
      ),
    );
  }
}
