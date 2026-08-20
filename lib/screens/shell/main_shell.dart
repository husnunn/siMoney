import 'dart:async';

import 'package:flutter/material.dart';

import '../../models/transaction.dart';
import '../../theme/app_colors.dart';
import '../../state/app_store.dart';
import '../account/account_screen.dart';
import '../flow/income_expense_screen.dart';
import '../home/home_screen.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  static const routeName = '/home';

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 0;
  StreamSubscription<TxRecord>? _noticeSub;
  Timer? _noticeTimer;
  int _pendingNoticeCount = 0;
  TxRecord? _pendingNoticeTx;

  @override
  void initState() {
    super.initState();

    // F11: in-app realtime notifications for transactions from other members.
    _noticeSub = appStore.txNotices.listen((tx) {
      _pendingNoticeCount += 1;
      _pendingNoticeTx = tx;
      _noticeTimer?.cancel();
      _noticeTimer = Timer(const Duration(seconds: 2), () {
        if (!mounted) return;
        final last = _pendingNoticeTx;
        if (last == null) return;

        final creator = last.createdByName.isNotEmpty
            ? last.createdByName
            : 'Anggota lain';
        final typeLabel = last.isIncome ? 'Pemasukan' : 'Pengeluaran';

        final text = _pendingNoticeCount > 1
            ? 'Ada $_pendingNoticeCount transaksi baru dari $creator'
            : '$typeLabel baru oleh $creator (Rp ${last.amount})';

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 3),
            content: Text(text),
          ),
        );

        _pendingNoticeCount = 0;
        _pendingNoticeTx = null;
      });
    });
  }

  @override
  void dispose() {
    _noticeSub?.cancel();
    _noticeTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _index,
        children: const [
          HomeScreen(),
          IncomeExpenseScreen(type: TransactionType.income),
          IncomeExpenseScreen(type: TransactionType.expense),
          AccountScreen(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        backgroundColor: AppColors.surface,
        indicatorColor: AppColors.mutedSurface,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Beranda',
          ),
          NavigationDestination(
            icon: Icon(Icons.arrow_downward_outlined),
            selectedIcon: Icon(Icons.arrow_downward),
            label: 'Pemasukan',
          ),
          NavigationDestination(
            icon: Icon(Icons.arrow_upward_outlined),
            selectedIcon: Icon(Icons.arrow_upward),
            label: 'Pengeluaran',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Akun',
          ),
        ],
      ),
    );
  }
}
