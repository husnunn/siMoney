import 'package:flutter/material.dart';

import '../../state/app_store.dart';
import '../../models/models.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../utils/formatters.dart';
import '../../widgets/transaction_tile.dart';
import '../transaction/add_edit_transaction_screen.dart';
import '../transaction/transaction_detail_screen.dart';

class IncomeExpenseScreen extends StatelessWidget {
  const IncomeExpenseScreen({super.key, required this.type});

  final TransactionType type;

  bool get _isIncome => type == TransactionType.income;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: appStore,
      builder: (context, _) {
        final textTheme = Theme.of(context).textTheme;
        final color = _isIncome ? AppColors.income : AppColors.expense;
        final title = _isIncome ? 'Pemasukan' : 'Pengeluaran';
        final txs = appStore.transactionsForFlowDate(type);
        final total = txs.fold(0, (sum, t) => sum + t.amount);

        return Scaffold(
          appBar: AppBar(
            title: Text(title),
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: AppSpacing.sm),
                child: Center(
                  child: ActionChip(
                    avatar: const Icon(Icons.calendar_today_outlined, size: 16),
                    label: Text(formatDateShort(appStore.selectedFlowDate)),
                    onPressed: () => _pickDate(context),
                    backgroundColor: AppColors.mutedSurface,
                    side: BorderSide.none,
                  ),
                ),
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton(
            heroTag: _isIncome ? 'fab_income' : 'fab_expense',
            onPressed: () {
              Navigator.of(context).pushNamed(
                AddEditTransactionScreen.routeName,
                arguments: type,
              );
            },
            tooltip: 'Tambah ${_isIncome ? 'pemasukan' : 'pengeluaran'}',
            child: const Icon(Icons.add),
          ),
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.md,
                  AppSpacing.lg,
                  AppSpacing.lg,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Total $title',
                      style: textTheme.bodyMedium?.copyWith(
                        color: AppColors.muted,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      formatRupiah(total),
                      style: textTheme.displayLarge?.copyWith(
                        fontSize: 36,
                        fontWeight: FontWeight.w600,
                        letterSpacing: -0.8,
                        color: color,
                        height: 1.1,
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                child: Text(
                  'Riwayat',
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
                                _isIncome
                                    ? Icons.south_west
                                    : Icons.north_east,
                                size: 48,
                                color: AppColors.muted.withValues(alpha: 0.5),
                              ),
                              const SizedBox(height: AppSpacing.md),
                              Text(
                                'Belum ada ${_isIncome ? 'pemasukan' : 'pengeluaran'} pada tanggal ini',
                                style: textTheme.bodyLarge?.copyWith(
                                  color: AppColors.muted,
                                ),
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

  Future<void> _pickDate(BuildContext context) async {
    final current = appStore.selectedFlowDate;
    final picked = await showDatePicker(
      context: context,
      initialDate: current,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      helpText: 'Pilih tanggal',
      fieldLabelText: 'Tanggal',
    );
    if (picked != null) {
      appStore.setSelectedFlowDate(picked);
    }
  }
}
