import '../models/models.dart';
import 'inflation_data.dart';
import 'savings_planner.dart';

/// Bridges a stored [SavingsGoal] to the pure planning math.
extension SavingsGoalPlanning on SavingsGoal {
  /// Plan for a "Target Akhir" goal. `null` for periodic goals and for goals
  /// without a deadline (nothing to plan towards).
  FinalGoalPlan? finalPlan({required int saved, DateTime? today}) {
    final deadline = targetDate;
    if (isPeriodic || deadline == null) return null;
    final base = effectivePriceDate;
    final horizon = PlanDates.daysBetween(base, deadline);
    return FinalGoalPlan.compute(
      targetAmount: targetAmount,
      saved: saved,
      today: today ?? DateTime.now(),
      deadline: deadline,
      priceDate: base,
      adjustForInflation: adjustForInflation,
      inflationRate: InflationData.resolve(inflationRate, horizon),
      annualReturn: expectedReturn,
    );
  }

  /// Plan for a "Target Berkala" goal. `null` for target goals.
  PeriodicPlan? periodicPlan() {
    final amount = periodicAmount;
    final unit = periodUnit;
    if (!isPeriodic || amount == null || unit == null) return null;
    return PeriodicPlan.compute(
      amount: amount,
      unit: unit,
      annualReturn: expectedReturn,
      inflationRate: adjustForInflation
          ? InflationData.resolve(inflationRate, InflationData.periodicHorizonDays)
          : null,
    );
  }

  /// How consistently a periodic goal has been kept up. `null` for target goals.
  PeriodicAdherence? adherence({
    required Iterable<SavingsContribution> contributions,
    DateTime? today,
  }) {
    final amount = periodicAmount;
    final unit = periodUnit;
    if (!isPeriodic || amount == null || unit == null) return null;
    return PeriodicAdherence.compute(
      amount: amount,
      unit: unit,
      startDate: startDate ?? createdAt,
      today: today ?? DateTime.now(),
      flows: [
        for (final c in contributions) DatedAmount(c.date, c.progressDelta),
      ],
    );
  }

  /// Average net saving per month over a recent window, plus a caption for it.
  /// The window is 90 days, shortened (never below 30) for a goal that is
  /// younger than that so a new goal is not judged on days it did not exist.
  ({double pace, String label}) recentPace(
    Iterable<SavingsContribution> contributions, {
    DateTime? today,
  }) {
    final now = today ?? DateTime.now();
    final age = PlanDates.daysBetween(createdAt, now) + 1;
    final window = age.clamp(30, 90);
    final pace = FinalGoalPlan.recentMonthlyPace(
      [for (final c in contributions) DatedAmount(c.date, c.progressDelta)],
      today: now,
      windowDays: window,
    );
    return (
      pace: pace,
      label: window >= 90 ? '3 bulan terakhir' : '$window hari terakhir',
    );
  }

  /// Saved amount at which a target goal counts as reached. When the target is
  /// adjusted for inflation this is what the goal costs *today* (it can be
  /// bought as soon as the savings cover today's price), otherwise the plain
  /// target. Periodic goals never complete.
  int completionTarget({DateTime? today}) {
    if (isPeriodic) return 0;
    final plan = finalPlan(saved: 0, today: today);
    if (plan == null || !adjustForInflation) return targetAmount;
    // The small offset keeps floating-point noise (1100000.0000000002) from
    // rounding a whole-rupiah price up by one.
    return (plan.currentCost - 0.01).ceil();
  }
}
