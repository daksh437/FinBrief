import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

class PlanCard extends StatelessWidget {
  final String name;
  final String price;
  final List<String> features;
  final bool highlighted;
  final bool isCurrent;
  final VoidCallback? onPressed;

  const PlanCard({
    super.key,
    required this.name,
    required this.price,
    required this.features,
    this.highlighted = false,
    this.isCurrent = false,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        side: highlighted ? const BorderSide(color: AppColors.primary, width: 2) : BorderSide.none,
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(name, style: Theme.of(context).textTheme.titleLarge),
                if (highlighted)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(6)),
                    child: const Text('Most Popular', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text(price, style: Theme.of(context).textTheme.titleMedium?.copyWith(color: AppColors.primary)),
            const SizedBox(height: AppSpacing.sm),
            ...features.map(
              (f) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle, size: 16, color: AppColors.success),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(child: Text(f, style: Theme.of(context).textTheme.bodyMedium)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            SizedBox(
              width: double.infinity,
              child: isCurrent
                  ? OutlinedButton(onPressed: null, child: const Text('Current Plan'))
                  : FilledButton(onPressed: onPressed, child: const Text('Choose Plan')),
            ),
          ],
        ),
      ),
    );
  }
}
