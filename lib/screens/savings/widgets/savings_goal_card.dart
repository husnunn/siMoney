import 'package:flutter/material.dart';

import '../../../models/models.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_spacing.dart';
import '../savings_goal_detail_screen.dart';
import 'final_goal_card_body.dart';
import 'periodic_goal_card_body.dart';

/// List card for either kind of goal. A Target Akhir card shows progress
/// towards the amount plus what to save per day/week/month/year; a Target
/// Berkala card shows the fixed amount, its equivalents and the streak.
class SavingsGoalCard extends StatelessWidget {
  const SavingsGoalCard({super.key, required this.goal});

  final SavingsGoal goal;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainer,
        border: Border.all(color: AppColors.outlineVariant),
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        onTap: () {
          Navigator.of(context).pushNamed(
            SavingsGoalDetailScreen.routeName,
            arguments: goal.id,
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: goal.isPeriodic
              ? PeriodicGoalCardBody(goal: goal)
              : FinalGoalCardBody(goal: goal),
        ),
      ),
    );
  }
}
