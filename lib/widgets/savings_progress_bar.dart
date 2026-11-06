import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../utils/formatters.dart';

class SavingsProgressBar extends StatelessWidget {
  const SavingsProgressBar({
    super.key,
    required this.progress,
    required this.target,
  });

  final int progress;
  final int target;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final ratio = target > 0 ? (progress / target).clamp(0.0, 1.0) : 0.0;
    final isComplete = progress >= target;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: ratio,
            minHeight: 8,
            backgroundColor: AppColors.surfaceContainerHighest,
            color: isComplete ? AppColors.income : AppColors.primary,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              formatRupiah(progress),
              style: textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.onSurface,
              ),
            ),
            Text(
              'dari ${formatRupiah(target)}',
              style: textTheme.bodySmall,
            ),
          ],
        ),
      ],
    );
  }
}
