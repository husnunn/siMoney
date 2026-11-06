import 'package:flutter/material.dart';

import '../../state/analytics_calculator.dart';
import '../../state/app_store.dart';
import '../../models/models.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../utils/formatters.dart';
import '../../widgets/bordered_list_card.dart';
import '../../widgets/category_tag.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/glow_hero_card.dart';
import '../../widgets/period_pill_selector.dart';
import '../../widgets/section_header.dart';
import '../../widgets/status_pill.dart';
import '../../widgets/transaction_tile.dart';
import '../analytics/analytics_screen.dart';
import '../transaction/add_edit_transaction_screen.dart';
import '../transaction/transaction_detail_screen.dart';

class IncomeExpenseScreen extends StatelessWidget {
  const IncomeExpenseScreen({super.key, required this.type});

  final TransactionType type;

  bool get _isIncome => type == TransactionType.income;

  String _periodLabel(FlowPeriod period, DateTime anchor) {
    switch (period) {
      case FlowPeriod.day:
        return formatDateShort(anchor);
      case FlowPeriod.week:
        return formatWeekRange(startOfWeek(anchor), endOfWeek(anchor));
      case FlowPeriod.month:
        return formatMonthYear(anchor);
    }
  }

  String _emptyStateLabel(FlowPeriod period) {
    switch (period) {
      case FlowPeriod.day:
        return 'pada tanggal ini';
      case FlowPeriod.week:
        return 'pada minggu ini';
      case FlowPeriod.month:
        return 'pada bulan ini';
    }
  }

  DateTime _previousAnchor(FlowPeriod period, DateTime anchor) {
    switch (period) {
      case FlowPeriod.day:
        return anchor.subtract(const Duration(days: 1));
      case FlowPeriod.week:
        return anchor.subtract(const Duration(days: 7));
      case FlowPeriod.month:
        return DateTime(anchor.year, anchor.month - 1, 1);
    }
  }

  List<TxRecord> _txForPeriod(FlowPeriod period, DateTime anchor) {
    switch (period) {
      case FlowPeriod.day:
        return appStore.transactions
            .where((t) =>
                t.type == type &&
                t.createdAt.year == anchor.year &&
                t.createdAt.month == anchor.month &&
                t.createdAt.day == anchor.day)
            .toList();
      case FlowPeriod.week:
        final start = startOfWeek(anchor);
        final end = start.add(const Duration(days: 7));
        return appStore.transactions
            .where((t) =>
                t.type == type &&
                !t.createdAt.isBefore(start) &&
                t.createdAt.isBefore(end))
            .toList();
      case FlowPeriod.month:
        return appStore.transactions
            .where((t) =>
                t.type == type &&
                t.createdAt.year == anchor.year &&
                t.createdAt.month == anchor.month)
            .toList();
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: appStore,
      builder: (context, _) {
        final color = _isIncome ? AppColors.income : AppColors.expense;
        final title = _isIncome ? 'Pemasukan' : 'Pengeluaran';
        final period = appStore.selectedFlowPeriod;
        final anchor = appStore.selectedFlowAnchor;
        final txs = appStore.transactionsForFlowPeriod(type);
        final total = AnalyticsCalculator.totalAmount(txs);

        final prevTotal = AnalyticsCalculator.totalAmount(
          _txForPeriod(period, _previousAnchor(period, anchor)),
        );
        final trendPct = AnalyticsCalculator.percentChange(total, prevTotal);
        final trendUp = trendPct != null && trendPct >= 0;
        final trendGood = trendPct == null
            ? true
            : (_isIncome ? trendUp : !trendUp);

        return Scaffold(
          appBar: AppBar(
            title: Text(title),
            actions: [
              if (!_isIncome)
                IconButton(
                  onPressed: () => Navigator.of(context)
                      .pushNamed(AnalyticsScreen.routeName),
                  icon: const Icon(Icons.bar_chart_outlined),
                  tooltip: 'Analitik Pengeluaran',
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
          body: ListView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.md,
              AppSpacing.md,
              88,
            ),
            children: [
              _FlowSummarySection(
                period: period,
                anchor: anchor,
                periodLabel: _periodLabel(period, anchor),
                title: title,
                total: total,
                color: color,
                txCount: txs.length,
                trendPct: trendPct,
                trendGood: trendGood,
                trendUp: trendUp,
                onPeriodChanged: appStore.setFlowPeriod,
                onShiftPeriod: appStore.shiftFlowPeriod,
                onPickAnchor: () => _pickAnchor(context),
              ),
              const SizedBox(height: AppSpacing.lg),
              _FlowHistorySection(
                txs: txs,
                isIncome: _isIncome,
                emptyStateLabel: _emptyStateLabel(period),
                onTapTransaction: (tx) => Navigator.of(context).pushNamed(
                  TransactionDetailScreen.routeName,
                  arguments: tx.id,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _pickAnchor(BuildContext context) async {
    final period = appStore.selectedFlowPeriod;
    final current = appStore.selectedFlowAnchor;
    final helpText = switch (period) {
      FlowPeriod.day => 'Pilih tanggal',
      FlowPeriod.week => 'Pilih minggu',
      FlowPeriod.month => 'Pilih bulan',
    };
    final picked = await showDatePicker(
      context: context,
      initialDate: current,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      helpText: helpText,
      fieldLabelText: helpText,
    );
    if (picked == null) return;
    switch (period) {
      case FlowPeriod.day:
        appStore.setSelectedFlowAnchor(picked);
      case FlowPeriod.week:
        appStore.setSelectedFlowAnchor(startOfWeek(picked));
      case FlowPeriod.month:
        appStore.setSelectedFlowAnchor(DateTime(picked.year, picked.month, 1));
    }
  }
}

class _FlowSummarySection extends StatelessWidget {
  const _FlowSummarySection({
    required this.period,
    required this.anchor,
    required this.periodLabel,
    required this.title,
    required this.total,
    required this.color,
    required this.txCount,
    required this.trendPct,
    required this.trendGood,
    required this.trendUp,
    required this.onPeriodChanged,
    required this.onShiftPeriod,
    required this.onPickAnchor,
  });

  final FlowPeriod period;
  final DateTime anchor;
  final String periodLabel;
  final String title;
  final int total;
  final Color color;
  final int txCount;
  final double? trendPct;
  final bool trendGood;
  final bool trendUp;
  final ValueChanged<FlowPeriod> onPeriodChanged;
  final void Function(int direction) onShiftPeriod;
  final VoidCallback onPickAnchor;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        PeriodPillSelector<FlowPeriod>(
          options: const [
            PeriodPillOption(value: FlowPeriod.day, label: 'Harian'),
            PeriodPillOption(value: FlowPeriod.week, label: 'Mingguan'),
            PeriodPillOption(value: FlowPeriod.month, label: 'Bulanan'),
          ],
          selected: period,
          onChanged: onPeriodChanged,
        ),
        const SizedBox(height: AppSpacing.md),
        GlowHeroCard(
          glowColor: color,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    onPressed: () => onShiftPeriod(-1),
                    icon: const Icon(Icons.chevron_left),
                  ),
                  Expanded(
                    child: Center(
                      child: Text(periodLabel, style: textTheme.labelLarge),
                    ),
                  ),
                  IconButton(
                    onPressed: () => onShiftPeriod(1),
                    icon: const Icon(Icons.chevron_right),
                  ),
                ],
              ),
              GestureDetector(
                onTap: onPickAnchor,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.calendar_today_outlined, size: 14),
                      const SizedBox(width: AppSpacing.xs),
                      Text('Ubah periode', style: textTheme.bodySmall),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Text('Total $title', style: textTheme.bodyMedium),
              const SizedBox(height: AppSpacing.xs),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    formatRupiah(total),
                    style: textTheme.displayLarge?.copyWith(color: color),
                  ),
                  if (trendPct != null) ...[
                    const SizedBox(width: AppSpacing.sm),
                    StatusPill(
                      label: '${trendPct!.abs().toStringAsFixed(0)}%',
                      color: trendGood ? AppColors.income : AppColors.error,
                      icon: trendUp ? Icons.trending_up : Icons.trending_down,
                    ),
                  ],
                ],
              ),
              const SizedBox(height: AppSpacing.xs),
              Text('$txCount transaksi tercatat', style: textTheme.bodySmall),
            ],
          ),
        ),
      ],
    );
  }
}

class _FlowHistorySection extends StatelessWidget {
  const _FlowHistorySection({
    required this.txs,
    required this.isIncome,
    required this.emptyStateLabel,
    required this.onTapTransaction,
  });

  final List<TxRecord> txs;
  final bool isIncome;
  final String emptyStateLabel;
  final ValueChanged<TxRecord> onTapTransaction;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(title: 'Riwayat'),
        const SizedBox(height: AppSpacing.sm),
        if (txs.isEmpty)
          EmptyState(
            icon: isIncome ? Icons.south_west : Icons.north_east,
            title:
                'Belum ada ${isIncome ? 'pemasukan' : 'pengeluaran'} $emptyStateLabel',
          )
        else
          BorderedListCard(
            dividerIndent: 64,
            children: [
              for (final tx in txs)
                Builder(builder: (context) {
                  final category = appStore.categoryById(tx.categoryId);
                  final author = appStore.userById(tx.createdBy) ??
                      AppUser(id: tx.createdBy, name: tx.createdByName, email: '');
                  final categoryName = tx.categoryName.isNotEmpty
                      ? tx.categoryName
                      : (category?.name ?? 'Lainnya');
                  return TransactionTile(
                    transaction: tx,
                    categoryName: categoryName,
                    categoryIcon: category?.icon ?? Icons.more_horiz,
                    author: author,
                    tag: CategoryTag(categoryId: tx.categoryId, label: categoryName),
                    onTap: () => onTapTransaction(tx),
                  );
                }),
            ],
          ),
      ],
    );
  }
}
