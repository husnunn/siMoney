import 'dart:math' as math;

import '../../models/savings_plan_types.dart';

/// Calendar helpers that ignore time of day and daylight-saving shifts.
abstract final class PlanDates {
  static DateTime dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  /// Whole days from [from] to [to] (negative when [to] is earlier).
  static int daysBetween(DateTime from, DateTime to) {
    final a = DateTime.utc(from.year, from.month, from.day);
    final b = DateTime.utc(to.year, to.month, to.day);
    return b.difference(a).inDays;
  }

  /// Adds calendar months, clamping the day (31 Jan + 1 month = 28/29 Feb).
  static DateTime addMonths(DateTime date, int months) {
    final total = date.year * 12 + (date.month - 1) + months;
    final year = total ~/ 12;
    final month = total % 12 + 1;
    final lastDay = DateTime(year, month + 1, 0).day;
    return DateTime(year, month, math.min(date.day, lastDay));
  }
}

abstract final class PlanMath {
  static double pow(double base, double exponent) =>
      math.pow(base, exponent).toDouble();

  /// [amount] (priced on [from]) expressed in the prices of [to], growing by
  /// [ratePercent] per year. Never deflates: [to] before [from] returns [amount].
  static double inflate(
    double amount,
    DateTime from,
    DateTime to,
    double ratePercent,
  ) {
    final days = PlanDates.daysBetween(from, to);
    if (days <= 0 || ratePercent == 0) return amount;
    return amount * pow(1 + ratePercent / 100, days / PeriodUnit.year.days);
  }

  /// Per-period rate equivalent to [annualReturn] percent per year.
  static double periodRate(double annualReturn, double periodDays) =>
      pow(1 + annualReturn / 100, periodDays / PeriodUnit.year.days) - 1;

  /// Growth of a lump sum over [days] at [annualReturn] percent per year.
  static double growLump(double amount, double days, double annualReturn) {
    if (annualReturn <= 0 || days <= 0) return amount;
    return amount * pow(1 + annualReturn / 100, days / PeriodUnit.year.days);
  }

  /// Future value of equal payments made every [periodDays] days for [days]
  /// days (payments at the end of each period).
  static double annuityFutureValue({
    required double payment,
    required double periodDays,
    required double days,
    double annualReturn = 0,
  }) {
    if (days <= 0) return 0;
    final n = days / periodDays;
    if (annualReturn <= 0) return payment * n;
    final i = periodRate(annualReturn, periodDays);
    return payment * (pow(1 + i, n) - 1) / i;
  }

  /// Payment per [periodDays] needed so that [saved] plus the payments reach
  /// [futureValue] in [days] days. Never negative.
  static double requiredPayment({
    required double futureValue,
    required double saved,
    required double days,
    required double periodDays,
    double annualReturn = 0,
  }) {
    if (days <= 0) return 0;
    final n = days / periodDays;
    if (annualReturn <= 0) {
      final need = futureValue - saved;
      return need <= 0 ? 0 : need / n;
    }
    final i = periodRate(annualReturn, periodDays);
    final growth = pow(1 + i, n);
    final need = futureValue - saved * growth;
    if (need <= 0) return 0;
    return need * i / (growth - 1);
  }
}
