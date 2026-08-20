import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../models/models.dart';
import '../services/category_repository.dart';
import '../services/ledger_repository.dart';
import '../services/transaction_repository.dart';
import '../services/user_repository.dart';

/// App-wide state backed by Firestore realtime listeners.
class AppStore extends ChangeNotifier {
  AppStore({
    UserRepository? userRepository,
    LedgerRepository? ledgerRepository,
    TransactionRepository? transactionRepository,
    CategoryRepository? categoryRepository,
  })  : _users = userRepository ?? UserRepository(),
        _ledgers = ledgerRepository ?? LedgerRepository(),
        _transactions = transactionRepository ?? TransactionRepository(),
        _categories = categoryRepository ?? CategoryRepository();

  final UserRepository _users;
  final LedgerRepository _ledgers;
  final TransactionRepository _transactions;
  final CategoryRepository _categories;

  AppUser? currentUser;
  Ledger? currentLedger;
  List<Ledger> ledgers = [];
  List<TxRecord> transactions = [];
  List<TxCategory> customCategories = [];
  List<AppUser> members = [];
  DateTime selectedMonth = DateTime(DateTime.now().year, DateTime.now().month);
  DateTime selectedFlowDate = DateTime(
    DateTime.now().year,
    DateTime.now().month,
    DateTime.now().day,
  );
  bool isLoadingSession = false;
  String? sessionError;

  StreamSubscription<Ledger?>? _ledgerSub;
  StreamSubscription<List<Ledger>>? _ledgersListSub;
  StreamSubscription<List<TxRecord>>? _txSub;
  StreamSubscription<List<TxCategory>>? _catSub;

  // F11: Emits newly added transactions created by other members.
  final StreamController<TxRecord> _txNoticeController =
      StreamController<TxRecord>.broadcast();
  Stream<TxRecord> get txNotices => _txNoticeController.stream;
  final Set<String> _knownTxIds = <String>{};
  bool _txListenerInitialized = false;

  List<TxCategory> get categories => [
        ...DefaultCategories.all,
        ...customCategories,
      ];

  List<TxRecord> get filteredTransactions {
    return transactions
        .where(
          (t) =>
              t.createdAt.year == selectedMonth.year &&
              t.createdAt.month == selectedMonth.month,
        )
        .toList();
  }

  int get totalIncome => filteredTransactions
      .where((t) => t.isIncome)
      .fold(0, (sum, t) => sum + t.amount);

  int get totalExpense => filteredTransactions
      .where((t) => !t.isIncome)
      .fold(0, (sum, t) => sum + t.amount);

  int get balance => totalIncome - totalExpense;

  List<TxRecord> transactionsForFlowDate(TransactionType type) {
    return transactions
        .where(
          (t) =>
              t.type == type &&
              t.createdAt.year == selectedFlowDate.year &&
              t.createdAt.month == selectedFlowDate.month &&
              t.createdAt.day == selectedFlowDate.day,
        )
        .toList();
  }

  bool get hasLedger => currentLedger != null || ledgers.isNotEmpty;

  TxCategory? categoryById(String id) {
    for (final c in categories) {
      if (c.id == id) return c;
    }
    return null;
  }

  AppUser? userById(String id) {
    if (currentUser?.id == id) return currentUser;
    for (final u in members) {
      if (u.id == id) return u;
    }
    return null;
  }

  TxRecord? transactionById(String id) {
    for (final t in transactions) {
      if (t.id == id) return t;
    }
    return null;
  }

  Future<AppUser> bootstrapSession(User firebaseUser, {String? name}) async {
    isLoadingSession = true;
    sessionError = null;
    notifyListeners();
    try {
      final appUser = await _users.upsertFromAuth(
        firebaseUser,
        displayName: name,
      );
      currentUser = appUser;

      // Load all ledgers this user can access, then choose active ledger.
      await _detachLedger(notify: false);
      ledgers = await _ledgers.getLedgersForUser(appUser.id);

      final activeId = appUser.activeLedgerId;
      final activeLedgerId = (activeId != null &&
              activeId.isNotEmpty &&
              ledgers.any((l) => l.id == activeId))
          ? activeId
          : null;

      if (activeLedgerId != null) {
        await _attachLedger(activeLedgerId);
      } else if (ledgers.isNotEmpty) {
        // If activeLedgerId is empty/invalid, pick the first accessible ledger.
        final fallbackId = ledgers.first.id;
        await _users.setActiveLedger(appUser.id, fallbackId);
        currentUser = appUser.copyWith(activeLedgerId: fallbackId);
        await _attachLedger(fallbackId);
      } else {
        await _detachLedger();
      }

      // Keep ledgers list in sync for F10 switching UI.
      await _ledgersListSub?.cancel();
      _ledgersListSub =
          _ledgers.watchLedgersForUser(appUser.id).listen((list) async {
        ledgers = list;
        if (currentLedger != null &&
            !list.any((l) => l.id == currentLedger!.id)) {
          await _detachLedger();
          return;
        }
        notifyListeners();
      });
      return appUser;
    } catch (e) {
      sessionError = e.toString();
      rethrow;
    } finally {
      isLoadingSession = false;
      notifyListeners();
    }
  }

  Future<void> _attachLedger(String ledgerId) async {
    await _detachLedger(notify: false);
    final ledger = await _ledgers.getLedger(ledgerId);
    currentLedger = ledger;
    if (ledger == null) {
      // Stale pointer — try to fall back to any accessible ledger.
      if (ledgers.isNotEmpty) {
        final fallbackId = ledgers.first.id;
        await _users.setActiveLedger(currentUser!.id, fallbackId);
        currentUser = currentUser?.copyWith(activeLedgerId: fallbackId);
        await _attachLedger(fallbackId);
        return;
      }
      await _users.setActiveLedger(currentUser!.id, null);
      currentUser = currentUser?.copyWith(clearActiveLedgerId: true);
      notifyListeners();
      return;
    }

    members = await _users.getUsersByIds(ledger.memberIds);

    _ledgerSub = _ledgers.watchLedger(ledgerId).listen((l) async {
      currentLedger = l;
      if (l != null) {
        members = await _users.getUsersByIds(l.memberIds);
      }
      notifyListeners();
    });

    _txSub = _transactions.watchTransactions(ledgerId).listen((list) {
      final ids = list.map((t) => t.id).toSet();

      if (!_txListenerInitialized) {
        _knownTxIds
          ..clear()
          ..addAll(ids);
        _txListenerInitialized = true;
      } else {
        final userId = currentUser?.id;
        if (userId != null) {
          final newIds = ids.difference(_knownTxIds);
          final newFromOthers = list.where((t) {
            return newIds.contains(t.id) && t.createdBy != userId;
          });
          for (final tx in newFromOthers) {
            _txNoticeController.add(tx);
          }
        }
        _knownTxIds
          ..clear()
          ..addAll(ids);
      }

      transactions = list;
      notifyListeners();
    });

    _catSub = _categories.watchCustomCategories(ledgerId).listen((list) {
      customCategories = list;
      notifyListeners();
    });

    notifyListeners();
  }

  Future<void> _detachLedger({bool notify = true}) async {
    await _ledgerSub?.cancel();
    await _txSub?.cancel();
    await _catSub?.cancel();
    _ledgerSub = null;
    _txSub = null;
    _catSub = null;
    currentLedger = null;
    transactions = [];
    customCategories = [];
    members = [];
    _knownTxIds.clear();
    _txListenerInitialized = false;
    if (notify) notifyListeners();
  }

  Future<void> createLedger(String name) async {
    final user = currentUser;
    if (user == null) throw StateError('Belum login');
    final ledger = await _ledgers.createLedger(name: name, ownerId: user.id);
    currentUser = user.copyWith(activeLedgerId: ledger.id);
    await _attachLedger(ledger.id);
  }

  Future<void> joinLedger(String code) async {
    final user = currentUser;
    if (user == null) throw StateError('Belum login');
    final ledger =
        await _ledgers.joinLedger(inviteCode: code, userId: user.id);
    currentUser = user.copyWith(activeLedgerId: ledger.id);
    await _attachLedger(ledger.id);
  }

  Future<void> switchLedger(String ledgerId) async {
    final user = currentUser;
    if (user == null) throw StateError('Belum login');
    if (!ledgers.any((l) => l.id == ledgerId)) {
      throw StateError('Ledger tidak ditemukan.');
    }
    await _users.setActiveLedger(user.id, ledgerId);
    currentUser = user.copyWith(activeLedgerId: ledgerId);
    await _attachLedger(ledgerId);
  }

  void setSelectedMonth(DateTime month) {
    selectedMonth = DateTime(month.year, month.month);
    notifyListeners();
  }

  void setSelectedFlowDate(DateTime date) {
    selectedFlowDate = DateTime(date.year, date.month, date.day);
    notifyListeners();
  }

  Future<void> addTransaction({
    required TransactionType type,
    required int amount,
    required String categoryId,
    required String note,
    required DateTime createdAt,
  }) async {
    final user = currentUser;
    final ledger = currentLedger;
    if (user == null || ledger == null) {
      throw StateError('Ledger belum dipilih');
    }
    final category = categoryById(categoryId);
    await _transactions.addTransaction(
      ledgerId: ledger.id,
      type: type,
      amount: amount,
      categoryId: categoryId,
      categoryName: category?.name ?? 'Lainnya',
      note: note,
      createdBy: user.id,
      createdByName: user.name,
      createdAt: createdAt,
    );
  }

  Future<void> updateTransaction(TxRecord record) async {
    final ledger = currentLedger;
    if (ledger == null) throw StateError('Ledger belum dipilih');
    final category = categoryById(record.categoryId);
    await _transactions.updateTransaction(
      ledgerId: ledger.id,
      record: record.copyWith(
        categoryName: category?.name ?? record.categoryName,
      ),
    );
  }

  Future<void> deleteTransaction(String id) async {
    final ledger = currentLedger;
    if (ledger == null) throw StateError('Ledger belum dipilih');
    await _transactions.deleteTransaction(
      ledgerId: ledger.id,
      transactionId: id,
    );
  }

  Future<void> addCategory(String name) async {
    final user = currentUser;
    final ledger = currentLedger;
    if (user == null || ledger == null) {
      throw StateError('Ledger belum dipilih');
    }
    await _categories.addCustomCategory(
      ledgerId: ledger.id,
      name: name,
      createdBy: user.id,
    );
  }

  Future<void> deleteCategory(String categoryId) async {
    final ledger = currentLedger;
    if (ledger == null) throw StateError('Ledger belum dipilih');

    // Only custom categories are deletable (default categories live on client only).
    final existsInCustom = customCategories.any((c) => c.id == categoryId);
    if (!existsInCustom) return;

    await _categories.deleteCustomCategory(
      ledgerId: ledger.id,
      categoryId: categoryId,
    );
  }

  Future<void> clearSession() async {
    await _detachLedger();
    await _ledgersListSub?.cancel();
    _ledgersListSub = null;
    ledgers = [];
    currentUser = null;
    sessionError = null;
    notifyListeners();
  }

  @override
  void dispose() {
    unawaited(_detachLedger(notify: false));
    unawaited(_ledgersListSub?.cancel());
    unawaited(_txNoticeController.close());
    _knownTxIds.clear();
    super.dispose();
  }
}

final appStore = AppStore();
