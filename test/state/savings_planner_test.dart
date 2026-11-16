import 'package:flutter_test/flutter_test.dart';
import 'package:simoney/models/savings_plan_types.dart';
import 'package:simoney/state/inflation_data.dart';
import 'package:simoney/state/savings_planner.dart';

// Expected values below were computed independently (separate script), not
// copied from the implementation.

void main() {
  group('PlanDates', () {
    test('addMonths clamps to the end of a shorter month', () {
      expect(PlanDates.addMonths(DateTime(2026, 1, 31), 1), DateTime(2026, 2, 28));
      expect(PlanDates.addMonths(DateTime(2028, 1, 31), 1), DateTime(2028, 2, 29));
      expect(PlanDates.addMonths(DateTime(2026, 12, 15), 13), DateTime(2028, 1, 15));
    });

    test('daysBetween counts whole days and ignores time of day', () {
      expect(
        PlanDates.daysBetween(DateTime(2026, 11, 16, 23, 59), DateTime(2029, 11, 16, 1)),
        1096, // includes 29 Feb 2028
      );
      expect(PlanDates.daysBetween(DateTime(2026, 11, 16), DateTime(2026, 11, 10)), -6);
    });
  });

  group('PeriodFigures', () {
    test('120.000 per week converts consistently to every period', () {
      final f = PeriodFigures.fromAmount(120000, PeriodUnit.week);
      expect(f.perDay, closeTo(17142.857, 0.001));
      expect(f.perWeek, closeTo(120000, 0.001));
      expect(f.perMonth, closeTo(521428.571, 0.001));
      expect(f.perYear, closeTo(6257142.857, 0.001));
    });

    test('sum adds every period', () {
      final a = PeriodFigures.fromAmount(120000, PeriodUnit.week);
      final b = PeriodFigures.fromAmount(500000, PeriodUnit.month);
      final total = PeriodFigures.sum([a, b]);
      expect(total.perMonth, closeTo(521428.571 + 500000, 0.01));
      // 500.000 x 12 months = 6.000.000 exactly under 1 month = 365 / 12 days.
      expect(total.perYear, closeTo(6257142.857 + 6000000, 0.01));
      expect(PeriodFigures.sum(const []).perMonth, 0);
    });

    test('round-trips: any unit gives the same figures for the same pace', () {
      final fromMonth = PeriodFigures.fromAmount(521428.5714285714, PeriodUnit.month);
      final fromDay = PeriodFigures.fromAmount(17142.857142857142, PeriodUnit.day);
      expect(fromMonth.perWeek, closeTo(120000, 0.01));
      expect(fromDay.perWeek, closeTo(120000, 0.01));
      expect(fromDay.of(PeriodUnit.year), closeTo(fromMonth.perYear, 0.01));
    });
  });

  group('FinalGoalPlan', () {
    final today = DateTime(2026, 11, 16);
    final deadline = DateTime(2029, 11, 16);

    test('inflation grows the target and raises the required saving', () {
      final plan = FinalGoalPlan.compute(
        targetAmount: 150000000,
        saved: 27500000,
        today: today,
        deadline: deadline,
        adjustForInflation: true,
        inflationRate: 3.2,
      );
      expect(plan.daysLeft, 1096);
      expect(plan.adjustedTarget, closeTo(164879943.35, 1));
      expect(plan.inflationExtra, closeTo(14879943.35, 1));
      expect(plan.required.perDay, closeTo(125346.66, 0.5));
      expect(plan.required.perWeek, closeTo(877426.65, 0.5));
      expect(plan.required.perMonth, closeTo(3812627.69, 1));
      expect(plan.required.perYear, closeTo(45751532.23, 1));
      expect(plan.requiredWithoutInflation.perMonth, closeTo(3399673.05, 1));
      expect(plan.inflationExtraPerMonth, closeTo(412954.63, 1));
      expect(plan.inflationExtraPercent, closeTo(12.147, 0.001));
    });

    test('inflation counts from the date the price was set, not from today', () {
      final plan = FinalGoalPlan.compute(
        targetAmount: 150000000,
        saved: 27500000,
        today: today,
        deadline: deadline,
        priceDate: DateTime(2025, 11, 16), // priced one year ago
        adjustForInflation: true,
        inflationRate: 3.2,
      );
      expect(plan.currentCost, closeTo(154800000, 0.01)); // one year of 3.2%
      expect(plan.adjustedTarget, closeTo(170156101.54, 1));
      expect(plan.required.perMonth, closeTo(3959053.91, 1));
      final points = plan.series();
      expect(points.first.cost, closeTo(154800000, 0.01));
      expect(points.last.cost, closeTo(plan.adjustedTarget, 1));
    });

    test('without inflation the target is unchanged', () {
      final plan = FinalGoalPlan.compute(
        targetAmount: 150000000,
        saved: 27500000,
        today: today,
        deadline: deadline,
      );
      expect(plan.adjustedTarget, 150000000);
      expect(plan.inflationExtra, 0);
      expect(plan.realReturn, isNull);
      expect(plan.required.perMonth, closeTo(3399673.05, 1));
    });

    test('a yield lowers the required saving and gives a real return', () {
      final plan = FinalGoalPlan.compute(
        targetAmount: 150000000,
        saved: 27500000,
        today: today,
        deadline: deadline,
        adjustForInflation: true,
        inflationRate: 3.2,
        annualReturn: 4.5,
      );
      expect(plan.required.perMonth, closeTo(3471707.81, 1));
      expect(plan.required.perDay, closeTo(113936.00, 0.5));
      expect(plan.required.perWeek, closeTo(797840.64, 0.5));
      expect(plan.realReturn, closeTo(1.2597, 0.0001));
    });

    test('zero yield: week is 7 days and year is 365 days of the daily figure', () {
      final plan = FinalGoalPlan.compute(
        targetAmount: 10000000,
        saved: 0,
        today: today,
        deadline: DateTime(2027, 11, 16),
      );
      expect(plan.required.perWeek, closeTo(plan.required.perDay * 7, 0.01));
      expect(plan.required.perYear, closeTo(plan.required.perDay * 365, 0.01));
      expect(plan.required.perYear, closeTo(10000000, 0.01)); // exactly one year
    });

    test('series ends where balance meets the adjusted target', () {
      for (final r in [0.0, 4.5]) {
        final plan = FinalGoalPlan.compute(
          targetAmount: 150000000,
          saved: 27500000,
          today: today,
          deadline: deadline,
          adjustForInflation: true,
          inflationRate: 3.2,
          annualReturn: r,
        );
        final points = plan.series();
        expect(points.first.balance, closeTo(27500000, 0.01));
        expect(points.first.cost, closeTo(150000000, 0.01));
        expect(points.last.balance, closeTo(plan.adjustedTarget, 1), reason: 'r=$r');
        expect(points.last.cost, closeTo(plan.adjustedTarget, 1));
      }
    });

    test('overdue and reached goals need no further saving', () {
      final overdue = FinalGoalPlan.compute(
        targetAmount: 1000000,
        saved: 100000,
        today: today,
        deadline: DateTime(2026, 11, 1),
      );
      expect(overdue.isOverdue, isTrue);
      expect(overdue.required.perMonth, 0);

      final reached = FinalGoalPlan.compute(
        targetAmount: 1000000,
        saved: 1000000,
        today: today,
        deadline: deadline,
      );
      expect(reached.isReached, isTrue);
      expect(reached.required.perMonth, 0);
    });

    test('monthlyGap is positive when the recent pace is too low', () {
      final plan = FinalGoalPlan.compute(
        targetAmount: 150000000,
        saved: 27500000,
        today: today,
        deadline: deadline,
        adjustForInflation: true,
        inflationRate: 3.2,
      );
      expect(plan.monthlyGap(2400000), closeTo(1412627.69, 1));
      expect(plan.monthlyGap(5000000), lessThan(0));
    });
  });

  group('tenorTable', () {
    test('auto inflation uses a different default for each tenor', () {
      final rows = FinalGoalPlan.tenorTable(
        targetAmount: 150000000,
        saved: 27500000,
        today: DateTime(2026, 11, 16),
        adjustForInflation: true,
      );
      expect(rows.map((r) => r.years), [1, 2, 3, 4, 5, 10]);
      expect(rows.map((r) => r.plan.daysLeft), [365, 731, 1096, 1461, 1826, 3653]);
      expect(rows.map((r) => r.plan.inflationRate), [3.2, 3.2, 3.1, 3.1, 3.0, 2.9]);
    });

    test('an explicit rate overrides auto for every tenor', () {
      final rows = FinalGoalPlan.tenorTable(
        targetAmount: 150000000,
        saved: 0,
        today: DateTime(2026, 11, 16),
        adjustForInflation: true,
        inflationRate: 5.5,
      );
      expect(rows.every((r) => r.plan.inflationRate == 5.5), isTrue);
    });

    test('longer tenors lower the monthly need but raise the inflation burden', () {
      final rows = FinalGoalPlan.tenorTable(
        targetAmount: 150000000,
        saved: 27500000,
        today: DateTime(2026, 11, 16),
        adjustForInflation: true,
        inflationRate: 3.2,
      );
      for (var i = 1; i < rows.length; i++) {
        expect(rows[i].plan.required.perMonth, lessThan(rows[i - 1].plan.required.perMonth));
        expect(rows[i].plan.inflationExtraPercent,
            greaterThan(rows[i - 1].plan.inflationExtraPercent));
      }
    });
  });

  group('monthsToReach', () {
    test('inflation slows things down', () {
      final withInflation = FinalGoalPlan.monthsToReach(
        targetAmount: 150000000,
        saved: 27500000,
        monthlyContribution: 3000000,
        adjustForInflation: true,
        inflationRate: 3.2,
      );
      final without = FinalGoalPlan.monthsToReach(
        targetAmount: 150000000,
        saved: 27500000,
        monthlyContribution: 3000000,
      );
      expect(withInflation, 48);
      expect(without, 41);
    });

    test('returns null when the target outruns the saving', () {
      expect(
        FinalGoalPlan.monthsToReach(
          targetAmount: 150000000,
          saved: 0,
          monthlyContribution: 1000,
          adjustForInflation: true,
          inflationRate: 3.2,
        ),
        isNull,
      );
    });

    test('is 0 when already reached', () {
      expect(
        FinalGoalPlan.monthsToReach(
          targetAmount: 100,
          saved: 100,
          monthlyContribution: 0,
        ),
        0,
      );
    });
  });

  group('recentMonthlyPace', () {
    test('averages net deposits inside the window only', () {
      final today = DateTime(2026, 11, 16);
      final flows = [
        DatedAmount(DateTime(2026, 11, 10), 1500000),
        DatedAmount(DateTime(2026, 10, 1), 1500000),
        DatedAmount(DateTime(2026, 9, 1), -300000), // withdrawal
        DatedAmount(DateTime(2026, 8, 18), 9999999), // one day outside
        DatedAmount(DateTime(2026, 8, 19), 0), // first day inside
      ];
      expect(
        FinalGoalPlan.recentMonthlyPace(flows, today: today),
        closeTo(912500, 0.01), // 2.7M / 90 days * 30.4167
      );
    });
  });

  group('PeriodicPlan', () {
    test('equivalents for 120.000 per week', () {
      final plan = PeriodicPlan.compute(amount: 120000, unit: PeriodUnit.week);
      expect(plan.figures.perDay, closeTo(17142.857, 0.001));
      expect(plan.figures.perMonth, closeTo(521428.571, 0.001));
      expect(plan.figures.perYear, closeTo(6257142.857, 0.001));
    });

    test('projection without yield is just the sum of deposits', () {
      final plan = PeriodicPlan.compute(amount: 120000, unit: PeriodUnit.week);
      final oneYear = plan.projections.firstWhere((p) => p.horizon.label == '1 tahun');
      expect(oneYear.contributed, closeTo(6257142.857, 0.001));
      expect(oneYear.nominal, closeTo(6257142.857, 0.001));
      expect(oneYear.realValue, closeTo(6257142.857, 0.001));
    });

    test('a yield adds interest on top of the deposits', () {
      final plan = PeriodicPlan.compute(
        amount: 120000,
        unit: PeriodUnit.week,
        annualReturn: 4.5,
      );
      final oneYear = plan.projections.firstWhere((p) => p.horizon.label == '1 tahun');
      expect(oneYear.nominal, closeTo(6394196.16, 0.5));
      expect(oneYear.nominal, greaterThan(oneYear.contributed));
    });

    test('inflation discounts the projection to today\'s purchasing power', () {
      final plan = PeriodicPlan.compute(
        amount: 120000,
        unit: PeriodUnit.week,
        inflationRate: 3.2,
      );
      final fiveYears = plan.projections.firstWhere((p) => p.horizon.label == '5 tahun');
      expect(fiveYears.nominal, closeTo(31285714.29, 0.5));
      expect(fiveYears.realValue, closeTo(26726838.44, 0.5));
    });

    test('the same pace in any unit projects to the same amount', () {
      final weekly = PeriodicPlan.compute(amount: 120000, unit: PeriodUnit.week);
      final monthly = PeriodicPlan.compute(
        amount: weekly.figures.perMonth.round(),
        unit: PeriodUnit.month,
      );
      // The monthly amount was rounded to whole rupiah (0.43 off), which adds
      // up to ~51 over the 120 months of the 10-year horizon.
      expect(monthly.projections.last.nominal, closeTo(weekly.projections.last.nominal, 60));
    });

    test('daysToReach', () {
      final plan = PeriodicPlan.compute(amount: 120000, unit: PeriodUnit.week);
      expect(plan.daysToReach(1200000), closeTo(70, 0.0001));
      expect(plan.daysToReach(100, alreadySaved: 100), 0);

      final withYield = PeriodicPlan.compute(
        amount: 120000,
        unit: PeriodUnit.week,
        annualReturn: 4.5,
      );
      expect(withYield.daysToReach(100000000)!, lessThan(plan.daysToReach(100000000)!));
    });
  });

  group('PeriodicAdherence (weekly, 120.000)', () {
    final start = DateTime(2026, 10, 5); // a Monday
    final today = DateTime(2026, 11, 16); // 6 weeks later: 7th week
    final flows = [
      DatedAmount(DateTime(2026, 10, 6), 120000), // week 0 ok
      DatedAmount(DateTime(2026, 10, 14), 60000), // week 1: two halves
      DatedAmount(DateTime(2026, 10, 16), 60000),
      // week 2 (19-25 Oct): nothing
      DatedAmount(DateTime(2026, 10, 28), 150000), // week 3 ok
      DatedAmount(DateTime(2026, 11, 3), 120000), // week 4 ok
      DatedAmount(DateTime(2026, 11, 10), 120000), // week 5 ok
    ];

    PeriodicAdherence compute(List<DatedAmount> f) => PeriodicAdherence.compute(
          amount: 120000,
          unit: PeriodUnit.week,
          startDate: start,
          today: today,
          flows: f,
        );

    test('counts fulfilled, missed and streak', () {
      final a = compute(flows);
      expect(a.started, isTrue);
      expect(a.currentIndex, 6);
      expect(a.completedPeriods, 6);
      expect(a.fulfilledCompleted, 5);
      expect(a.missedPeriods, 1);
      expect(a.currentFulfilled, isFalse);
      expect(a.streak, 3); // weeks 3-5; the open week does not break it
      expect(a.bestStreak, 3);
      expect(a.actualTotal, 630000);
      expect(a.catchUp, 210000); // 7 weeks x 120k - 630k
      expect(a.currentTotal, 0);
      expect(a.currentRemaining, 120000);
      expect(a.currentPeriodEnd, DateTime(2026, 11, 22));
      expect(a.consistency, closeTo(5 / 6, 1e-9));
      expect(a.recent.length, 7);
      expect(a.recent.last.isCurrent, isTrue);
      expect(a.recent[2].fulfilled, isFalse);
    });

    test('depositing in the current week extends the streak', () {
      final a = compute([...flows, DatedAmount(DateTime(2026, 11, 16), 120000)]);
      expect(a.currentFulfilled, isTrue);
      expect(a.streak, 4);
      expect(a.currentRemaining, 0);
      expect(a.catchUp, 90000); // 7 x 120k - 750k
    });

    test('a withdrawal reduces a period below the amount', () {
      final a = compute([...flows, DatedAmount(DateTime(2026, 11, 11), -50000)]);
      expect(a.recent[5].fulfilled, isFalse);
      expect(a.streak, 0);
    });

    test('future-dated deposits are ignored', () {
      final a = compute([...flows, DatedAmount(DateTime(2026, 11, 20), 120000)]);
      expect(a.actualTotal, 630000);
    });

    test('before the start date nothing is due yet', () {
      final a = PeriodicAdherence.compute(
        amount: 120000,
        unit: PeriodUnit.week,
        startDate: DateTime(2027, 1, 4),
        today: today,
        flows: const [],
      );
      expect(a.started, isFalse);
      expect(a.completedPeriods, 0);
      expect(a.currentRemaining, 120000);
    });
  });

  group('PeriodicAdherence (monthly and daily)', () {
    test('monthly buckets follow calendar months', () {
      final a = PeriodicAdherence.compute(
        amount: 100000,
        unit: PeriodUnit.month,
        startDate: DateTime(2026, 1, 20),
        today: DateTime(2026, 4, 2),
        flows: [
          DatedAmount(DateTime(2026, 1, 25), 100000),
          DatedAmount(DateTime(2026, 2, 3), 100000),
          DatedAmount(DateTime(2026, 3, 30), 100000),
        ],
      );
      expect(a.currentIndex, 3); // Jan, Feb, Mar, Apr
      expect(a.fulfilledCompleted, 3);
      expect(a.streak, 3);
      expect(a.currentPeriodEnd, DateTime(2026, 4, 30));
    });

    test('daily buckets', () {
      final a = PeriodicAdherence.compute(
        amount: 10000,
        unit: PeriodUnit.day,
        startDate: DateTime(2026, 11, 10),
        today: DateTime(2026, 11, 13),
        flows: [
          DatedAmount(DateTime(2026, 11, 10), 10000),
          DatedAmount(DateTime(2026, 11, 11), 4000),
          DatedAmount(DateTime(2026, 11, 12), 10000),
        ],
      );
      expect(a.currentIndex, 3);
      expect(a.fulfilledCompleted, 2);
      expect(a.missedPeriods, 1);
      expect(a.streak, 1); // 12 Nov; 13 Nov is still open
      expect(a.bestStreak, 1);
      expect(a.currentPeriodEnd, DateTime(2026, 11, 13));
    });
  });

  group('InflationData', () {
    test('long-run averages match the bundled series', () {
      expect(InflationData.average10y, closeTo(2.8583, 0.0001));
      expect(InflationData.average5y, closeTo(2.8866, 0.0001));
    });

    test('auto rate steps down with the horizon', () {
      expect(InflationData.autoRateForDays(30), 3.2);
      expect(InflationData.autoRateForDays(731), 3.2); // 2 calendar years
      expect(InflationData.autoRateForDays(732), 3.1);
      expect(InflationData.autoRateForDays(1461), 3.1); // 4 calendar years
      expect(InflationData.autoRateForDays(1462), 3.0);
      expect(InflationData.autoRateForDays(2557), 3.0); // 7 calendar years
      expect(InflationData.autoRateForDays(2558), 2.9);
      expect(InflationData.autoRateForDays(3653), 2.9);
      expect(InflationData.resolve(5.5, 3653), 5.5);
      expect(InflationData.resolve(null, 3653), 2.9);
    });
  });
}
