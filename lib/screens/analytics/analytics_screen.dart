import 'package:flutter/material.dart';

import '../../models/models.dart';
import '../../state/analytics_calculator.dart';
import '../../state/app_store.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../utils/formatters.dart';
import '../../widgets/category_donut_chart.dart';
import '../../widgets/category_rank_list.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/glow_hero_card.dart';
import '../../widgets/period_pill_selector.dart';
import '../../widgets/section_header.dart';
import '../../widgets/status_pill.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key, required this.type});

  static const routeName = '/analytics';

  final TransactionType type;

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  FlowPeriod _period = FlowPeriod.month;
  DateTime _anchor = DateTime.now();
  String? _selectedCategoryId;

  bool get _isIncome => widget.type == TransactionType.income;

  String _periodLabel(DateTime anchor) {
    switch (_period) {
      case FlowPeriod.day:
        return formatDateShort(anchor);
      case FlowPeriod.week:
        return formatWeekRange(startOfWeek(anchor), endOfWeek(anchor));
      case FlowPeriod.month:
        return formatMonthYear(anchor);
    }
  }

  String _emptyStateLabel() {
    switch (_period) {
      case FlowPeriod.day:
        return 'pada tanggal ini';
      case FlowPeriod.week:
        return 'pada minggu ini';
      case FlowPeriod.month:
        return 'pada bulan ini';
    }
  }

  ({DateTime start, DateTime end}) _rangeFor(DateTime anchor) {
    switch (_period) {
      case FlowPeriod.day:
        final start = DateTime(anchor.year, anchor.month, anchor.day);
        return (start: start, end: start.add(const Duration(days: 1)));
      case FlowPeriod.week:
        final start = startOfWeek(anchor);
        return (start: start, end: start.add(const Duration(days: 7)));
      case FlowPeriod.month:
        final start = DateTime(anchor.year, anchor.month, 1);
        return (start: start, end: DateTime(anchor.year, anchor.month + 1, 1));
    }
  }

  DateTime _previousAnchor(DateTime anchor) {
    switch (_period) {
      case FlowPeriod.day:
        return anchor.subtract(const Duration(days: 1));
      case FlowPeriod.week:
        return anchor.subtract(const Duration(days: 7));
      case FlowPeriod.month:
        return DateTime(anchor.year, anchor.month - 1, 1);
    }
  }

  void _shiftPeriod(int direction) {
    setState(() {
      switch (_period) {
        case FlowPeriod.day:
          _anchor = _anchor.add(Duration(days: direction));
        case FlowPeriod.week:
          _anchor = _anchor.add(Duration(days: 7 * direction));
        case FlowPeriod.month:
          _anchor = DateTime(_anchor.year, _anchor.month + direction, 1);
      }
    });
  }

  Future<void> _pickAnchor() async {
    final helpText = switch (_period) {
      FlowPeriod.day => 'Pilih tanggal',
      FlowPeriod.week => 'Pilih minggu',
      FlowPeriod.month => 'Pilih bulan',
    };
    final picked = await showDatePicker(
      context: context,
      initialDate: _anchor,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      helpText: helpText,
      fieldLabelText: helpText,
    );
    if (picked == null || !mounted) return;
    setState(() {
      switch (_period) {
        case FlowPeriod.day:
          _anchor = picked;
        case FlowPeriod.week:
          _anchor = startOfWeek(picked);
        case FlowPeriod.month:
          _anchor = DateTime(picked.year, picked.month, 1);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: appStore,
      builder: (context, _) {
        final textTheme = Theme.of(context).textTheme;
        final isIncome = _isIncome;
        final color = isIncome ? AppColors.income : AppColors.expense;
        final totalLabel = isIncome ? 'Total Pemasukan' : 'Total Pengeluaran';
        final range = _rangeFor(_anchor);
        final txs = AnalyticsCalculator.transactionsInRange(
          appStore.transactions,
          widget.type,
          range.start,
          range.end,
        );
        final total = AnalyticsCalculator.totalAmount(txs);
        final segments = AnalyticsCalculator.byCategory(
          txs,
          appStore.categoryById,
          topN: 5,
        );

        final prevRange = _rangeFor(_previousAnchor(_anchor));
        final prevTxs = AnalyticsCalculator.transactionsInRange(
          appStore.transactions,
          widget.type,
          prevRange.start,
          prevRange.end,
        );
        final trendPct = AnalyticsCalculator.percentChange(
          total,
          AnalyticsCalculator.totalAmount(prevTxs),
        );
        final trendUp = trendPct != null && trendPct >= 0;
        final trendGood = trendPct == null
            ? true
            : (isIncome ? trendUp : !trendUp);

        return Scaffold(
          appBar: AppBar(
            title: Text(isIncome ? 'Analitik Pemasukan' : 'Analitik Pengeluaran'),
          ),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.md,
              AppSpacing.md,
              AppSpacing.xl,
            ),
            children: [
              PeriodPillSelector<FlowPeriod>(
                options: const [
                  PeriodPillOption(value: FlowPeriod.day, label: 'Harian'),
                  PeriodPillOption(value: FlowPeriod.week, label: 'Mingguan'),
                  PeriodPillOption(value: FlowPeriod.month, label: 'Bulanan'),
                ],
                selected: _period,
                onChanged: (p) => setState(() => _period = p),
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
                          onPressed: () => _shiftPeriod(-1),
                          icon: const Icon(Icons.chevron_left),
                        ),
                        Expanded(
                          child: Center(
                            child: Text(
                              _periodLabel(_anchor),
                              style: textTheme.labelLarge,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: () => _shiftPeriod(1),
                          icon: const Icon(Icons.chevron_right),
                        ),
                      ],
                    ),
                    GestureDetector(
                      onTap: _pickAnchor,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.sm,
                        ),
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
                    Text(totalLabel, style: textTheme.bodyMedium),
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
                            label: '${trendPct.abs().toStringAsFixed(0)}%',
                            color: trendGood
                                ? AppColors.income
                                : AppColors.error,
                            icon: trendUp
                                ? Icons.trending_up
                                : Icons.trending_down,
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      '${txs.length} transaksi tercatat',
                      style: textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              const SectionHeader(title: 'Berdasarkan Kategori'),
              const SizedBox(height: AppSpacing.md),
              if (total == 0)
                EmptyState(
                  icon: isIncome ? Icons.south_west : Icons.north_east,
                  title:
                      'Belum ada ${isIncome ? 'pemasukan' : 'pengeluaran'} ${_emptyStateLabel()}',
                )
              else ...[
                Center(
                  child: CategoryDonutChart(
                    segments: segments,
                    total: total,
                    centerLabel: totalLabel,
                    selectedCategoryId: _selectedCategoryId,
                    onSegmentTap: (id) =>
                        setState(() => _selectedCategoryId = id),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                CategoryRankList(
                  segments: segments,
                  selectedCategoryId: _selectedCategoryId,
                  onCategoryTap: (id) =>
                      setState(() => _selectedCategoryId = id),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}
