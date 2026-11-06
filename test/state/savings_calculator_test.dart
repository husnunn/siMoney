import 'package:flutter_test/flutter_test.dart';
import 'package:simoney/models/models.dart';
import 'package:simoney/state/savings_calculator.dart';

TxRecord _tx({required bool income, required int amount, DateTime? at}) {
  return TxRecord(
    id: 'tx-${income ? 'in' : 'out'}-$amount-${at?.millisecondsSinceEpoch ?? 0}',
    ledgerId: 'ledger-1',
    type: income ? TransactionType.income : TransactionType.expense,
    amount: amount,
    categoryId: 'c1',
    categoryName: 'Test',
    note: '',
    createdBy: 'u1',
    createdByName: 'User',
    createdAt: at ?? DateTime(2026, 1, 1),
  );
}

SavingsGoal _goal({
  String id = 'g1',
  int targetAmount = 1000000,
  SavingsGoalStatus status = SavingsGoalStatus.active,
}) {
  return SavingsGoal(
    id: id,
    name: 'Goal',
    targetAmount: targetAmount,
    status: status,
    createdAt: DateTime(2026, 1, 1),
    createdBy: 'u1',
  );
}

SavingsContribution _contrib({
  String id = 'c1',
  String goalId = 'g1',
  required int amount,
  required ContributionType type,
  required ContributionSource source,
}) {
  return SavingsContribution(
    id: id,
    goalId: goalId,
    amount: amount,
    date: DateTime(2026, 1, 1),
    note: '',
    type: type,
    source: source,
    createdBy: 'u1',
    createdByName: 'User',
  );
}

void main() {
  group('goalProgress', () {
    test('nets deposits minus withdrawals, scoped to the right goal', () {
      final contributions = [
        _contrib(
          id: 'c1',
          goalId: 'g1',
          amount: 500000,
          type: ContributionType.deposit,
          source: ContributionSource.appBalance,
        ),
        _contrib(
          id: 'c2',
          goalId: 'g1',
          amount: 100000,
          type: ContributionType.withdraw,
          source: ContributionSource.external,
        ),
        // Unrelated goal's contributions must not leak in.
        _contrib(
          id: 'c3',
          goalId: 'g2',
          amount: 999999,
          type: ContributionType.deposit,
          source: ContributionSource.appBalance,
        ),
      ];

      expect(SavingsCalculator.goalProgress('g1', contributions), 400000);
      expect(SavingsCalculator.goalProgress('g2', contributions), 999999);
    });
  });

  group('availableAppBalance — all 4 type x source combinations', () {
    final txs = [
      _tx(income: true, amount: 1000000),
      _tx(income: false, amount: 400000),
    ];
    // Raw balance (income - expense) = 600000.

    test('deposit + appBalance decreases available balance', () {
      final contributions = [
        _contrib(
          amount: 200000,
          type: ContributionType.deposit,
          source: ContributionSource.appBalance,
        ),
      ];
      expect(
        SavingsCalculator.availableAppBalance(txs, contributions),
        400000,
      );
    });

    test('deposit + external leaves available balance unchanged', () {
      final contributions = [
        _contrib(
          amount: 200000,
          type: ContributionType.deposit,
          source: ContributionSource.external,
        ),
      ];
      expect(
        SavingsCalculator.availableAppBalance(txs, contributions),
        600000,
      );
    });

    test('withdraw + appBalance increases available balance', () {
      final contributions = [
        _contrib(
          amount: 200000,
          type: ContributionType.withdraw,
          source: ContributionSource.appBalance,
        ),
      ];
      expect(
        SavingsCalculator.availableAppBalance(txs, contributions),
        800000,
      );
    });

    test('withdraw + external leaves available balance unchanged', () {
      final contributions = [
        _contrib(
          amount: 200000,
          type: ContributionType.withdraw,
          source: ContributionSource.external,
        ),
      ];
      expect(
        SavingsCalculator.availableAppBalance(txs, contributions),
        600000,
      );
    });

    test('deposit then withdraw from appBalance composes correctly', () {
      final contributions = [
        _contrib(
          id: 'c1',
          amount: 200000,
          type: ContributionType.deposit,
          source: ContributionSource.appBalance,
        ),
        _contrib(
          id: 'c2',
          amount: 50000,
          type: ContributionType.withdraw,
          source: ContributionSource.appBalance,
        ),
      ];
      expect(
        SavingsCalculator.availableAppBalance(txs, contributions),
        450000,
      );
    });
  });

  group('totalDeposits / totalWithdrawals', () {
    test('sums deposits and withdrawals independently, across sources', () {
      final contributions = [
        _contrib(
          id: 'c1',
          goalId: 'g1',
          amount: 300000,
          type: ContributionType.deposit,
          source: ContributionSource.appBalance,
        ),
        _contrib(
          id: 'c2',
          goalId: 'g1',
          amount: 200000,
          type: ContributionType.deposit,
          source: ContributionSource.external,
        ),
        _contrib(
          id: 'c3',
          goalId: 'g2',
          amount: 100000,
          type: ContributionType.withdraw,
          source: ContributionSource.appBalance,
        ),
      ];

      expect(SavingsCalculator.totalDeposits(contributions), 500000);
      expect(SavingsCalculator.totalWithdrawals(contributions), 100000);
    });

    test('returns 0 for an empty list', () {
      expect(SavingsCalculator.totalDeposits(const []), 0);
      expect(SavingsCalculator.totalWithdrawals(const []), 0);
    });
  });

  group('all-time totals ignore selectedMonth entirely', () {
    test('sums income/expense across multiple months', () {
      final txs = [
        _tx(income: true, amount: 100000, at: DateTime(2026, 1, 15)),
        _tx(income: true, amount: 200000, at: DateTime(2026, 6, 1)),
        _tx(income: false, amount: 50000, at: DateTime(2025, 12, 1)),
      ];
      expect(SavingsCalculator.allTimeTotalIncome(txs), 300000);
      expect(SavingsCalculator.allTimeTotalExpense(txs), 50000);
    });
  });

  group('validateContribution', () {
    final txs = [
      _tx(income: true, amount: 1000000),
      _tx(income: false, amount: 400000),
    ];
    // available app balance with no contributions = 600000

    test('amount must be > 0', () {
      expect(
        () => SavingsCalculator.validateContribution(
          goal: _goal(),
          type: ContributionType.deposit,
          source: ContributionSource.appBalance,
          amount: 0,
          txs: txs,
          allContributions: const [],
        ),
        throwsA(isA<SavingsValidationException>()),
      );
    });

    test('deposit + appBalance passes at exactly available balance', () {
      expect(
        () => SavingsCalculator.validateContribution(
          goal: _goal(),
          type: ContributionType.deposit,
          source: ContributionSource.appBalance,
          amount: 600000,
          txs: txs,
          allContributions: const [],
        ),
        returnsNormally,
      );
    });

    test('deposit + appBalance throws at 1 above available balance', () {
      expect(
        () => SavingsCalculator.validateContribution(
          goal: _goal(),
          type: ContributionType.deposit,
          source: ContributionSource.appBalance,
          amount: 600001,
          txs: txs,
          allContributions: const [],
        ),
        throwsA(isA<SavingsValidationException>()),
      );
    });

    test('deposit + external never throws regardless of available balance', () {
      expect(
        () => SavingsCalculator.validateContribution(
          goal: _goal(),
          type: ContributionType.deposit,
          source: ContributionSource.external,
          amount: 999999999,
          txs: txs,
          allContributions: const [],
        ),
        returnsNormally,
      );
    });

    test('withdraw passes at exactly current progress', () {
      final contributions = [
        _contrib(
          amount: 300000,
          type: ContributionType.deposit,
          source: ContributionSource.external,
        ),
      ];
      expect(
        () => SavingsCalculator.validateContribution(
          goal: _goal(),
          type: ContributionType.withdraw,
          source: ContributionSource.external,
          amount: 300000,
          txs: txs,
          allContributions: contributions,
        ),
        returnsNormally,
      );
    });

    test('withdraw throws at 1 above current progress', () {
      final contributions = [
        _contrib(
          amount: 300000,
          type: ContributionType.deposit,
          source: ContributionSource.external,
        ),
      ];
      expect(
        () => SavingsCalculator.validateContribution(
          goal: _goal(),
          type: ContributionType.withdraw,
          source: ContributionSource.external,
          amount: 300001,
          txs: txs,
          allContributions: contributions,
        ),
        throwsA(isA<SavingsValidationException>()),
      );
    });
  });
}
