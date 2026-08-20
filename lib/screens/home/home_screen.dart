import 'package:flutter/material.dart';

import '../../state/app_store.dart';
import '../../models/models.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../utils/formatters.dart';
import '../../widgets/balance_summary.dart';
import '../../widgets/transaction_tile.dart';
import '../ledger/invite_member_screen.dart';
import '../transaction/add_edit_transaction_screen.dart';
import '../transaction/transaction_detail_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: appStore,
      builder: (context, _) {
        final ledger = appStore.currentLedger;
        final txs = appStore.filteredTransactions;
        final textTheme = Theme.of(context).textTheme;

        return Scaffold(
          appBar: AppBar(
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  ledger?.name ?? 'SiMoney',
                  style: textTheme.titleLarge,
                ),
                Text(
                  '${ledger?.memberIds.length ?? 0} anggota',
                  style: textTheme.bodySmall,
                ),
              ],
            ),
            actions: [
              IconButton(
                tooltip: 'Undang anggota',
                onPressed: () {
                  Navigator.of(context).pushNamed(InviteMemberScreen.routeName);
                },
                icon: const Icon(Icons.person_add_outlined),
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton(
            heroTag: 'fab_home',
            onPressed: () {
              Navigator.of(context).pushNamed(
                AddEditTransactionScreen.routeName,
              );
            },
            tooltip: 'Tambah transaksi',
            child: const Icon(Icons.add),
          ),
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: ActionChip(
                    avatar: const Icon(Icons.calendar_today_outlined, size: 16),
                    label: Text(formatMonthYear(appStore.selectedMonth)),
                    onPressed: () => _pickMonth(context),
                    backgroundColor: AppColors.mutedSurface,
                    side: BorderSide.none,
                  ),
                ),
              ),
              BalanceSummary(
                balance: appStore.balance,
                income: appStore.totalIncome,
                expense: appStore.totalExpense,
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                child: Text(
                  'Transaksi',
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              const Divider(),
              Expanded(
                child: txs.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(AppSpacing.xl),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.receipt_long_outlined,
                                size: 48,
                                color: AppColors.muted.withValues(alpha: 0.5),
                              ),
                              const SizedBox(height: AppSpacing.md),
                              Text(
                                'Belum ada transaksi bulan ini',
                                style: textTheme.bodyLarge?.copyWith(
                                  color: AppColors.muted,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: AppSpacing.sm),
                              Text(
                                'Ketuk + untuk menambah pencatatan.',
                                style: textTheme.bodySmall,
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.only(bottom: 88),
                        itemCount: txs.length,
                        separatorBuilder: (_, _) => const Divider(indent: 72),
                        itemBuilder: (context, index) {
                          final tx = txs[index];
                          final category =
                              appStore.categoryById(tx.categoryId);
                          final author = appStore.userById(tx.createdBy) ??
                              AppUser(
                                id: tx.createdBy,
                                name: tx.createdByName,
                                email: '',
                              );
                          return TransactionTile(
                            transaction: tx,
                            categoryName: tx.categoryName.isNotEmpty
                                ? tx.categoryName
                                : (category?.name ?? 'Lainnya'),
                            categoryIcon:
                                category?.icon ?? Icons.more_horiz,
                            author: author,
                            onTap: () {
                              Navigator.of(context).pushNamed(
                                TransactionDetailScreen.routeName,
                                arguments: tx.id,
                              );
                            },
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _pickMonth(BuildContext context) async {
    final current = appStore.selectedMonth;
    final picked = await showDatePicker(
      context: context,
      initialDate: current,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      helpText: 'Pilih bulan',
      fieldLabelText: 'Bulan',
    );
    if (picked != null) {
      appStore.setSelectedMonth(picked);
    }
  }
}
