import 'package:flutter/material.dart';

import '../../../models/models.dart';
import '../../../state/app_store.dart';
import '../../../state/inflation_data.dart';
import '../../../state/savings_planner.dart';
import 'plan_previews.dart';

/// Live preview under the goal form. Picks the right preview for the kind of
/// goal and the state of the form (nothing to calculate yet, a Target Akhir
/// plan, or a Target Berkala plan).
class GoalFormPreview extends StatelessWidget {
  const GoalFormPreview({
    super.key,
    required this.isPeriodic,
    required this.amount,
    required this.annualReturn,
    required this.unit,
    required this.adjust,
    required this.rate,
    required this.deadline,
    this.existing,
  });

  final bool isPeriodic;
  final int amount;
  final double annualReturn;
  final PeriodUnit unit;
  final bool adjust;

  /// Yearly inflation in percent; `null` = automatic.
  final double? rate;
  final DateTime? deadline;

  /// The goal being edited, if any (its saved amount and price date count).
  final SavingsGoal? existing;

  @override
  Widget build(BuildContext context) {
    if (isPeriodic) {
      if (amount <= 0) {
        return const PlanPreviewHint(
          message: 'Isi nominal per periode untuk melihat setara per hari, '
              'minggu, bulan, dan tahun.',
        );
      }
      return PeriodicPlanPreview(
        plan: PeriodicPlan.compute(
          amount: amount,
          unit: unit,
          annualReturn: annualReturn,
          inflationRate: adjust
              ? InflationData.resolve(rate, InflationData.periodicHorizonDays)
              : null,
        ),
      );
    }

    final end = deadline;
    if (amount <= 0 || end == null) {
      return const PlanPreviewHint(
        message: 'Isi nominal dan tenggat untuk melihat rencana setoran per '
            'hari, minggu, bulan, dan tahun.',
      );
    }

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final goal = existing;
    // An unchanged amount keeps its original price date; a new amount is a
    // new price quote, so inflation counts from today.
    final priceDate = (goal != null && amount == goal.targetAmount)
        ? goal.effectivePriceDate
        : today;
    final horizon = PlanDates.daysBetween(priceDate, end);

    return FinalPlanPreview(
      plan: FinalGoalPlan.compute(
        targetAmount: amount,
        saved: goal != null ? appStore.goalProgress(goal.id) : 0,
        today: today,
        deadline: end,
        priceDate: priceDate,
        adjustForInflation: adjust,
        inflationRate: InflationData.resolve(rate, horizon),
        annualReturn: annualReturn,
      ),
    );
  }
}
