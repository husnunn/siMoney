import 'dart:math' as math;

import '../../models/savings_plan_types.dart';
import 'period_figures.dart';
import 'plan_math.dart';

/// One saving period of a periodic goal and whether it was fulfilled.
class PeriodBucket {
  const PeriodBucket({
    required this.index,
    required this.start,
    required this.total,
    required this.fulfilled,
    required this.isCurrent,
  });

  final int index;
  final DateTime start;
  final int total;
  final bool fulfilled;
  final bool isCurrent;
}

/// How consistently a periodic goal has been kept up.
class PeriodicAdherence {
  const PeriodicAdherence._({
    required this.started,
    required this.currentIndex,
    required this.completedPeriods,
    required this.fulfilledCompleted,
    required this.streak,
    required this.bestStreak,
    required this.actualTotal,
    required this.catchUp,
    required this.currentTotal,
    required this.currentRemaining,
    required this.currentPeriodEnd,
    required this.recent,
  });

  /// Calendar bucket index of [date] counted from [start] (0 = first period).
  static int bucketIndex(PeriodUnit unit, DateTime start, DateTime date) {
    return switch (unit) {
      PeriodUnit.day => PlanDates.daysBetween(start, date),
      PeriodUnit.week => PlanDates.daysBetween(start, date) ~/ 7,
      PeriodUnit.month =>
        (date.year - start.year) * 12 + date.month - start.month,
      PeriodUnit.year => date.year - start.year,
    };
  }

  /// First day of period [index]. Period 0 starts on [start] itself; later
  /// month / year periods start on calendar boundaries.
  static DateTime bucketStart(PeriodUnit unit, DateTime start, int index) {
    return switch (unit) {
      PeriodUnit.day => DateTime(start.year, start.month, start.day + index),
      PeriodUnit.week =>
        DateTime(start.year, start.month, start.day + 7 * index),
      PeriodUnit.month =>
        index == 0 ? start : DateTime(start.year, start.month + index, 1),
      PeriodUnit.year => index == 0 ? start : DateTime(start.year + index, 1, 1),
    };
  }

  factory PeriodicAdherence.compute({
    required int amount,
    required PeriodUnit unit,
    required DateTime startDate,
    required DateTime today,
    required Iterable<DatedAmount> flows,
    int recentBuckets = 12,
  }) {
    final start = PlanDates.dateOnly(startDate);
    final now = PlanDates.dateOnly(today);

    if (now.isBefore(start)) {
      return PeriodicAdherence._(
        started: false,
        currentIndex: -1,
        completedPeriods: 0,
        fulfilledCompleted: 0,
        streak: 0,
        bestStreak: 0,
        actualTotal: 0,
        catchUp: 0,
        currentTotal: 0,
        currentRemaining: amount,
        currentPeriodEnd: start,
        recent: const [],
      );
    }

    final currentIndex = bucketIndex(unit, start, now);
    final totals = List<int>.filled(currentIndex + 1, 0);
    var actualTotal = 0;
    for (final f in flows) {
      final d = PlanDates.dateOnly(f.date);
      if (d.isAfter(now)) continue;
      final idx = math.max(0, bucketIndex(unit, start, d));
      if (idx > currentIndex) continue;
      totals[idx] += f.amount;
      actualTotal += f.amount;
    }

    var fulfilledCompleted = 0;
    for (var i = 0; i < currentIndex; i++) {
      if (totals[i] >= amount) fulfilledCompleted++;
    }
    final currentTotal = totals[currentIndex];
    final currentFulfilled = currentTotal >= amount;

    // Streak: consecutive fulfilled periods ending now. An unfinished current
    // period does not break the streak, it just is not counted yet.
    var streak = 0;
    for (var i = currentFulfilled ? currentIndex : currentIndex - 1;
        i >= 0 && totals[i] >= amount;
        i--) {
      streak++;
    }
    var best = 0;
    var run = 0;
    for (var i = 0; i <= currentIndex; i++) {
      if (totals[i] >= amount) {
        run++;
        best = math.max(best, run);
      } else {
        run = 0;
      }
    }

    final nextStart = bucketStart(unit, start, currentIndex + 1);
    final periodEnd = DateTime(nextStart.year, nextStart.month, nextStart.day - 1);

    final firstRecent = math.max(0, currentIndex - recentBuckets + 1);
    final recent = [
      for (var i = firstRecent; i <= currentIndex; i++)
        PeriodBucket(
          index: i,
          start: bucketStart(unit, start, i),
          total: totals[i],
          fulfilled: totals[i] >= amount,
          isCurrent: i == currentIndex,
        ),
    ];

    return PeriodicAdherence._(
      started: true,
      currentIndex: currentIndex,
      completedPeriods: currentIndex,
      fulfilledCompleted: fulfilledCompleted,
      streak: streak,
      bestStreak: best,
      actualTotal: actualTotal,
      catchUp: math.max(0, amount * (currentIndex + 1) - actualTotal),
      currentTotal: currentTotal,
      currentRemaining: math.max(0, amount - currentTotal),
      currentPeriodEnd: periodEnd,
      recent: recent,
    );
  }

  final bool started;
  final int currentIndex;

  /// Periods that are fully over (the current one is not included).
  final int completedPeriods;
  final int fulfilledCompleted;
  final int streak;
  final int bestStreak;

  /// Net amount saved since the start date.
  final int actualTotal;

  /// Amount still missing to be level with the schedule at the end of the
  /// current period (0 when ahead).
  final int catchUp;

  final int currentTotal;
  final int currentRemaining;
  final DateTime currentPeriodEnd;
  final List<PeriodBucket> recent;

  int get missedPeriods => completedPeriods - fulfilledCompleted;

  bool get currentFulfilled => started && currentRemaining == 0;

  /// Share of completed periods that were fulfilled (null before any ended).
  double? get consistency =>
      completedPeriods == 0 ? null : fulfilledCompleted / completedPeriods;
}
