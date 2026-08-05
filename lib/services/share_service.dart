import 'package:share_plus/share_plus.dart';
import '../models/news_article.dart';

class ShareService {
  ShareService._();

  static Future<void> shareArticle(NewsArticle article) {
    final text = article.url != null ? '${article.title}\n${article.url}' : article.title;
    return SharePlus.instance.share(ShareParams(text: text, subject: article.title));
  }

  static Future<void> shareText(String text) {
    return SharePlus.instance.share(ShareParams(text: text));
  }
}
