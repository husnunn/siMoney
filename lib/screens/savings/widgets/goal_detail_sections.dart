import 'package:flutter/material.dart';

import '../../../models/models.dart';
import '../../../state/savings_goal_planning.dart';
import '../../../state/savings_planner.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_spacing.dart';
import '../../../widgets/info_banner.dart';
import 'final_plan_section.dart';
import 'periodic_consistency_section.dart';
import 'periodic_plan_section.dart';
import 'projection_chart_card.dart';
import 'reach_calculator_card.dart';
import 'tenor_comparison_card.dart';

/// Plan, chart, tenor comparison and "when is it reached" for Target Akhir.
class FinalGoalSections extends StatelessWidget {
  const FinalGoalSections({
    super.key,
    required this.goal,
    required this.progress,
    required this.contributions,
  });

  final SavingsGoal goal;
  final int progress;
  final List<SavingsContribution> contributions;

  @override
  Widget build(BuildContext context) {
    final plan = goal.finalPlan(saved: progress);

    if (plan == null) {
      return const InfoBanner(
        message: 'Tambahkan tenggat lewat menu Edit untuk melihat rencana '
            'setoran per hari, minggu, bulan, dan tahun.',
        color: AppColors.primary,
        icon: Icons.event_outlined,
      );
    }

    final pace = goal.recentPace(contributions);
    final isActive = goal.status == SavingsGoalStatus.active;
    final isOpen = isActive && !plan.isReached && !plan.isOverdue;
    final tenors = FinalGoalPlan.tenorTable(
      targetAmount:
          plan.adjustForInflation ? plan.currentCost.round() : plan.targetAmount,
      saved: plan.saved,
      today: plan.today,
      adjustForInflation: plan.adjustForInflation,
      inflationRate: goal.inflationRate,
      annualReturn: plan.annualReturn,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FinalPlanSection(
          plan: plan,
          recentPace: pace.pace,
          paceLabel: pace.label,
        ),
        if (isOpen) ...[
          const SizedBox(height: AppSpacing.lg),
          ProjectionChartCard(plan: plan),
          const SizedBox(height: AppSpacing.lg),
          ReachCalculatorCard(plan: plan),
        ],
        if (isActive && !plan.isReached) ...[
          const SizedBox(height: AppSpacing.lg),
          TenorComparisonCard(rows: tenors),
        ],
      ],
    );
  }
}

/// Equivalents, projections and consistency for Target Berkala.
class PeriodicGoalSections extends StatelessWidget {
  const PeriodicGoalSections({
    super.key,
    required this.goal,
    required this.contributions,
  });

  final SavingsGoal goal;
  final List<SavingsContribution> contributions;

  @override
  Widget build(BuildContext context) {
    final plan = goal.periodicPlan();
    final adherence = goal.adherence(contributions: contributions);
    if (plan == null || adherence == null) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        PeriodicPlanSection(plan: plan),
        const SizedBox(height: AppSpacing.lg),
        PeriodicConsistencySection(
          adherence: adherence,
          unit: plan.unit,
          amount: plan.amount,
          startDate: goal.startDate ?? goal.createdAt,
        ),
      ],
    );
  }
}
