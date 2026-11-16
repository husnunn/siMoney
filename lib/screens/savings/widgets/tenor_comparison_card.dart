import 'package:flutter/material.dart';

import '../../../state/savings_planner.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_spacing.dart';
import '../../../utils/formatters.dart';
import '../../../widgets/bordered_list_card.dart';
import '../../../widgets/section_header.dart';
import '../../../widgets/status_pill.dart';

/// The same goal compared across tenors (1, 2, 3 ... years): a longer tenor
/// lowers the monthly need, but inflation adds more on top.
class TenorComparisonCard extends StatelessWidget {
  const TenorComparisonCard({super.key, required this.rows});

  final List<TenorRow> rows;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(title: 'Kalau Tenornya Berbeda'),
        const SizedBox(height: AppSpacing.xs),
        Text(
          'Target dan asumsi sama. Tenor lebih panjang meringankan setoran, '
          'tetapi inflasi menambah bebannya.',
          style: textTheme.bodySmall,
        ),
        const SizedBox(height: AppSpacing.sm),
        BorderedListCard(
          children: [for (final row in rows) _TenorTile(row: row)],
        ),
      ],
    );
  }
}

class _TenorTile extends StatelessWidget {
  const _TenorTile({required this.row});

  final TenorRow row;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final plan = row.plan;

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('${row.years} tahun', style: textTheme.labelLarge),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerRight,
                  child: Text(
                    '${formatRupiahAuto(plan.required.perMonth)}/bln',
                    style: textTheme.titleSmall?.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xxs),
          Text(
            'Tenggat ${formatDateShort(plan.deadline)} · target '
            '${formatRupiahCompact(plan.adjustedTarget)}',
            style: textTheme.bodySmall,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Per minggu ${formatRupiahAuto(plan.required.perWeek)} · '
            'per hari ${formatRupiahAuto(plan.required.perDay)}',
            style: textTheme.bodyMedium,
          ),
          if (plan.adjustForInflation) ...[
            const SizedBox(height: AppSpacing.sm),
            StatusPill(
              label: '+${formatPercent(plan.inflationExtraPercent)} inflasi '
                  '(${formatPercent(plan.inflationRate)}/th)',
              color: AppColors.primary,
              icon: Icons.trending_up,
            ),
          ],
        ],
      ),
    );
  }
}
