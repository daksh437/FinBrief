import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../models/news_article.dart';
import '../services/news_service.dart';
import '../services/share_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../utils/time_format.dart';

class NewsCard extends StatefulWidget {
  final NewsArticle article;
  final VoidCallback onTap;

  const NewsCard({super.key, required this.article, required this.onTap});

  @override
  State<NewsCard> createState() => _NewsCardState();
}

class _NewsCardState extends State<NewsCard> {
  bool _bookmarked = false;

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

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        onTap: widget.onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (article.imageUrl != null) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppSpacing.sm),
                  child: CachedNetworkImage(
                    imageUrl: article.imageUrl!,
                    width: 64,
                    height: 64,
                    fit: BoxFit.cover,
                    // Reserve the slot on failure/while loading so the card
                    // layout doesn't jump around as images resolve.
                    errorWidget: (_, _, _) => const SizedBox(width: 64, height: 64),
                    placeholder: (_, _) => const SizedBox(width: 64, height: 64),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      article.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            [article.source, timeAgo(article.publishedAt)].where((s) => s != null && s.isNotEmpty).join(' • '),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                                ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.auto_awesome, size: 11, color: AppColors.primary),
                              const SizedBox(width: 2),
                              Text('AI', style: TextStyle(fontSize: 10, color: AppColors.primary, fontWeight: FontWeight.w600)),
                            ],
                          ),
                        ),
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        IconButton(
                          visualDensity: VisualDensity.compact,
                          icon: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 200),
                            transitionBuilder: (child, anim) => ScaleTransition(scale: anim, child: child),
                            child: Icon(
                              _bookmarked ? Icons.bookmark : Icons.bookmark_outline,
                              key: ValueKey(_bookmarked),
                              size: 20,
                            ),
                          ),
                          onPressed: _toggleBookmark,
                        ),
                        IconButton(
                          visualDensity: VisualDensity.compact,
                          icon: const Icon(Icons.share_outlined, size: 20),
                          onPressed: () => ShareService.shareArticle(article),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
