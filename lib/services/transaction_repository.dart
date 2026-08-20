import '../models/models.dart';
import 'firestore_paths.dart';

class TransactionRepository {
  Stream<List<TxRecord>> watchTransactions(String ledgerId) {
    return FsPaths.transactions(ledgerId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snap) => snap.docs
              .map((d) => TxRecord.fromDoc(d, ledgerId: ledgerId))
              .toList(),
        );
  }

  Future<String> addTransaction({
    required String ledgerId,
    required TransactionType type,
    required int amount,
    required String categoryId,
    required String categoryName,
    required String note,
    required String createdBy,
    required String createdByName,
    required DateTime createdAt,
  }) async {
    final ref = FsPaths.transactions(ledgerId).doc();
    final record = TxRecord(
      id: ref.id,
      ledgerId: ledgerId,
      type: type,
      amount: amount,
      categoryId: categoryId,
      categoryName: categoryName,
      note: note,
      createdBy: createdBy,
      createdByName: createdByName,
      createdAt: createdAt,
    );
    await ref.set(record.toMap());
    return ref.id;
  }

  Future<void> updateTransaction({
    required String ledgerId,
    required TxRecord record,
  }) async {
    await FsPaths.transactions(ledgerId).doc(record.id).update(record.toMap());
  }

  Future<void> deleteTransaction({
    required String ledgerId,
    required String transactionId,
  }) async {
    await FsPaths.transactions(ledgerId).doc(transactionId).delete();
  }
}
