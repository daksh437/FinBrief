import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

/// A selectable billing period on the paywall.
///
/// The card used to repeat the benefit list per plan, which made the three
/// options look like three different products. They aren't — the same Premium
/// at three billing periods — so the benefits are listed once above and each
/// card carries only price and saving. That also keeps the whole choice on one
/// screen without scrolling, which is where the conversion is.
class PlanCard extends StatelessWidget {
  final String name;
  final String price;
  final String? subtitle;
  final String? badge;
  final bool highlighted;

  /// Whether this is the selected plan (the paywall preselects yearly).
  final bool isCurrent;
  final VoidCallback? onPressed;

  const PlanCard({
    super.key,
    required this.name,
    required this.price,
    this.subtitle,
    this.badge,
    this.highlighted = false,
    this.isCurrent = false,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final borderColour = isCurrent
        ? AppColors.primary
        : theme.colorScheme.outlineVariant;

    return Card(
      margin: EdgeInsets.zero,
      elevation: isCurrent ? 2 : 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        side: BorderSide(color: borderColour, width: isCurrent ? 2 : 1),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        onTap: onPressed,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              Icon(
                isCurrent ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                color: isCurrent ? AppColors.primary : theme.hintColor,
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(name, style: theme.textTheme.titleMedium),
                        if (badge != null) ...[
                          const SizedBox(width: AppSpacing.sm),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: highlighted ? AppColors.success : theme.colorScheme.surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              badge!,
                              style: TextStyle(
                                color: highlighted ? Colors.white : theme.colorScheme.onSurfaceVariant,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(subtitle!, style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor)),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                price,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
