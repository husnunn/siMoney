import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AppUser {
  const AppUser({
    required this.id,
    required this.name,
    required this.email,
    this.activeLedgerId,
  });

  final String id;
  final String name;
  final String email;
  final String? activeLedgerId;

  String get initials {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty) return '?';
    if (parts.length == 1) {
      return parts.first.substring(0, 1).toUpperCase();
    }
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }

  AppUser copyWith({
    String? id,
    String? name,
    String? email,
    String? activeLedgerId,
    bool clearActiveLedgerId = false,
  }) {
    return AppUser(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      activeLedgerId: clearActiveLedgerId
          ? null
          : (activeLedgerId ?? this.activeLedgerId),
    );
  }

  Map<String, dynamic> toMap({bool includeCreatedAt = false}) {
    return {
      'name': name,
      'email': email,
      'activeLedgerId': activeLedgerId,
      if (includeCreatedAt) 'createdAt': FieldValue.serverTimestamp(),
    };
  }

  factory AppUser.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return AppUser(
      id: doc.id,
      name: data['name'] as String? ?? 'Pengguna',
      email: data['email'] as String? ?? '',
      activeLedgerId: data['activeLedgerId'] as String?,
    );
  }
}

class Ledger {
  const Ledger({
    required this.id,
    required this.name,
    required this.ownerId,
    required this.memberIds,
    required this.inviteCode,
  });

  final String id;
  final String name;
  final String ownerId;
  final List<String> memberIds;
  final String inviteCode;

  Ledger copyWith({
    String? id,
    String? name,
    String? ownerId,
    List<String>? memberIds,
    String? inviteCode,
  }) {
    return Ledger(
      id: id ?? this.id,
      name: name ?? this.name,
      ownerId: ownerId ?? this.ownerId,
      memberIds: memberIds ?? this.memberIds,
      inviteCode: inviteCode ?? this.inviteCode,
    );
  }

  Map<String, dynamic> toMap({bool includeCreatedAt = false}) {
    return {
      'name': name,
      'ownerId': ownerId,
      'memberIds': memberIds,
      'inviteCode': inviteCode,
      if (includeCreatedAt) 'createdAt': FieldValue.serverTimestamp(),
    };
  }

  factory Ledger.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return Ledger(
      id: doc.id,
      name: data['name'] as String? ?? 'Buku kas',
      ownerId: data['ownerId'] as String? ?? '',
      memberIds: List<String>.from(data['memberIds'] as List? ?? const []),
      inviteCode: data['inviteCode'] as String? ?? '',
    );
  }
}

enum TransactionType { income, expense }

class TxRecord {
  const TxRecord({
    required this.id,
    required this.ledgerId,
    required this.type,
    required this.amount,
    required this.categoryId,
    required this.categoryName,
    required this.note,
    required this.createdBy,
    required this.createdByName,
    required this.createdAt,
  });

  final String id;
  final String ledgerId;
  final TransactionType type;
  final int amount;
  final String categoryId;
  final String categoryName;
  final String note;
  final String createdBy;
  final String createdByName;
  final DateTime createdAt;

  bool get isIncome => type == TransactionType.income;

  TxRecord copyWith({
    String? id,
    String? ledgerId,
    TransactionType? type,
    int? amount,
    String? categoryId,
    String? categoryName,
    String? note,
    String? createdBy,
    String? createdByName,
    DateTime? createdAt,
  }) {
    return TxRecord(
      id: id ?? this.id,
      ledgerId: ledgerId ?? this.ledgerId,
      type: type ?? this.type,
      amount: amount ?? this.amount,
      categoryId: categoryId ?? this.categoryId,
      categoryName: categoryName ?? this.categoryName,
      note: note ?? this.note,
      createdBy: createdBy ?? this.createdBy,
      createdByName: createdByName ?? this.createdByName,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'type': type == TransactionType.income ? 'income' : 'expense',
      'amount': amount,
      'categoryId': categoryId,
      'categoryName': categoryName,
      'note': note,
      'createdBy': createdBy,
      'createdByName': createdByName,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  factory TxRecord.fromDoc(
    DocumentSnapshot<Map<String, dynamic>> doc, {
    required String ledgerId,
  }) {
    final data = doc.data() ?? {};
    final typeRaw = data['type'] as String? ?? 'expense';
    final createdAt = data['createdAt'];
    return TxRecord(
      id: doc.id,
      ledgerId: ledgerId,
      type: typeRaw == 'income'
          ? TransactionType.income
          : TransactionType.expense,
      amount: (data['amount'] as num?)?.toInt() ?? 0,
      categoryId: data['categoryId'] as String? ?? 'c8',
      categoryName: data['categoryName'] as String? ?? 'Lainnya',
      note: data['note'] as String? ?? '',
      createdBy: data['createdBy'] as String? ?? '',
      createdByName: data['createdByName'] as String? ?? 'Pengguna',
      createdAt: createdAt is Timestamp
          ? createdAt.toDate()
          : DateTime.now(),
    );
  }
}

class TxCategory {
  const TxCategory({
    required this.id,
    required this.name,
    required this.icon,
    this.iconKey = 'label',
    this.isCustom = false,
    this.createdBy = '',
  });

  final String id;
  final String name;
  final IconData icon;
  final String iconKey;
  final bool isCustom;
  final String createdBy;

  Map<String, dynamic> toMap({required String createdBy}) {
    return {
      'name': name,
      'iconKey': iconKey,
      'createdBy': createdBy,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }

  factory TxCategory.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    final key = data['iconKey'] as String? ?? 'label';
    return TxCategory(
      id: doc.id,
      name: data['name'] as String? ?? 'Custom',
      icon: CategoryIcons.iconFor(key),
      iconKey: key,
      isCustom: true,
      createdBy: data['createdBy'] as String? ?? '',
    );
  }
}

abstract final class CategoryIcons {
  static IconData iconFor(String key) {
    switch (key) {
      case 'restaurant':
        return Icons.restaurant_outlined;
      case 'transport':
        return Icons.directions_car_outlined;
      case 'shopping':
        return Icons.shopping_bag_outlined;
      case 'bills':
        return Icons.receipt_long_outlined;
      case 'salary':
        return Icons.payments_outlined;
      case 'entertainment':
        return Icons.movie_outlined;
      case 'health':
        return Icons.local_hospital_outlined;
      default:
        return Icons.label_outline;
    }
  }
}

abstract final class DefaultCategories {
  static const List<TxCategory> all = [
    TxCategory(
      id: 'c1',
      name: 'Makan',
      icon: Icons.restaurant_outlined,
      iconKey: 'restaurant',
    ),
    TxCategory(
      id: 'c2',
      name: 'Transport',
      icon: Icons.directions_car_outlined,
      iconKey: 'transport',
    ),
    TxCategory(
      id: 'c3',
      name: 'Belanja',
      icon: Icons.shopping_bag_outlined,
      iconKey: 'shopping',
    ),
    TxCategory(
      id: 'c4',
      name: 'Tagihan',
      icon: Icons.receipt_long_outlined,
      iconKey: 'bills',
    ),
    TxCategory(
      id: 'c5',
      name: 'Gaji',
      icon: Icons.payments_outlined,
      iconKey: 'salary',
    ),
    TxCategory(
      id: 'c6',
      name: 'Hiburan',
      icon: Icons.movie_outlined,
      iconKey: 'entertainment',
    ),
    TxCategory(
      id: 'c7',
      name: 'Kesehatan',
      icon: Icons.local_hospital_outlined,
      iconKey: 'health',
    ),
    TxCategory(
      id: 'c8',
      name: 'Lainnya',
      icon: Icons.more_horiz,
      iconKey: 'label',
    ),
  ];
}
