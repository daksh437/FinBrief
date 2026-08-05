import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/ai_summary.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

class SummaryCard extends StatelessWidget {
  final AiSummary summary;

  const SummaryCard({super.key, required this.summary});

  String get _copyText {
    final points = summary.keyPoints.map((p) => '• $p').join('\n');
    return points.isEmpty ? summary.summary : '${summary.summary}\n\n$points';
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.auto_awesome, size: 18, color: AppColors.primary),
                const SizedBox(width: AppSpacing.sm),
                Text('AI Summary', style: Theme.of(context).textTheme.titleSmall),
                const Spacer(),
                if (summary.confidence > 0) _ConfidenceChip(confidence: summary.confidence),
                IconButton(
                  visualDensity: VisualDensity.compact,
                  icon: const Icon(Icons.copy_outlined, size: 18),
                  tooltip: 'Copy summary',
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: _copyText));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Summary copied')),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            SelectableText(summary.summary, style: Theme.of(context).textTheme.bodyMedium),
            if (summary.keyPoints.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.md),
              Text('Key points', style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 4),
              ...summary.keyPoints.map(
                (point) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('•  '),
                      Expanded(child: Text(point, style: Theme.of(context).textTheme.bodyMedium)),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ConfidenceChip extends StatelessWidget {
  final double confidence;

  const _ConfidenceChip({required this.confidence});

  @override
  Widget build(BuildContext context) {
    final percent = (confidence * 100).clamp(0, 100).round();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        '$percent% confident',
        style: const TextStyle(fontSize: 10, color: AppColors.primary, fontWeight: FontWeight.w600),
      ),
    );
  }
}
