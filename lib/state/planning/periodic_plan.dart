import '../../models/savings_plan_types.dart';
import 'period_figures.dart';
import 'plan_math.dart';

class ProjectionHorizon {
  const ProjectionHorizon(this.label, this.days);

  final String label;
  final double days;
}

class PeriodicProjection {
  const PeriodicProjection({
    required this.horizon,
    required this.contributed,
    required this.nominal,
    required this.realValue,
  });

  final ProjectionHorizon horizon;

  /// Sum of all deposits, ignoring any yield.
  final double contributed;

  /// Balance including yield, in future money.
  final double nominal;

  /// [nominal] expressed in today's purchasing power (needs an inflation rate).
  final double realValue;
}

/// Plan for a "Target Berkala" goal: a fixed amount every period, no deadline.
class PeriodicPlan {
  const PeriodicPlan._({
    required this.amount,
    required this.unit,
    required this.annualReturn,
    required this.inflationRate,
    required this.figures,
  });

  /// [inflationRate] is only used to express projections in today's
  /// purchasing power; pass `null` to skip that.
  factory PeriodicPlan.compute({
    required int amount,
    required PeriodUnit unit,
    double annualReturn = 0,
    double? inflationRate,
  }) {
    return PeriodicPlan._(
      amount: amount,
      unit: unit,
      annualReturn: annualReturn,
      inflationRate: inflationRate,
      figures: PeriodFigures.fromAmount(amount.toDouble(), unit),
    );
  }

  static const List<ProjectionHorizon> horizons = [
    ProjectionHorizon('1 bulan', 365 / 12),
    ProjectionHorizon('3 bulan', 365 / 4),
    ProjectionHorizon('6 bulan', 365 / 2),
    ProjectionHorizon('1 tahun', 365),
    ProjectionHorizon('3 tahun', 365 * 3),
    ProjectionHorizon('5 tahun', 365 * 5),
    ProjectionHorizon('10 tahun', 365 * 10),
  ];

  final int amount;
  final PeriodUnit unit;
  final double annualReturn;
  final double? inflationRate;
  final PeriodFigures figures;

  bool get hasInflation => inflationRate != null && inflationRate! > 0;

  PeriodicProjection projectAfter(ProjectionHorizon horizon) {
    final contributed = amount * horizon.days / unit.days;
    final nominal = PlanMath.annuityFutureValue(
      payment: amount.toDouble(),
      periodDays: unit.days,
      days: horizon.days,
      annualReturn: annualReturn,
    );
    final real = hasInflation
        ? nominal /
            PlanMath.pow(
              1 + inflationRate! / 100,
              horizon.days / PeriodUnit.year.days,
            )
        : nominal;
    return PeriodicProjection(
      horizon: horizon,
      contributed: contributed,
      nominal: nominal,
      realValue: real,
    );
  }

  List<PeriodicProjection> get projections => [
        for (final h in horizons) projectAfter(h),
      ];

  /// Days until the saved total reaches [goalAmount] (null if never within
  /// 100 years). Useful for "when do I reach X at this pace?".
  double? daysToReach(num goalAmount, {num alreadySaved = 0}) {
    if (alreadySaved >= goalAmount) return 0;
    if (amount <= 0) return null;
    if (annualReturn <= 0) {
      return (goalAmount - alreadySaved) / amount * unit.days;
    }
    var low = 0.0;
    var high = PeriodUnit.year.days * 100;
    double balanceAt(double days) =>
        PlanMath.growLump(alreadySaved.toDouble(), days, annualReturn) +
        PlanMath.annuityFutureValue(
          payment: amount.toDouble(),
          periodDays: unit.days,
          days: days,
          annualReturn: annualReturn,
        );
    if (balanceAt(high) < goalAmount) return null;
    for (var k = 0; k < 60; k++) {
      final mid = (low + high) / 2;
      if (balanceAt(mid) >= goalAmount) {
        high = mid;
      } else {
        low = mid;
      }
    }
    return high;
  }
}
