import 'dart:math' as math;

import '../../models/savings_plan_types.dart';
import '../inflation_data.dart';
import 'period_figures.dart';
import 'plan_math.dart';

/// Plan for a "Target Akhir" goal: reach [targetAmount] by [deadline].
class FinalGoalPlan {
  const FinalGoalPlan._({
    required this.targetAmount,
    required this.saved,
    required this.today,
    required this.deadline,
    required this.daysLeft,
    required this.adjustForInflation,
    required this.inflationRate,
    required this.annualReturn,
    required this.priceDate,
    required this.currentCost,
    required this.adjustedTarget,
    required this.required,
    required this.requiredWithoutInflation,
    required this.realReturn,
  });

  /// [targetAmount] is the price on [priceDate] (defaults to [today]). When
  /// [adjustForInflation] is true it is grown by [inflationRate] percent per
  /// year up to [deadline]. [annualReturn] is the optional yearly yield
  /// (percent) of wherever the money is kept.
  factory FinalGoalPlan.compute({
    required int targetAmount,
    required int saved,
    required DateTime today,
    required DateTime deadline,
    DateTime? priceDate,
    bool adjustForInflation = false,
    double inflationRate = 0,
    double annualReturn = 0,
  }) {
    final days = PlanDates.daysBetween(today, deadline);
    final base = PlanDates.dateOnly(priceDate ?? today);
    final adjusted = adjustForInflation
        ? PlanMath.inflate(
            targetAmount.toDouble(),
            base,
            deadline,
            inflationRate,
          )
        : targetAmount.toDouble();
    final cost = adjustForInflation
        ? PlanMath.inflate(targetAmount.toDouble(), base, today, inflationRate)
        : targetAmount.toDouble();

    PeriodFigures figuresFor(double futureValue) {
      if (days <= 0) return PeriodFigures.zero;
      double pay(PeriodUnit unit) => PlanMath.requiredPayment(
            futureValue: futureValue,
            saved: saved.toDouble(),
            days: days.toDouble(),
            periodDays: unit.days,
            annualReturn: annualReturn,
          );
      return PeriodFigures(
        perDay: pay(PeriodUnit.day),
        perWeek: pay(PeriodUnit.week),
        perMonth: pay(PeriodUnit.month),
        perYear: pay(PeriodUnit.year),
      );
    }

    final real = adjustForInflation
        ? ((1 + annualReturn / 100) / (1 + inflationRate / 100) - 1) * 100
        : null;

    return FinalGoalPlan._(
      targetAmount: targetAmount,
      saved: saved,
      today: PlanDates.dateOnly(today),
      deadline: PlanDates.dateOnly(deadline),
      daysLeft: days,
      adjustForInflation: adjustForInflation,
      inflationRate: inflationRate,
      annualReturn: annualReturn,
      priceDate: base,
      currentCost: cost,
      adjustedTarget: adjusted,
      required: figuresFor(adjusted),
      requiredWithoutInflation: figuresFor(targetAmount.toDouble()),
      realReturn: real,
    );
  }

  final int targetAmount;
  final int saved;
  final DateTime today;
  final DateTime deadline;
  final int daysLeft;
  final bool adjustForInflation;
  final double inflationRate;
  final double annualReturn;

  /// The date [targetAmount] was priced on.
  final DateTime priceDate;

  /// What the goal costs today (the target grown from [priceDate] to today).
  final double currentCost;

  /// Target in the money of [deadline] (equals [targetAmount] when not
  /// adjusted for inflation).
  final double adjustedTarget;

  /// Payment needed per day / week / month / year from today until the deadline.
  final PeriodFigures required;

  /// The same, if inflation were ignored.
  final PeriodFigures requiredWithoutInflation;

  /// Yield minus inflation in percent per year (null when not adjusting).
  final double? realReturn;

  double get inflationExtra => adjustedTarget - targetAmount;

  /// What is still missing after the current balance (undiscounted).
  double get remaining => math.max(0, adjustedTarget - saved);

  bool get isOverdue => daysLeft <= 0 && remaining > 0;

  bool get isReached => saved >= adjustedTarget;

  double get monthsLeft => daysLeft / PeriodUnit.month.days;

  /// Extra monthly saving caused by inflation.
  double get inflationExtraPerMonth =>
      required.perMonth - requiredWithoutInflation.perMonth;

  double get inflationExtraPercent {
    final base = requiredWithoutInflation.perMonth;
    if (base <= 0) return 0;
    return (required.perMonth / base - 1) * 100;
  }

  /// How far the recent saving pace is below what is needed (<= 0 = on track).
  double monthlyGap(double recentMonthlyPace) =>
      required.perMonth - recentMonthlyPace;

  /// Balance vs. cost over the remaining time, for the projection chart.
  List<ProjectionPoint> series({int points = 48}) {
    if (daysLeft <= 0 || points < 2) return const [];
    final total = daysLeft.toDouble();
    return [
      for (var k = 0; k <= points; k++)
        () {
          final t = total * k / points;
          final balance = PlanMath.growLump(saved.toDouble(), t, annualReturn) +
              PlanMath.annuityFutureValue(
                payment: required.perMonth,
                periodDays: PeriodUnit.month.days,
                days: t,
                annualReturn: annualReturn,
              );
          final cost = adjustForInflation
              ? PlanMath.inflate(
                  targetAmount.toDouble(),
                  priceDate,
                  DateTime(today.year, today.month, today.day + t.round()),
                  inflationRate,
                )
              : targetAmount.toDouble();
          return ProjectionPoint(day: t, balance: balance, cost: cost);
        }(),
    ];
  }

  /// Same goal compared across several tenors (1, 2, 3 ... years from today).
  /// A `null` [inflationRate] means "auto": each tenor gets its own default.
  static List<TenorRow> tenorTable({
    required int targetAmount,
    required int saved,
    required DateTime today,
    bool adjustForInflation = false,
    double? inflationRate,
    double annualReturn = 0,
    List<int> years = const [1, 2, 3, 4, 5, 10],
  }) {
    return [
      for (final y in years)
        () {
          final deadline = PlanDates.addMonths(today, y * 12);
          final days = PlanDates.daysBetween(today, deadline);
          return TenorRow(
            years: y,
            plan: FinalGoalPlan.compute(
              targetAmount: targetAmount,
              saved: saved,
              today: today,
              deadline: deadline,
              adjustForInflation: adjustForInflation,
              inflationRate: InflationData.resolve(inflationRate, days),
              annualReturn: annualReturn,
            ),
          );
        }(),
    ];
  }

  /// Months until savings of [monthlyContribution] reach the (inflating)
  /// target, or `null` when it takes longer than [maxMonths].
  static int? monthsToReach({
    required int targetAmount,
    required int saved,
    required double monthlyContribution,
    bool adjustForInflation = false,
    double inflationRate = 0,
    double annualReturn = 0,
    int maxMonths = 600,
  }) {
    if (saved >= targetAmount) return 0;
    final monthlyRate = annualReturn <= 0
        ? 0.0
        : PlanMath.pow(1 + annualReturn / 100, 1 / 12) - 1;
    for (var m = 1; m <= maxMonths; m++) {
      final growth = monthlyRate == 0 ? 1.0 : PlanMath.pow(1 + monthlyRate, m.toDouble());
      final annuity = monthlyRate == 0
          ? monthlyContribution * m
          : monthlyContribution * (growth - 1) / monthlyRate;
      final balance = saved * growth + annuity;
      final cost = adjustForInflation
          ? targetAmount * PlanMath.pow(1 + inflationRate / 100, m / 12)
          : targetAmount.toDouble();
      if (balance >= cost) return m;
    }
    return null;
  }

  /// Average net saving per month over the last [windowDays] days.
  static double recentMonthlyPace(
    Iterable<DatedAmount> flows, {
    required DateTime today,
    int windowDays = 90,
  }) {
    final end = PlanDates.dateOnly(today);
    final start = DateTime(end.year, end.month, end.day - (windowDays - 1));
    var sum = 0;
    for (final f in flows) {
      final d = PlanDates.dateOnly(f.date);
      if (d.isBefore(start) || d.isAfter(end)) continue;
      sum += f.amount;
    }
    return sum / windowDays * PeriodUnit.month.days;
  }
}

class TenorRow {
  const TenorRow({required this.years, required this.plan});

  final int years;
  final FinalGoalPlan plan;
}
