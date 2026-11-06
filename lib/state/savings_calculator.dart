import '../models/models.dart';

class SavingsValidationException implements Exception {
  SavingsValidationException(this.message);

  final String message;

  @override
  String toString() => message;
}

abstract final class SavingsCalculator {
  static int goalProgress(String goalId, List<SavingsContribution> all) {
    return all
        .where((c) => c.goalId == goalId)
        .fold(0, (sum, c) => sum + c.progressDelta);
  }

  static int appBalanceDeductionFromSavings(List<SavingsContribution> all) {
    return all.fold(0, (sum, c) => sum + c.appBalanceDelta);
  }

  static int allTimeTotalIncome(List<TxRecord> txs) {
    return txs.where((t) => t.isIncome).fold(0, (sum, t) => sum + t.amount);
  }

  static int allTimeTotalExpense(List<TxRecord> txs) {
    return txs.where((t) => !t.isIncome).fold(0, (sum, t) => sum + t.amount);
  }

  static int availableAppBalance(
    List<TxRecord> txs,
    List<SavingsContribution> contributions,
  ) {
    return allTimeTotalIncome(txs) -
        allTimeTotalExpense(txs) +
        appBalanceDeductionFromSavings(contributions);
  }

  static int totalSavingsAcrossGoals(List<SavingsContribution> all) {
    return all.fold(0, (sum, c) => sum + c.progressDelta);
  }

  static int totalDeposits(List<SavingsContribution> all) {
    return all
        .where((c) => c.isDeposit)
        .fold(0, (sum, c) => sum + c.amount);
  }

  static int totalWithdrawals(List<SavingsContribution> all) {
    return all
        .where((c) => !c.isDeposit)
        .fold(0, (sum, c) => sum + c.amount);
  }

  static void validateContribution({
    required SavingsGoal goal,
    required ContributionType type,
    required ContributionSource source,
    required int amount,
    required List<TxRecord> txs,
    required List<SavingsContribution> allContributions,
  }) {
    if (amount <= 0) {
      throw SavingsValidationException('Nominal harus lebih dari 0');
    }
    if (type == ContributionType.withdraw) {
      final currentProgress = goalProgress(goal.id, allContributions);
      if (amount > currentProgress) {
        throw SavingsValidationException(
          'Penarikan melebihi progres tabungan saat ini',
        );
      }
    } else if (source == ContributionSource.appBalance) {
      final available = availableAppBalance(txs, allContributions);
      if (amount > available) {
        throw SavingsValidationException(
          'Saldo aplikasi tidak mencukupi untuk setoran ini',
        );
      }
    }
  }
}
