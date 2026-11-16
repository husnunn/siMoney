import 'package:flutter/material.dart';

import '../../../models/models.dart';
import '../../../state/app_store.dart';
import '../../../state/savings_goal_planning.dart';
import '../../../state/savings_planner.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_spacing.dart';
import '../../../utils/formatters.dart';
import '../../../widgets/savings_progress_bar.dart';
import '../../../widgets/status_pill.dart';
import 'goal_status_pill.dart';
import 'period_figures_grid.dart';

/// Body of the list card of a Target Akhir goal: deadline, progress, what to
/// save per day / week / month / year, and whether the pace is enough.
class FinalGoalCardBody extends StatelessWidget {
  const FinalGoalCardBody({super.key, required this.goal});

  final SavingsGoal goal;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final saved = appStore.goalProgress(goal.id);
    final plan = goal.finalPlan(saved: saved);
    final isActive = goal.status == SavingsGoalStatus.active;
    final showPlan =
        plan != null && isActive && !plan.isReached && !plan.isOverdue;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                goal.name,
                style: textTheme.labelLarge,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            GoalStatusPill(goal: goal),
            if (goal.adjustForInflation && plan != null) ...[
              const SizedBox(width: AppSpacing.xs),
              StatusPill(
                label: 'Inflasi ${formatPercent(plan.inflationRate)}',
                color: AppColors.primary,
                icon: Icons.trending_up,
              ),
            ],
          ],
        ),
        if (plan != null) ...[
          const SizedBox(height: AppSpacing.xxs),
          Text(
            'Tenggat ${formatDateShort(plan.deadline)} · '
            '${formatTimeLeft(plan.daysLeft)}',
            style: textTheme.bodySmall,
          ),
        ],
        const SizedBox(height: AppSpacing.sm),
        SavingsProgressBar(progress: saved, target: goal.completionTarget()),
        if (showPlan) ...[
          const SizedBox(height: AppSpacing.gutter),
          PeriodFiguresStrip(figures: plan.required),
          const SizedBox(height: AppSpacing.sm),
          _PacePill(
            goal: goal,
            plan: plan,
            contributions: appStore.contributionsForGoal(goal.id),
          ),
        ] else if (plan == null && isActive) ...[
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Tambahkan tenggat untuk melihat rencana setoran.',
            style: textTheme.bodySmall,
          ),
        ],
      ],
    );
  }
}

class _PacePill extends StatelessWidget {
  const _PacePill({
    required this.goal,
    required this.plan,
    required this.contributions,
  });

  final SavingsGoal goal;
  final FinalGoalPlan plan;
  final List<SavingsContribution> contributions;

  @override
  Widget build(BuildContext context) {
    final recent = goal.recentPace(contributions);
    final gap = plan.monthlyGap(recent.pace);

    if (recent.pace <= 0) {
      return const StatusPill(
        label: 'Belum ada setoran',
        color: AppColors.outline,
      );
    }
    if (gap <= 0) {
      return const StatusPill(
        label: 'Di jalur',
        color: AppColors.income,
        icon: Icons.check,
      );
    }
    return StatusPill(
      label: 'Kurang ${formatRupiahCompact(gap)}/bln',
      color: AppColors.primary,
      icon: Icons.trending_up,
    );
  }
}
