import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/models.dart';
import 'firestore_paths.dart';

class LedgerRepository {
  Future<Ledger> createLedger({
    required String name,
    required String ownerId,
  }) async {
    final ledgerRef = FsPaths.ledgers().doc();
    final code = await _generateUniqueInviteCode();
    final ledger = Ledger(
      id: ledgerRef.id,
      name: name.trim(),
      ownerId: ownerId,
      memberIds: [ownerId],
      inviteCode: code,
    );

    final batch = FsPaths.db.batch();
    batch.set(ledgerRef, ledger.toMap(includeCreatedAt: true));
    batch.set(FsPaths.inviteCode(code), {
      'ledgerId': ledgerRef.id,
      'createdAt': FieldValue.serverTimestamp(),
    });
    batch.update(FsPaths.user(ownerId), {'activeLedgerId': ledgerRef.id});
    await batch.commit();
    return ledger;
  }

  Future<Ledger> joinLedger({
    required String inviteCode,
    required String userId,
  }) async {
    final code = inviteCode.trim().toUpperCase();
    final inviteSnap = await FsPaths.inviteCode(code).get();
    if (!inviteSnap.exists) {
      throw StateError('Kode undangan tidak ditemukan.');
    }
    final ledgerId = inviteSnap.data()?['ledgerId'] as String?;
    if (ledgerId == null || ledgerId.isEmpty) {
      throw StateError('Kode undangan tidak valid.');
    }

    // No prior ledger read (rules block non-members). arrayUnion adds self.
    final ledgerRef = FsPaths.ledger(ledgerId);
    final batch = FsPaths.db.batch();
    batch.update(ledgerRef, {
      'memberIds': FieldValue.arrayUnion([userId]),
    });
    batch.update(FsPaths.user(userId), {'activeLedgerId': ledgerId});
    await batch.commit();

    final updated = await ledgerRef.get();
    if (!updated.exists) {
      throw StateError('Buku kas tidak ditemukan.');
    }
    return Ledger.fromDoc(updated);
  }

  Stream<Ledger?> watchLedger(String ledgerId) {
    return FsPaths.ledger(ledgerId).snapshots().map((snap) {
      if (!snap.exists) return null;
      return Ledger.fromDoc(snap);
    });
  }

  Future<Ledger?> getLedger(String ledgerId) async {
    final snap = await FsPaths.ledger(ledgerId).get();
    if (!snap.exists) return null;
    return Ledger.fromDoc(snap);
  }

  Future<List<Ledger>> getLedgersForUser(String userId) async {
    final snap = await FsPaths.ledgers()
        .where('memberIds', arrayContains: userId)
        .get();
    return snap.docs.map(Ledger.fromDoc).toList();
  }

  Stream<List<Ledger>> watchLedgersForUser(String userId) {
    return FsPaths.ledgers()
        .where('memberIds', arrayContains: userId)
        .snapshots()
        .map((snap) => snap.docs.map(Ledger.fromDoc).toList());
  }

  Future<String> _generateUniqueInviteCode() async {
    final random = Random.secure();
    for (var attempt = 0; attempt < 8; attempt++) {
      final suffix = List.generate(
        4,
        (_) => 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789'[random.nextInt(32)],
      ).join();
      final code = 'SIMONEY-$suffix';
      final exists = await FsPaths.inviteCode(code).get();
      if (!exists.exists) return code;
    }
    return 'SIMONEY-${DateTime.now().millisecondsSinceEpoch % 100000}';
  }
}
