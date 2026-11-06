import 'package:flutter/material.dart';

import '../state/analytics_calculator.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/category_colors.dart';
import '../utils/formatters.dart';

/// Ranked list of category spending, each row showing a proportional bar
/// against the largest category in [segments] (already sorted descending).
class CategoryRankList extends StatelessWidget {
  const CategoryRankList({
    super.key,
    required this.segments,
    this.selectedCategoryId,
    this.onCategoryTap,
  });

  final List<CategorySpend> segments;
  final String? selectedCategoryId;
  final ValueChanged<String?>? onCategoryTap;

  @override
  Widget build(BuildContext context) {
    if (segments.isEmpty) return const SizedBox.shrink();
    final maxTotal = segments.first.total;

    return Column(
      children: [
        for (var i = 0; i < segments.length; i++) ...[
          if (i > 0) const SizedBox(height: AppSpacing.sm),
          _CategoryRankRow(
            segment: segments[i],
            maxTotal: maxTotal,
            selected: selectedCategoryId == segments[i].categoryId,
            onTap: onCategoryTap == null
                ? null
                : () => onCategoryTap!(
                      selectedCategoryId == segments[i].categoryId
                          ? null
                          : segments[i].categoryId,
                    ),
          ),
        ],
      ],
    );
  }
}

class _CategoryRankRow extends StatelessWidget {
  const _CategoryRankRow({
    required this.segment,
    required this.maxTotal,
    required this.selected,
    this.onTap,
  });

  final CategorySpend segment;
  final int maxTotal;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final isOther = segment.categoryId == AnalyticsCalculator.otherCategoryId;
    final color = isOther
        ? AppColors.outlineVariant
        : CategoryColors.forCategoryId(segment.categoryId);
    final widthFactor = maxTotal == 0 ? 0.0 : segment.total / maxTotal;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.sm),
        decoration: BoxDecoration(
          color: selected ? AppColors.surfaceContainer : null,
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(segment.icon, size: 16, color: color),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: Text(
                    segment.categoryName,
                    style: textTheme.bodyMedium,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(formatRupiah(segment.total), style: textTheme.labelLarge),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                    child: Stack(
                      children: [
                        Container(
                          height: 6,
                          color: AppColors.surfaceContainerHigh,
                        ),
                        FractionallySizedBox(
                          widthFactor: widthFactor.clamp(0, 1),
                          child: Container(height: 6, color: color),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                SizedBox(
                  width: 40,
                  child: Text(
                    '${segment.percentOfTotal.toStringAsFixed(0)}%',
                    style: textTheme.bodySmall,
                    textAlign: TextAlign.end,
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
