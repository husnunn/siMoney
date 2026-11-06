import 'package:flutter/material.dart';

import '../../state/app_store.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../utils/formatters.dart';
import '../../widgets/primary_button.dart';
import 'add_edit_transaction_screen.dart';

class TransactionDetailScreen extends StatelessWidget {
  const TransactionDetailScreen({super.key, required this.transactionId});

  static const routeName = '/transaction/detail';

  final String transactionId;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: appStore,
      builder: (context, _) {
        final tx = appStore.transactionById(transactionId);
        final textTheme = Theme.of(context).textTheme;

        if (tx == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Detail')),
            body: const Center(child: Text('Transaksi tidak ditemukan')),
          );
        }

        final category = appStore.categoryById(tx.categoryId);
        final authorName = tx.createdByName.isNotEmpty
            ? tx.createdByName
            : (appStore.userById(tx.createdBy)?.name ?? 'Pengguna');
        final isOwn = tx.createdBy == appStore.currentUser?.id;
        final amountColor =
            tx.isIncome ? AppColors.income : AppColors.expense;
        final sign = tx.isIncome ? '+' : '−';

        return Scaffold(
          appBar: AppBar(
            title: const Text('Detail transaksi'),
            actions: [
              if (isOwn)
                IconButton(
                  tooltip: 'Edit',
                  onPressed: () {
                    Navigator.of(context).pushNamed(
                      AddEditTransactionScreen.routeName,
                      arguments: tx.id,
                    );
                  },
                  icon: const Icon(Icons.edit_outlined),
                ),
            ],
          ),
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tx.isIncome ? 'Pemasukan' : 'Pengeluaran',
                    style: textTheme.bodyMedium,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    '$sign${formatRupiah(tx.amount)}',
                    style: textTheme.displayLarge?.copyWith(color: amountColor),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  _DetailRow(
                    label: 'Kategori',
                    value: category?.name ??
                        (tx.categoryName.isNotEmpty
                            ? tx.categoryName
                            : 'Lainnya'),
                    icon: category?.icon ?? Icons.more_horiz,
                  ),
                  _DetailRow(
                    label: 'Tanggal',
                    value: formatDateShort(tx.createdAt),
                    icon: Icons.calendar_today_outlined,
                  ),
                  _DetailRow(
                    label: 'Dicatat oleh',
                    value: authorName,
                    icon: Icons.person_outline,
                  ),
                  if (tx.note.isNotEmpty)
                    _DetailRow(
                      label: 'Catatan',
                      value: tx.note,
                      icon: Icons.notes_outlined,
                    ),
                  const Spacer(),
                  if (isOwn) ...[
                    PrimaryButton(
                      label: 'Edit transaksi',
                      onPressed: () {
                        Navigator.of(context).pushNamed(
                          AddEditTransactionScreen.routeName,
                          arguments: tx.id,
                        );
                      },
                    ),
                    const SizedBox(height: AppSpacing.md),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.error,
                          side: const BorderSide(color: AppColors.error),
                        ),
                        onPressed: () => _confirmDelete(context, tx.id),
                        child: const Text('Hapus transaksi'),
                      ),
                    ),
                  ] else
                    Text(
                      'Hanya pembuat transaksi yang dapat mengedit atau menghapus.',
                      style: textTheme.bodySmall,
                      textAlign: TextAlign.center,
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _confirmDelete(BuildContext context, String id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus transaksi?'),
        content: const Text(
          'Tindakan ini tidak dapat dibatalkan.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      await appStore.deleteTransaction(id);
      if (context.mounted) Navigator.of(context).pop();
    }
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 22, color: AppColors.outline),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: textTheme.bodySmall),
                const SizedBox(height: 2),
                Text(value, style: textTheme.titleMedium),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
