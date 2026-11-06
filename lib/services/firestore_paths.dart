import 'package:cloud_firestore/cloud_firestore.dart';

abstract final class FsPaths {
  static final FirebaseFirestore db = FirebaseFirestore.instance;

  static CollectionReference<Map<String, dynamic>> users() =>
      db.collection('users');

  static DocumentReference<Map<String, dynamic>> user(String uid) =>
      users().doc(uid);

  static CollectionReference<Map<String, dynamic>> ledgers() =>
      db.collection('ledgers');

  static DocumentReference<Map<String, dynamic>> ledger(String id) =>
      ledgers().doc(id);

  static CollectionReference<Map<String, dynamic>> inviteCodes() =>
      db.collection('inviteCodes');

  static DocumentReference<Map<String, dynamic>> inviteCode(String code) =>
      inviteCodes().doc(code);

  static CollectionReference<Map<String, dynamic>> transactions(
    String ledgerId,
  ) =>
      ledger(ledgerId).collection('transactions');

  static CollectionReference<Map<String, dynamic>> categories(String ledgerId) =>
      ledger(ledgerId).collection('categories');

  static CollectionReference<Map<String, dynamic>> savingsGoals(
    String ledgerId,
  ) =>
      ledger(ledgerId).collection('savingsGoals');

  static CollectionReference<Map<String, dynamic>> savingsContributions(
    String ledgerId,
  ) =>
      ledger(ledgerId).collection('savingsContributions');
}
