import 'package:flutter/material.dart';

import '../../../state/savings_planner.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_spacing.dart';
import '../../../utils/formatters.dart';
import '../../../widgets/bordered_list_card.dart';
import '../../../widgets/section_header.dart';
import 'period_figures_grid.dart';

/// What a periodic goal adds up to: the same amount per day / week / month /
/// year, and where the habit leads after one month, a year, ten years.
class PeriodicPlanSection extends StatelessWidget {
  const PeriodicPlanSection({super.key, required this.plan});

  final PeriodicPlan plan;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    final notes = <String>[
      'Proyeksi bila kamu konsisten menabung ${formatRupiah(plan.amount)} '
          '${plan.unit.perLabel}.',
      if (plan.annualReturn > 0)
        'Termasuk imbal hasil ${formatPercent(plan.annualReturn)} per tahun.',
      if (plan.hasInflation)
        'Nilai daya beli memakai inflasi ${formatPercent(plan.inflationRate!)} '
            'per tahun.',
      '1 tahun dihitung 365 hari.',
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(title: 'Setara Dengan'),
        const SizedBox(height: AppSpacing.xs),
        Text(
          '${formatRupiah(plan.amount)} ${plan.unit.perLabel} sama dengan:',
          style: textTheme.bodyMedium,
        ),
        const SizedBox(height: AppSpacing.gutter),
        PeriodFiguresGrid(figures: plan.figures, highlight: plan.unit),
        const SizedBox(height: AppSpacing.lg),
        const SectionHeader(title: 'Proyeksi Tabungan'),
        const SizedBox(height: AppSpacing.xs),
        Text(notes.join(' '), style: textTheme.bodySmall),
        const SizedBox(height: AppSpacing.sm),
        BorderedListCard(
          children: [
            for (final p in plan.projections)
              _ProjectionTile(projection: p, plan: plan),
          ],
        ),
      ],
    );
  }
}

class _ProjectionTile extends StatelessWidget {
  const _ProjectionTile({required this.projection, required this.plan});

  final PeriodicProjection projection;
  final PeriodicPlan plan;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final interest = projection.nominal - projection.contributed;

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Dalam ${projection.horizon.label}',
                style: textTheme.labelLarge,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerRight,
                  child: Text(
                    formatRupiahAuto(projection.nominal),
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
            plan.annualReturn > 0
                ? 'Setoran ${formatRupiahCompact(projection.contributed)} + '
                    'imbal hasil ${formatRupiahCompact(interest)}'
                : 'Total setoran ${formatRupiahCompact(projection.contributed)}',
            style: textTheme.bodySmall,
          ),
          if (plan.hasInflation) ...[
            const SizedBox(height: AppSpacing.xxs),
            Text(
              'Setara ${formatRupiahCompact(projection.realValue)} dalam '
              'daya beli hari ini',
              style: textTheme.bodySmall?.copyWith(
                color: AppColors.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
