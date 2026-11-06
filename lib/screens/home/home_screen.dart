import 'package:flutter/material.dart';

import '../../models/models.dart';
import '../../state/app_store.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../utils/csv_export_action.dart';
import '../../utils/formatters.dart';
import '../../widgets/balance_visibility_toggle.dart';
import '../../widgets/bordered_list_card.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/glow_hero_card.dart';
import '../../widgets/section_header.dart';
import '../../widgets/transaction_tile.dart';
import '../category/categories_screen.dart';
import '../ledger/invite_member_screen.dart';
import '../savings/add_contribution_screen.dart';
import '../savings/add_edit_savings_goal_screen.dart';
import '../transaction/add_edit_transaction_screen.dart';
import '../transaction/transaction_detail_screen.dart';
import '../../widgets/savings_progress_bar.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _balanceHidden = false;
  bool _csvExportLoading = false;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: appStore,
      builder: (context, _) {
        final ledger = appStore.currentLedger;
        final user = appStore.currentUser;

        final priorityGoal = _priorityGoal();
        final recentTransactions = [...appStore.transactions]
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
        final recent = recentTransactions.take(5).toList();

        return Scaffold(
          appBar: AppBar(
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  ledger?.name ?? 'SiMoney',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                Text(
                  '${ledger?.memberIds.length ?? 0} anggota',
                  style: Theme.of(context).textTheme.bodySmall,
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
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                AppSpacing.md,
                AppSpacing.md,
                AppSpacing.xl,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _BalanceHeroSection(
                    userName: user?.name ?? 'Pengguna',
                    balance: appStore.balance,
                    allTimeBalance: appStore.allTimeBalance,
                    totalIncome: appStore.totalIncome,
                    totalExpense: appStore.totalExpense,
                    balanceHidden: _balanceHidden,
                    onToggleBalance: () =>
                        setState(() => _balanceHidden = !_balanceHidden),
                    csvExportLoading: _csvExportLoading,
                    onAddTransaction: () => Navigator.of(context)
                        .pushNamed(AddEditTransactionScreen.routeName),
                    onAddSavingsGoal: () => Navigator.of(context)
                        .pushNamed(AddEditSavingsGoalScreen.routeName),
                    onExportCsv: () => exportTransactionsCsv(
                      context,
                      setLoading: (loading) {
                        if (mounted) {
                          setState(() => _csvExportLoading = loading);
                        }
                      },
                    ),
                    onOpenCategories: () => Navigator.of(context)
                        .pushNamed(CategoriesScreen.routeName),
                  ),
                  if (priorityGoal != null) ...[
                    const SizedBox(height: AppSpacing.lg),
                    const SectionHeader(title: 'Target Prioritas'),
                    const SizedBox(height: AppSpacing.sm),
                    _PriorityGoalCard(goal: priorityGoal),
                  ],
                  const SizedBox(height: AppSpacing.lg),
                  _RecentTransactionsSection(
                    recent: recent,
                    onTapTransaction: (tx) => Navigator.of(context).pushNamed(
                      TransactionDetailScreen.routeName,
                      arguments: tx.id,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  SavingsGoal? _priorityGoal() {
    final active = appStore.savingsGoals
        .where((g) => g.status == SavingsGoalStatus.active)
        .toList()
      ..sort((a, b) {
        final ad = a.targetDate;
        final bd = b.targetDate;
        if (ad == null && bd == null) return 0;
        if (ad == null) return 1;
        if (bd == null) return -1;
        return ad.compareTo(bd);
      });
    return active.isEmpty ? null : active.first;
  }
}

class _BalanceHeroSection extends StatelessWidget {
  const _BalanceHeroSection({
    required this.userName,
    required this.balance,
    required this.allTimeBalance,
    required this.totalIncome,
    required this.totalExpense,
    required this.balanceHidden,
    required this.onToggleBalance,
    required this.csvExportLoading,
    required this.onAddTransaction,
    required this.onAddSavingsGoal,
    required this.onExportCsv,
    required this.onOpenCategories,
  });

  final String userName;
  final int balance;
  final int allTimeBalance;
  final int totalIncome;
  final int totalExpense;
  final bool balanceHidden;
  final VoidCallback onToggleBalance;
  final bool csvExportLoading;
  final VoidCallback onAddTransaction;
  final VoidCallback onAddSavingsGoal;
  final VoidCallback onExportCsv;
  final VoidCallback onOpenCategories;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return GlowHeroCard(
      glowColor: AppColors.primary,
      secondaryGlowColor: AppColors.secondary,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'Halo, $userName 👋',
                  style: textTheme.headlineMedium,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              BalanceVisibilityToggle(
                hidden: balanceHidden,
                color: AppColors.onSurfaceVariant,
                onToggle: onToggleBalance,
              ),
            ],
          ),
          Text('Saldo kas bulan ini', style: textTheme.bodySmall),
          const SizedBox(height: AppSpacing.xs),
          MaskedAmountText(
            amount: balance,
            hidden: balanceHidden,
            style: textTheme.displayLarge?.copyWith(color: AppColors.primary),
          ),
          const SizedBox(height: AppSpacing.sm),
          Container(
            height: 1,
            color: AppColors.outlineVariant.withValues(alpha: 0.4),
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.account_balance_wallet_outlined,
                    size: 14,
                    color: AppColors.onSurfaceVariant,
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Text('Total saldo seluruhnya', style: textTheme.bodySmall),
                ],
              ),
              MaskedAmountText(
                amount: allTimeBalance,
                hidden: balanceHidden,
                style: textTheme.titleSmall,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: _FlowCapsule(
                  icon: Icons.south_west,
                  label: 'Pemasukan',
                  amount: totalIncome,
                  color: AppColors.income,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _FlowCapsule(
                  icon: Icons.north_east,
                  label: 'Pengeluaran',
                  amount: totalExpense,
                  color: AppColors.expense,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _QuickAction(
                icon: Icons.add,
                label: 'Catat Kas',
                emphasized: true,
                onTap: onAddTransaction,
              ),
              _QuickAction(
                icon: Icons.savings_outlined,
                label: 'Celengan',
                onTap: onAddSavingsGoal,
              ),
              _QuickAction(
                icon: Icons.ios_share,
                label: 'Laporan',
                isLoading: csvExportLoading,
                onTap: onExportCsv,
              ),
              _QuickAction(
                icon: Icons.category_outlined,
                label: 'Kategori',
                onTap: onOpenCategories,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RecentTransactionsSection extends StatelessWidget {
  const _RecentTransactionsSection({
    required this.recent,
    required this.onTapTransaction,
  });

  final List<TxRecord> recent;
  final ValueChanged<TxRecord> onTapTransaction;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(title: 'Transaksi Terkini'),
        const SizedBox(height: AppSpacing.sm),
        if (recent.isEmpty)
          EmptyState(
            title: 'Belum ada transaksi',
            titleStyle: Theme.of(context).textTheme.bodyMedium,
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
          )
        else
          BorderedListCard(
            dividerIndent: 64,
            children: [
              for (final tx in recent)
                Builder(builder: (context) {
                  final category = appStore.categoryById(tx.categoryId);
                  final author = appStore.userById(tx.createdBy) ??
                      AppUser(id: tx.createdBy, name: tx.createdByName, email: '');
                  return TransactionTile(
                    transaction: tx,
                    categoryName: tx.categoryName.isNotEmpty
                        ? tx.categoryName
                        : (category?.name ?? 'Lainnya'),
                    categoryIcon: category?.icon ?? Icons.more_horiz,
                    author: author,
                    onTap: () => onTapTransaction(tx),
                  );
                }),
            ],
          ),
      ],
    );
  }
}

class _FlowCapsule extends StatelessWidget {
  const _FlowCapsule({
    required this.icon,
    required this.label,
    required this.amount,
    required this.color,
  });

  final IconData icon;
  final String label;
  final int amount;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: AppSpacing.xs),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: textTheme.labelSmall?.copyWith(color: color)),
                Text(
                  formatRupiah(amount),
                  style: textTheme.labelLarge?.copyWith(color: color),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  const _QuickAction({
    required this.icon,
    required this.label,
    required this.onTap,
    this.emphasized = false,
    this.isLoading = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool emphasized;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return InkWell(
      onTap: isLoading ? null : onTap,
      borderRadius: BorderRadius.circular(AppRadius.full),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: emphasized
                  ? AppColors.primary
                  : AppColors.surfaceContainerHigh,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: isLoading
                  ? SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: emphasized
                            ? AppColors.onPrimary
                            : AppColors.onSurface,
                      ),
                    )
                  : Icon(
                      icon,
                      color:
                          emphasized ? AppColors.onPrimary : AppColors.onSurface,
                    ),
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(label, style: textTheme.labelSmall),
        ],
      ),
    );
  }
}

class _PriorityGoalCard extends StatelessWidget {
  const _PriorityGoalCard({required this.goal});

  final SavingsGoal goal;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final progress = appStore.goalProgress(goal.id);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainer,
        border: Border.all(color: AppColors.outlineVariant),
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  goal.name,
                  style: textTheme.labelLarge,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pushNamed(
                  AddContributionScreen.routeName,
                  arguments: AddContributionArgs(
                    goalId: goal.id,
                    type: ContributionType.deposit,
                  ),
                ),
                child: const Text('+ Setor'),
              ),
            ],
          ),
          if (goal.targetDate != null) ...[
            const SizedBox(height: 2),
            Text(
              'Target ${formatDateShort(goal.targetDate!)}',
              style: textTheme.bodySmall,
            ),
          ],
          const SizedBox(height: AppSpacing.sm),
          SavingsProgressBar(progress: progress, target: goal.targetAmount),
        ],
      ),
    );
  }
}
