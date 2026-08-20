import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/models.dart';
import 'firestore_paths.dart';

class UserRepository {
  UserRepository();

  Future<AppUser> upsertFromAuth(User user, {String? displayName}) async {
    final ref = FsPaths.user(user.uid);
    final snap = await ref.get();
    final name = displayName?.trim().isNotEmpty == true
        ? displayName!.trim()
        : (user.displayName?.trim().isNotEmpty == true
            ? user.displayName!.trim()
            : (user.email?.split('@').first ?? 'Pengguna'));
    final email = user.email ?? '';

    if (!snap.exists) {
      await ref.set({
        'name': name,
        'email': email,
        'activeLedgerId': null,
        'createdAt': FieldValue.serverTimestamp(),
      });
      return AppUser(id: user.uid, name: name, email: email);
    }

    final existing = AppUser.fromDoc(snap);
    final updates = <String, dynamic>{};
    if (existing.name != name && name.isNotEmpty) updates['name'] = name;
    if (existing.email != email && email.isNotEmpty) updates['email'] = email;
    if (updates.isNotEmpty) await ref.update(updates);

    return AppUser(
      id: user.uid,
      name: updates['name'] as String? ?? existing.name,
      email: updates['email'] as String? ?? existing.email,
      activeLedgerId: existing.activeLedgerId,
    );
  }

  Future<AppUser?> getUser(String uid) async {
    final snap = await FsPaths.user(uid).get();
    if (!snap.exists) return null;
    return AppUser.fromDoc(snap);
  }

  Future<List<AppUser>> getUsersByIds(List<String> ids) async {
    if (ids.isEmpty) return const [];
    final unique = ids.toSet().toList();
    final results = <AppUser>[];
    // Firestore whereIn limit 30 — fine for MVP (<10 members)
    for (var i = 0; i < unique.length; i += 30) {
      final chunk = unique.sublist(
        i,
        i + 30 > unique.length ? unique.length : i + 30,
      );
      final snap = await FsPaths.users()
          .where(FieldPath.documentId, whereIn: chunk)
          .get();
      results.addAll(snap.docs.map(AppUser.fromDoc));
    }
    return results;
  }

  Future<void> setActiveLedger(String uid, String? ledgerId) async {
    await FsPaths.user(uid).update({'activeLedgerId': ledgerId});
  }
}
