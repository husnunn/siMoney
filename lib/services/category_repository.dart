import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/models.dart';
import 'firestore_paths.dart';

class CategoryRepository {
  Stream<List<TxCategory>> watchCustomCategories(String ledgerId) {
    return FsPaths.categories(ledgerId).snapshots().map(
          (snap) => snap.docs.map(TxCategory.fromDoc).toList(),
        );
  }

  Future<void> addCustomCategory({
    required String ledgerId,
    required String name,
    required String createdBy,
    String iconKey = 'label',
  }) async {
    await FsPaths.categories(ledgerId).add({
      'name': name.trim(),
      'iconKey': iconKey,
      'createdBy': createdBy,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deleteCustomCategory({
    required String ledgerId,
    required String categoryId,
  }) async {
    await FsPaths.categories(ledgerId).doc(categoryId).delete();
  }
}
