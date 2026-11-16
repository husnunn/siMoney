import 'package:flutter/material.dart';

import '../../../models/models.dart';
import '../../../theme/app_colors.dart';
import '../../../widgets/status_pill.dart';

class GoalStatusPill extends StatelessWidget {
  const GoalStatusPill({super.key, required this.goal});

  final SavingsGoal goal;

  @override
  Widget build(BuildContext context) {
    if (goal.status == SavingsGoalStatus.completed) {
      return const StatusPill(label: 'Tercapai', color: AppColors.income);
    }
    if (goal.status == SavingsGoalStatus.archived) {
      return const StatusPill(label: 'Diarsipkan', color: AppColors.outline);
    }
    return const SizedBox.shrink();
  }
}
