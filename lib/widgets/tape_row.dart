import 'package:flutter/material.dart';
import '../models/news_article.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../utils/time_format.dart';

/// A single line in the live tape — dense by design, so a lot of headlines
/// fit on screen the way a trader-style feed does.
class TapeRow extends StatelessWidget {
  final NewsArticle article;
  final VoidCallback onTap;

  const TapeRow({super.key, required this.article, required this.onTap});

  Color _priorityColor() {
    switch (article.priority) {
      case 'high':
        return AppColors.danger;
      case 'medium':
        return AppColors.primary;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isHigh = article.priority == 'high';

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Left accent bar communicates priority at a glance.
            Container(
              width: 3,
              height: 38,
              margin: const EdgeInsets.only(right: AppSpacing.sm, top: 2),
              decoration: BoxDecoration(
                color: _priorityColor(),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      if (isHigh) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                          decoration: BoxDecoration(
                            color: AppColors.danger,
                            borderRadius: BorderRadius.circular(3),
                          ),
                          child: const Text(
                            'BREAKING',
                            style: TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold),
                          ),
                        ),
                        const SizedBox(width: 6),
                      ],
                      Text(
                        timeAgo(article.publishedAt),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 11),
                      ),
                      if (article.category != null) ...[
                        const Text(' · ', style: TextStyle(fontSize: 11, color: Colors.grey)),
                        Text(
                          article.category!,
                          style: TextStyle(fontSize: 11, color: Theme.of(context).colorScheme.primary),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    article.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, height: 1.25),
                  ),
                  // The personalisation payoff — why this matters to this user.
                  if (article.relevanceLabel != null) ...[
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Icon(
                          article.relevanceDirect ? Icons.account_balance_wallet : Icons.link,
                          size: 11,
                          color: AppColors.success,
                        ),
                        const SizedBox(width: 3),
                        Expanded(
                          child: Text(
                            article.relevanceLabel!,
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.success,
                              fontWeight: FontWeight.w600,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                  if (article.source != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      article.source!,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 10),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
