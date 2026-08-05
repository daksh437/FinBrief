import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

class CreditCardTile extends StatelessWidget {
  final String label;
  final int credits;
  final String price;
  final VoidCallback? onPressed;

  const CreditCardTile({
    super.key,
    required this.label,
    required this.credits,
    required this.price,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: [
            const Icon(Icons.bolt_rounded, color: AppColors.primary, size: 32),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: Theme.of(context).textTheme.titleSmall),
                  Text('$credits credits', style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ),
            FilledButton(onPressed: onPressed, child: Text(price)),
          ],
        ),
      ),
    );
  }
}
