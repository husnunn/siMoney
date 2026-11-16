import 'package:flutter/material.dart';

import '../../../models/models.dart';
import '../../../state/app_store.dart';
import '../../../state/savings_goal_planning.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_spacing.dart';
import '../../../utils/formatters.dart';
import '../../../widgets/status_pill.dart';
import 'goal_status_pill.dart';
import 'period_figures_grid.dart';

/// Body of the list card of a Target Berkala goal: the fixed amount, its
/// equivalents, what is saved so far and this period's status.
class PeriodicGoalCardBody extends StatelessWidget {
  const PeriodicGoalCardBody({super.key, required this.goal});

  final SavingsGoal goal;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final plan = goal.periodicPlan();
    final amount = goal.periodicAmount ?? 0;
    final unit = goal.periodUnit ?? PeriodUnit.month;
    final saved = appStore.goalProgress(goal.id);
    final isActive = goal.status == SavingsGoalStatus.active;
    final adherence = goal.adherence(
      contributions: appStore.contributionsForGoal(goal.id),
    );
    final start = goal.startDate ?? goal.createdAt;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.repeat, size: 18, color: AppColors.primary),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                goal.name,
                style: textTheme.labelLarge,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            GoalStatusPill(goal: goal),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          '${formatRupiah(amount)} ${unit.perLabel}',
          style: textTheme.titleMedium?.copyWith(color: AppColors.primary),
        ),
        Text(
          'Tanpa tenggat · sejak ${formatDateShort(start)}',
          style: textTheme.bodySmall,
        ),
        if (plan != null) ...[
          const SizedBox(height: AppSpacing.gutter),
          PeriodFiguresStrip(figures: plan.figures, highlight: unit),
        ],
        const SizedBox(height: AppSpacing.gutter),
        Row(
          children: [
            Expanded(
              child: Text(
                'Terkumpul ${formatRupiah(saved)}',
                style: textTheme.labelLarge,
              ),
            ),
          ],
        ),
        if (isActive && adherence != null) ...[
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.xs,
            children: [
              if (!adherence.started)
                StatusPill(
                  label: 'Mulai ${formatDateShort(start)}',
                  color: AppColors.outline,
                  icon: Icons.event_outlined,
                )
              else if (adherence.currentFulfilled)
                StatusPill(
                  label: '${unit.label} ini terpenuhi',
                  color: AppColors.income,
                  icon: Icons.check,
                )
              else
                StatusPill(
                  label: 'Kurang '
                      '${formatRupiahCompact(adherence.currentRemaining.toDouble())} '
                      'sebelum ${formatDateShort(adherence.currentPeriodEnd)}',
                  color: AppColors.primary,
                  icon: Icons.schedule,
                ),
              if (adherence.streak > 1)
                StatusPill(
                  label: 'Beruntun ${adherence.streak} '
                      '${unit.label.toLowerCase()}',
                  color: AppColors.secondary,
                  icon: Icons.local_fire_department_outlined,
                ),
            ],
          ),
        ],
      ],
    );
  }
}
