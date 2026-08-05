import 'package:flutter/material.dart';
import '../../models/news_article.dart';
import '../../services/news_service.dart';
import '../news/article_detail_screen.dart';

class BookmarksScreen extends StatefulWidget {
  const BookmarksScreen({super.key});

  @override
  State<BookmarksScreen> createState() => _BookmarksScreenState();
}

class _BookmarksScreenState extends State<BookmarksScreen> {
  late Future<List<NewsArticle>> _bookmarks;

  @override
  void initState() {
    super.initState();
    _bookmarks = NewsService.instance.getBookmarks();
  }

  void _reload() => setState(() => _bookmarks = NewsService.instance.getBookmarks());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Bookmarks')),
      body: FutureBuilder<List<NewsArticle>>(
        future: _bookmarks,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final articles = snapshot.data ?? [];
          if (articles.isEmpty) {
            return const Center(child: Text('No bookmarks yet.'));
          }
          return ListView.separated(
            itemCount: articles.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final article = articles[index];
              return ListTile(
                title: Text(article.title, maxLines: 2, overflow: TextOverflow.ellipsis),
                subtitle: Text(article.source ?? ''),
                trailing: IconButton(
                  icon: const Icon(Icons.bookmark_remove_outlined),
                  onPressed: () async {
                    await NewsService.instance.removeBookmark(article.id);
                    _reload();
                  },
                ),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => ArticleDetailScreen(article: article)),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
