import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../theme/app_spacing.dart';

class LoadingSkeleton extends StatelessWidget {
  final double height;
  final double? width;
  final BorderRadius? borderRadius;

  const LoadingSkeleton({
    super.key,
    this.height = 16,
    this.width,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    final baseColor = Theme.of(context).colorScheme.surfaceContainerHighest;
    final highlightColor = Theme.of(context).colorScheme.surfaceContainerLowest;

    return Shimmer.fromColors(
      baseColor: baseColor,
      highlightColor: highlightColor,
      child: Container(
        height: height,
        width: width,
        decoration: BoxDecoration(
          color: baseColor,
          borderRadius: borderRadius ?? BorderRadius.circular(AppSpacing.sm),
        ),
      ),
    );
  }
}

class NewsCardSkeleton extends StatelessWidget {
  const NewsCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            LoadingSkeleton(height: 16, width: double.infinity),
            SizedBox(height: AppSpacing.sm),
            LoadingSkeleton(height: 16, width: 200),
            SizedBox(height: AppSpacing.sm),
            LoadingSkeleton(height: 12, width: 100),
          ],
        ),
      ),
    );
  }
}
