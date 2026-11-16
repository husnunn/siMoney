import 'package:flutter/material.dart';

import '../../../models/models.dart';
import '../../../state/savings_planner.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_spacing.dart';
import 'period_figures_grid.dart';

/// One compact card summing up what all goals of a tab ask for per day, week,
/// month and year. Kept short so the goal list stays near the top of the tab.
class PlanSummaryCard extends StatelessWidget {
  const PlanSummaryCard({
    super.key,
    required this.title,
    required this.caption,
    required this.figures,
    this.highlight = PeriodUnit.month,
  });

  final String title;
  final String caption;
  final PeriodFigures figures;
  final PeriodUnit? highlight;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainer,
        border: Border.all(color: AppColors.outlineVariant),
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: textTheme.labelLarge),
          const SizedBox(height: AppSpacing.xxs),
          Text(caption, style: textTheme.bodySmall),
          const SizedBox(height: AppSpacing.gutter),
          PeriodFiguresStrip(figures: figures, highlight: highlight),
        ],
      ),
    );
  }
}
