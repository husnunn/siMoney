import '../models/models.dart';
import 'firestore_paths.dart';

class SavingsRepository {
  Stream<List<SavingsGoal>> watchGoals(String ledgerId) {
    return FsPaths.savingsGoals(ledgerId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map(SavingsGoal.fromDoc).toList());
  }

  Stream<List<SavingsContribution>> watchContributions(String ledgerId) {
    return FsPaths.savingsContributions(ledgerId)
        .orderBy('date', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map(SavingsContribution.fromDoc).toList());
  }

  /// Writes [draft] as a new goal; its `id` is replaced by the generated one.
  Future<String> addGoal({
    required String ledgerId,
    required SavingsGoal draft,
  }) async {
    final ref = FsPaths.savingsGoals(ledgerId).doc();
    final goal = draft.copyWith(id: ref.id);
    await ref.set(goal.toMap(includeCreatedAt: true));
    return ref.id;
  }

  Future<void> updateGoal({
    required String ledgerId,
    required SavingsGoal goal,
  }) async {
    await FsPaths.savingsGoals(ledgerId).doc(goal.id).update(goal.toMap());
  }

  Future<void> deleteGoal({
    required String ledgerId,
    required String goalId,
  }) async {
    await FsPaths.savingsGoals(ledgerId).doc(goalId).delete();
  }

  Future<String> addContribution({
    required String ledgerId,
    required String goalId,
    required int amount,
    required DateTime date,
    required String note,
    required ContributionType type,
    required ContributionSource source,
    required String createdBy,
    required String createdByName,
  }) async {
    final ref = FsPaths.savingsContributions(ledgerId).doc();
    final contribution = SavingsContribution(
      id: ref.id,
      goalId: goalId,
      amount: amount,
      date: date,
      note: note,
      type: type,
      source: source,
      createdBy: createdBy,
      createdByName: createdByName,
    );
    await ref.set(contribution.toMap());
    return ref.id;
  }

  Future<void> deleteContribution({
    required String ledgerId,
    required String contributionId,
  }) async {
    await FsPaths.savingsContributions(ledgerId).doc(contributionId).delete();
  }
}
