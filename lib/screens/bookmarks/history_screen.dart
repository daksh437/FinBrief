import 'package:flutter/material.dart';
import '../../models/news_article.dart';
import '../../services/reading_history_service.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/news_card.dart';
import '../news/article_detail_screen.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  late Future<List<NewsArticle>> _history;

  @override
  void initState() {
    super.initState();
    _history = ReadingHistoryService.getHistory();
  }

  void _reload() => setState(() => _history = ReadingHistoryService.getHistory());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reading History'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: () async {
              await ReadingHistoryService.clear();
              _reload();
            },
          ),
        ],
      ),
      body: FutureBuilder<List<NewsArticle>>(
        future: _history,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final articles = snapshot.data ?? [];
          if (articles.isEmpty) {
            return const EmptyState(message: 'Articles you read will show up here.', icon: Icons.history);
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: articles.length,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (context, i) => NewsCard(
              article: articles[i],
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => ArticleDetailScreen(article: articles[i])),
              ),
            ),
          );
        },
      ),
    );
  }
}
