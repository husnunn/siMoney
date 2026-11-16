import 'package:cloud_firestore/cloud_firestore.dart' show Timestamp;
import 'package:flutter_test/flutter_test.dart';
import 'package:simoney/models/models.dart';

void main() {
  group('SavingsGoal storage', () {
    test('a document from before the two goal kinds reads as a plain target', () {
      final goal = SavingsGoal.fromMap('g1', {
        'name': 'Dana darurat',
        'targetAmount': 20000000,
        'targetDate': Timestamp.fromDate(DateTime(2027, 6, 1)),
        'status': 'active',
        'createdBy': 'u1',
        'createdAt': Timestamp.fromDate(DateTime(2026, 1, 1)),
      });

      expect(goal.id, 'g1');
      expect(goal.kind, SavingsGoalKind.target);
      expect(goal.isPeriodic, isFalse);
      expect(goal.targetAmount, 20000000);
      expect(goal.targetDate, DateTime(2027, 6, 1));
      expect(goal.adjustForInflation, isFalse);
      expect(goal.inflationRate, isNull);
      expect(goal.expectedReturn, 0);
      expect(goal.periodicAmount, isNull);
      expect(goal.periodUnit, isNull);
      expect(goal.startDate, isNull);
      expect(goal.priceDate, isNull);
      // Inflation, if ever switched on, counts from when the goal was created.
      expect(goal.effectivePriceDate, DateTime(2026, 1, 1));
    });

    test('a periodic goal survives toMap and fromMap', () {
      final goal = SavingsGoal(
        id: 'p1',
        name: 'Celengan mingguan',
        targetAmount: 0,
        status: SavingsGoalStatus.active,
        createdAt: DateTime(2026, 11, 1),
        createdBy: 'u1',
        kind: SavingsGoalKind.periodic,
        periodicAmount: 120000,
        periodUnit: PeriodUnit.week,
        startDate: DateTime(2026, 11, 2),
        adjustForInflation: true,
        inflationRate: 3.1,
        expectedReturn: 4.5,
      );

      final map = goal.toMap();
      expect(map['kind'], 'periodic');
      expect(map['periodUnit'], 'week');
      expect(map['targetAmount'], 0);

      final back = SavingsGoal.fromMap('p1', {
        ...map,
        'createdAt': Timestamp.fromDate(goal.createdAt),
      });
      expect(back.isPeriodic, isTrue);
      expect(back.periodicAmount, 120000);
      expect(back.periodUnit, PeriodUnit.week);
      expect(back.startDate, DateTime(2026, 11, 2));
      expect(back.adjustForInflation, isTrue);
      expect(back.inflationRate, 3.1);
      expect(back.expectedReturn, 4.5);
    });

    test('a target goal keeps its price date', () {
      final goal = SavingsGoal(
        id: 'g2',
        name: 'Laptop',
        targetAmount: 18000000,
        targetDate: DateTime(2027, 5, 1),
        status: SavingsGoalStatus.active,
        createdAt: DateTime(2026, 11, 1),
        createdBy: 'u1',
        adjustForInflation: true,
        priceDate: DateTime(2026, 10, 15),
      );
      final back = SavingsGoal.fromMap('g2', {
        ...goal.toMap(),
        'createdAt': Timestamp.fromDate(goal.createdAt),
      });
      expect(back.priceDate, DateTime(2026, 10, 15));
      expect(back.effectivePriceDate, DateTime(2026, 10, 15));
      expect(back.inflationRate, isNull, reason: 'null means automatic');
    });

    test('unknown stored values fall back instead of crashing', () {
      final goal = SavingsGoal.fromMap('g3', {
        'name': 'X',
        'targetAmount': 1,
        'status': 'mystery',
        'kind': 'weird',
        'periodUnit': 'fortnight',
      });
      expect(goal.kind, SavingsGoalKind.target);
      expect(goal.status, SavingsGoalStatus.active);
      expect(goal.periodUnit, isNull);
    });

    test('copyWith can clear the deadline and the inflation rate', () {
      final goal = SavingsGoal(
        id: 'g4',
        name: 'X',
        targetAmount: 100,
        targetDate: DateTime(2028, 1, 1),
        status: SavingsGoalStatus.active,
        createdAt: DateTime(2026, 1, 1),
        createdBy: 'u1',
        adjustForInflation: true,
        inflationRate: 5.5,
      );
      expect(goal.copyWith(name: 'Y').inflationRate, 5.5);
      expect(goal.copyWith(clearInflationRate: true).inflationRate, isNull);
      expect(goal.copyWith(clearTargetDate: true).targetDate, isNull);
    });
  });

  group('PeriodUnit', () {
    test('only day, week and month can be picked', () {
      expect(PeriodUnit.selectable, [PeriodUnit.day, PeriodUnit.week, PeriodUnit.month]);
    });

    test('units are consistent: a week is 7 days, a year is 12 months', () {
      expect(PeriodUnit.week.days, 7 * PeriodUnit.day.days);
      expect(PeriodUnit.year.days, closeTo(12 * PeriodUnit.month.days, 1e-9));
    });

    test('fromName', () {
      expect(PeriodUnit.fromName('month'), PeriodUnit.month);
      expect(PeriodUnit.fromName('nope'), isNull);
      expect(PeriodUnit.fromName(null), isNull);
    });
  });
}
