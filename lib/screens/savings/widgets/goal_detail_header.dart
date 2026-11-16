import 'package:flutter/material.dart';

import '../../../models/models.dart';
import '../../../state/savings_goal_planning.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_spacing.dart';
import '../../../utils/formatters.dart';
import '../../../widgets/savings_progress_bar.dart';
import '../../../widgets/status_pill.dart';
import '../add_contribution_screen.dart';

/// Status pills plus the headline of the goal: progress towards the target,
/// or the fixed periodic amount.
class GoalDetailHeader extends StatelessWidget {
  const GoalDetailHeader({
    super.key,
    required this.goal,
    required this.progress,
  });

  final SavingsGoal goal;
  final int progress;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final isCompleted = goal.status == SavingsGoalStatus.completed;
    final isArchived = goal.status == SavingsGoalStatus.archived;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.xs,
          children: [
            StatusPill(
              label: goal.isPeriodic ? 'Target Berkala' : 'Target Akhir',
              color: AppColors.primary,
              icon: goal.isPeriodic ? Icons.repeat : Icons.flag_outlined,
            ),
            if (isCompleted)
              const StatusPill(label: 'Tercapai', color: AppColors.income),
            if (isArchived)
              const StatusPill(label: 'Diarsipkan', color: AppColors.outline),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        if (goal.isPeriodic) ..._periodicHeader(context, textTheme)
        else ..._finalHeader(context, textTheme),
      ],
    );
  }

  List<Widget> _periodicHeader(BuildContext context, TextTheme textTheme) {
    final amount = goal.periodicAmount ?? 0;
    final unit = goal.periodUnit ?? PeriodUnit.month;
    final start = goal.startDate ?? goal.createdAt;

    return [
      Text(
        '${formatRupiah(amount)} ${unit.perLabel}',
        style: textTheme.displaySmall?.copyWith(color: AppColors.primary),
      ),
      const SizedBox(height: AppSpacing.xs),
      Text(
        'Tanpa tenggat · sejak ${formatDateShort(start)}',
        style: textTheme.bodySmall,
      ),
      const SizedBox(height: AppSpacing.md),
      Text('Terkumpul', style: textTheme.bodySmall),
      Text(
        formatRupiah(progress),
        style: textTheme.titleLarge?.copyWith(color: AppColors.onSurface),
      ),
    ];
  }

  List<Widget> _finalHeader(BuildContext context, TextTheme textTheme) {
    final plan = goal.finalPlan(saved: progress);
    return [
      if (plan != null)
        Text(
          'Tenggat ${formatDateShort(plan.deadline)} · '
          '${formatTimeLeft(plan.daysLeft)}',
          style: textTheme.bodySmall,
        ),
      const SizedBox(height: AppSpacing.sm),
      SavingsProgressBar(progress: progress, target: goal.completionTarget()),
      if (plan != null && plan.adjustForInflation) ...[
        const SizedBox(height: AppSpacing.sm),
        Text(
          'Harga target ${formatRupiah(goal.targetAmount)} '
          '(per ${formatDateShort(plan.priceDate)}) kini '
          '${formatRupiahAuto(plan.currentCost)}, dan menjadi '
          '${formatRupiahAuto(plan.adjustedTarget)} pada '
          '${formatDateShort(plan.deadline)}.',
          style: textTheme.bodySmall,
        ),
      ],
    ];
  }
}

class GoalDetailActions extends StatelessWidget {
  const GoalDetailActions({super.key, required this.goal});

  final SavingsGoal goal;

  @override
  Widget build(BuildContext context) {
    final periodicAmount = goal.isPeriodic ? goal.periodicAmount : null;

    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => Navigator.of(context).pushNamed(
              AddContributionScreen.routeName,
              arguments: AddContributionArgs(
                goalId: goal.id,
                type: ContributionType.deposit,
                initialAmount: periodicAmount,
              ),
            ),
            icon: const Icon(Icons.south_west),
            label: Text(
              periodicAmount != null
                  ? 'Setor ${formatRupiahCompact(periodicAmount.toDouble())}'
                  : 'Setor',
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => Navigator.of(context).pushNamed(
              AddContributionScreen.routeName,
              arguments: AddContributionArgs(
                goalId: goal.id,
                type: ContributionType.withdraw,
              ),
            ),
            icon: const Icon(Icons.north_east),
            label: const Text('Tarik'),
          ),
        ),
      ],
    );
  }
}
