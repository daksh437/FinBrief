import 'package:flutter/material.dart';
import '../models/news_article.dart';
import '../theme/app_colors.dart';
import 'app_logo.dart';

/// The image a user forwards to WhatsApp.
///
/// This is how apps spread in India — not through store search, but because
/// someone shares something into a family or trading group. So the card has to
/// stand on its own: readable at thumbnail size, obviously from FinBrief, and
/// worth forwarding even to someone who has never heard of the app.
///
/// Rendered off-screen and captured to PNG by ShareService. It is a plain
/// widget with a fixed width so the output is the same on every device —
/// nothing here should depend on MediaQuery.
class ShareCard extends StatelessWidget {
  const ShareCard({
    super.key,
    required this.article,
    required this.summary,
    this.keyPoints = const [],
  });

  final NewsArticle article;
  final String summary;
  final List<String> keyPoints;

  /// Logical width of the card. Captured at 3x, giving a ~1200px image —
  /// sharp on a phone, and small enough that WhatsApp won't crush it.
  static const width = 400.0;

  @override
  Widget build(BuildContext context) {
    // Deliberately not inheriting the app's theme: the card must look the same
    // whether the user is in dark mode or not, because the person receiving it
    // has no context for why it might be black.
    return Material(
      color: Colors.white,
      child: Container(
        width: width,
        padding: const EdgeInsets.all(22),
        decoration: const BoxDecoration(color: Colors.white),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const AppLogo(size: 30),
                const SizedBox(width: 8),
                const Text(
                  'FinBrief',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: AppColors.text,
                  ),
                ),
                const Spacer(),
                if (article.source != null)
                  Flexible(
                    child: Text(
                      article.source!,
                      textAlign: TextAlign.right,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 11, color: Colors.black54),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),

            Text(
              article.title,
              // Long headlines are common; clipping is better than a card that
              // grows until the text is unreadable at thumbnail size.
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 19,
                height: 1.3,
                fontWeight: FontWeight.bold,
                color: AppColors.text,
              ),
            ),
            const SizedBox(height: 14),

            if (keyPoints.isNotEmpty)
              ...keyPoints.take(3).map(
                    (point) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            margin: const EdgeInsets.only(top: 7, right: 9),
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                            ),
                          ),
                          Expanded(
                            child: Text(
                              point,
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 14, height: 1.4, color: Colors.black87),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
            else
              Text(
                summary,
                maxLines: 6,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 14, height: 1.5, color: Colors.black87),
              ),

            const SizedBox(height: 16),
            const Divider(height: 1),
            const SizedBox(height: 12),

            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Summarised by AI · may be inaccurate',
                    style: TextStyle(fontSize: 10, color: Colors.black45),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    'Get FinBrief',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
