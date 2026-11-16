import 'package:flutter/material.dart';

import '../../../state/savings_planner.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_spacing.dart';
import '../../../utils/formatters.dart';
import '../../../widgets/info_banner.dart';
import 'period_figures_grid.dart';

/// Live preview card on the goal form: updates while the user types.
class _PreviewCard extends StatelessWidget {
  const _PreviewCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainer,
        border: Border.all(color: AppColors.outlineVariant),
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Pratinjau hitungan', style: textTheme.titleMedium),
          const SizedBox(height: AppSpacing.sm),
          child,
        ],
      ),
    );
  }
}

/// Shown while the form is not complete enough to calculate anything.
class PlanPreviewHint extends StatelessWidget {
  const PlanPreviewHint({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return _PreviewCard(
      child: Text(message, style: Theme.of(context).textTheme.bodyMedium),
    );
  }
}

/// Preview for a Target Akhir goal being created or edited.
class FinalPlanPreview extends StatelessWidget {
  const FinalPlanPreview({super.key, required this.plan});

  final FinalGoalPlan plan;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    if (plan.isReached) {
      return const _PreviewCard(
        child: InfoBanner(
          message: 'Saldo saat ini sudah menutup target ini.',
          color: AppColors.income,
          icon: Icons.check_circle_outline,
        ),
      );
    }
    if (plan.isOverdue) {
      return const _PreviewCard(
        child: InfoBanner(
          message: 'Tenggat sudah lewat. Pilih tanggal yang akan datang.',
          color: AppColors.error,
          icon: Icons.event_busy_outlined,
        ),
      );
    }

    return _PreviewCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Sampai ${formatDateShort(plan.deadline)} '
            '(${formatTimeLeft(plan.daysLeft)}), kamu perlu menabung:',
            style: textTheme.bodyMedium,
          ),
          const SizedBox(height: AppSpacing.gutter),
          PeriodFiguresGrid(figures: plan.required),
          const SizedBox(height: AppSpacing.gutter),
          Text(
            plan.adjustForInflation
                ? 'Target pada ${formatDateShort(plan.deadline)}: '
                    '${formatRupiahAuto(plan.adjustedTarget)} '
                    '(naik ${formatRupiahAuto(plan.inflationExtra)} karena inflasi '
                    '${formatPercent(plan.inflationRate)} per tahun).'
                : 'Target ${formatRupiahAuto(plan.adjustedTarget)}, nominal tetap '
                    'tanpa penyesuaian inflasi.',
            style: textTheme.bodySmall,
          ),
          if (plan.adjustForInflation) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Inflasi menambah setoran '
              '${formatRupiahAuto(plan.inflationExtraPerMonth)}/bln '
              '(+${formatPercent(plan.inflationExtraPercent)}) dibanding tanpa inflasi.',
              style: textTheme.bodySmall,
            ),
          ],
        ],
      ),
    );
  }
}

/// Preview for a Target Berkala goal being created or edited.
class PeriodicPlanPreview extends StatelessWidget {
  const PeriodicPlanPreview({super.key, required this.plan});

  final PeriodicPlan plan;

  static const _labels = {'1 tahun', '5 tahun', '10 tahun'};

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final shown = [
      for (final p in plan.projections)
        if (_labels.contains(p.horizon.label)) p,
    ];

    return _PreviewCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${formatRupiah(plan.amount)} ${plan.unit.perLabel} sama dengan:',
            style: textTheme.bodyMedium,
          ),
          const SizedBox(height: AppSpacing.gutter),
          PeriodFiguresGrid(figures: plan.figures, highlight: plan.unit),
          const SizedBox(height: AppSpacing.gutter),
          Text('Kalau konsisten tanpa tenggat:', style: textTheme.labelLarge),
          const SizedBox(height: AppSpacing.sm),
          for (final p in shown)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.xs),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Dalam ${p.horizon.label}',
                      style: textTheme.bodyMedium,
                    ),
                  ),
                  Text(
                    formatRupiahCompact(p.nominal),
                    style: textTheme.labelLarge?.copyWith(
                      color: AppColors.primary,
                    ),
                  ),
                  if (plan.hasInflation)
                    Text(
                      '  (≈ ${formatRupiahCompact(p.realValue)} hari ini)',
                      style: textTheme.bodySmall,
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
