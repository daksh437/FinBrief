import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/ai_summary.dart';
import '../../models/news_article.dart';
import '../../services/ai_service.dart';
import '../../services/analytics_service.dart';
import '../../services/news_service.dart';
import '../../services/reading_history_service.dart';
import '../../services/share_service.dart';
import '../../services/squawk_service.dart';
import '../../theme/app_spacing.dart';
import '../../utils/time_format.dart';
import '../../widgets/ask_ai_bar.dart';
import '../../widgets/bookmark_button.dart';
import '../../widgets/impact_card.dart';
import '../../widgets/loading_skeleton.dart';
import '../../widgets/news_card.dart';
import '../../widgets/summary_card.dart';

class ArticleDetailScreen extends StatefulWidget {
  final NewsArticle article;
  const ArticleDetailScreen({super.key, required this.article});

  @override
  State<ArticleDetailScreen> createState() => _ArticleDetailScreenState();
}

class _ArticleDetailScreenState extends State<ArticleDetailScreen> {
  late final Future<List<NewsArticle>> _relatedFuture;

  AiSummary? _summary;
  MarketImpact? _impact;
  String? _explanation;
  String? _explanationMode;

  bool _summaryLoading = false;
  bool _impactLoading = false;
  bool _explainLoading = false;
  bool _voiceLoading = false;
  bool _isPlaying = false;
  bool _bookmarked = false;
  String? _error;

  String get _sourceText =>
      (widget.article.summary?.isNotEmpty ?? false) ? widget.article.summary! : widget.article.title;

  /// What the Listen button reads out: the generated AI summary when there is
  /// one, otherwise the headline and article snippet.
  String get _spokenText {
    final points = _summary?.keyPoints ?? const <String>[];
    if (points.isNotEmpty) {
      return '${widget.article.title}. ${points.join('. ')}';
    }
    return '${widget.article.title}. $_sourceText';
  }

  @override
  void initState() {
    super.initState();
    _relatedFuture = NewsService.instance
        .getFeed()
        .then((articles) => articles.where((a) => a.id != widget.article.id).take(5).toList());
    ReadingHistoryService.add(widget.article);
    AnalyticsService.instance.logArticleOpened(widget.article.id);
  }

  @override
  void dispose() {
    // The TTS engine is shared, so stop playback rather than disposing it —
    // leaving the article shouldn't keep reading it aloud.
    SquawkService.instance.stop();
    super.dispose();
  }

  /// Maps AI failures onto a single friendly message. Credit exhaustion gets
  /// its own copy since it's an expected state, not an error.
  String _messageFor(Object error) {
    if (error is AiInsufficientCreditsException) {
      return "You've used today's free AI credits. Upgrade to Premium for unlimited access.";
    }
    return 'Something went wrong. Please try again.';
  }

  Future<void> _loadSummary() async {
    setState(() {
      _summaryLoading = true;
      _error = null;
    });
    try {
      final summary = await AiService.instance.summarizeStructured(_sourceText);
      if (mounted) setState(() => _summary = summary);
      AnalyticsService.instance.logAiAction('summary');
    } catch (e) {
      if (mounted) setState(() => _error = _messageFor(e));
    } finally {
      if (mounted) setState(() => _summaryLoading = false);
    }
  }

  Future<void> _loadImpact() async {
    setState(() {
      _impactLoading = true;
      _error = null;
    });
    try {
      final impact = await AiService.instance.analyzeMarketImpact(_sourceText);
      if (mounted) setState(() => _impact = impact);
      AnalyticsService.instance.logAiAction('impact');
    } catch (e) {
      if (mounted) setState(() => _error = _messageFor(e));
    } finally {
      if (mounted) setState(() => _impactLoading = false);
    }
  }

  Future<void> _askAi(String mode) async {
    setState(() {
      _explainLoading = true;
      _explanationMode = mode;
      _explanation = null;
      _error = null;
    });
    try {
      final explanation = await AiService.instance.explain(_sourceText, mode);
      if (mounted) setState(() => _explanation = explanation);
      AnalyticsService.instance.logAiAction('explain_$mode');
    } catch (e) {
      if (mounted) setState(() => _error = _messageFor(e));
    } finally {
      if (mounted) setState(() => _explainLoading = false);
    }
  }

  Future<void> _toggleVoiceSummary() async {
    if (_isPlaying) {
      await SquawkService.instance.stop();
      if (mounted) setState(() => _isPlaying = false);
      return;
    }

    setState(() {
      _voiceLoading = true;
      _isPlaying = true;
      _error = null;
    });
    try {
      // Prefer the AI summary if the user has generated one — that's the
      // digestible version worth listening to; otherwise read the article text.
      await SquawkService.instance.readAloud(_spokenText);
    } catch (e) {
      if (mounted) setState(() => _error = _messageFor(e));
    } finally {
      // readAloud completes when the engine stops speaking, so both flags
      // reset together.
      if (mounted) {
        setState(() {
          _voiceLoading = false;
          _isPlaying = false;
        });
      }
    }
  }

  Future<void> _toggleBookmark() async {
    setState(() => _bookmarked = !_bookmarked);
    if (_bookmarked) {
      await NewsService.instance.addBookmark(widget.article);
    } else {
      await NewsService.instance.removeBookmark(widget.article.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final article = widget.article;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Article'),
        actions: [
          BookmarkButton(bookmarked: _bookmarked, onPressed: _toggleBookmark),
          IconButton(
            tooltip: 'Share',
            icon: const Icon(Icons.share_outlined),
            onPressed: () => ShareService.shareArticle(article),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          SelectableText(article.title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(
                child: Text(
                  [article.source, timeAgo(article.publishedAt)].where((s) => s != null && s.isNotEmpty).join(' • '),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
              IconButton(
                visualDensity: VisualDensity.compact,
                tooltip: 'Copy headline',
                icon: const Icon(Icons.copy_outlined, size: 18),
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: article.title));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Headline copied')),
                  );
                },
              ),
            ],
          ),
          if (article.summary != null) ...[
            const SizedBox(height: AppSpacing.md),
            SelectableText(article.summary!, style: Theme.of(context).textTheme.bodyMedium),
          ],

          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              Expanded(
                child: FilledButton.tonalIcon(
                  onPressed: _summaryLoading ? null : _loadSummary,
                  icon: const Icon(Icons.auto_awesome, size: 18),
                  label: Text(_summary == null ? 'AI Summary' : 'Regenerate'),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              IconButton.filledTonal(
                tooltip: _isPlaying ? 'Stop' : 'Listen',
                onPressed: _voiceLoading ? null : _toggleVoiceSummary,
                icon: _voiceLoading
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                    : Icon(_isPlaying ? Icons.stop : Icons.volume_up_outlined),
              ),
            ],
          ),

          if (_summaryLoading) ...[
            const SizedBox(height: AppSpacing.md),
            const _CardSkeleton(),
          ] else if (_summary != null) ...[
            const SizedBox(height: AppSpacing.md),
            SummaryCard(summary: _summary!),
          ],

          const SizedBox(height: AppSpacing.md),
          FilledButton.tonalIcon(
            onPressed: _impactLoading ? null : _loadImpact,
            icon: const Icon(Icons.insights_outlined, size: 18),
            label: Text(_impact == null ? 'Market Impact' : 'Refresh impact'),
          ),
          if (_impactLoading) ...[
            const SizedBox(height: AppSpacing.md),
            const _CardSkeleton(),
          ] else if (_impact != null) ...[
            const SizedBox(height: AppSpacing.md),
            ImpactCard(impact: _impact!),
          ],

          const SizedBox(height: AppSpacing.lg),
          AskAIBar(onAction: _askAi, activeMode: _explanationMode, loading: _explainLoading),
          if (_explainLoading) ...[
            const SizedBox(height: AppSpacing.md),
            const _CardSkeleton(),
          ] else if (_explanation != null) ...[
            const SizedBox(height: AppSpacing.md),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            askAiActions.firstWhere((a) => a.mode == _explanationMode).label,
                            style: Theme.of(context).textTheme.titleSmall,
                          ),
                        ),
                        IconButton(
                          visualDensity: VisualDensity.compact,
                          tooltip: 'Copy',
                          icon: const Icon(Icons.copy_outlined, size: 18),
                          onPressed: () {
                            Clipboard.setData(ClipboardData(text: _explanation!));
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Copied')),
                            );
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    SelectableText(_explanation!, style: Theme.of(context).textTheme.bodyMedium),
                  ],
                ),
              ),
            ),
          ],

          if (_error != null) ...[
            const SizedBox(height: AppSpacing.md),
            Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
          ],

          const SizedBox(height: AppSpacing.lg),
          Text('Related News', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: AppSpacing.sm),
          FutureBuilder<List<NewsArticle>>(
            future: _relatedFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const NewsCardSkeleton();
              }
              final related = snapshot.data ?? [];
              if (related.isEmpty) return const SizedBox.shrink();
              return Column(
                children: related
                    .map((a) => Padding(
                          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                          child: NewsCard(
                            article: a,
                            onTap: () => Navigator.of(context).pushReplacement(
                              MaterialPageRoute(builder: (_) => ArticleDetailScreen(article: a)),
                            ),
                          ),
                        ))
                    .toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _CardSkeleton extends StatelessWidget {
  const _CardSkeleton();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            LoadingSkeleton(height: 14, width: 140),
            SizedBox(height: AppSpacing.sm),
            LoadingSkeleton(height: 12, width: double.infinity),
            SizedBox(height: 6),
            LoadingSkeleton(height: 12, width: double.infinity),
            SizedBox(height: 6),
            LoadingSkeleton(height: 12, width: 180),
          ],
        ),
      ),
    );
  }
}
