import 'package:flutter/material.dart';

import '../../../state/savings_planner.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_spacing.dart';
import '../../../utils/formatters.dart';
import '../../../widgets/bordered_list_card.dart';
import '../../../widgets/info_banner.dart';
import '../../../widgets/ledger_row.dart';
import '../../../widgets/section_header.dart';
import 'period_figures_grid.dart';

/// "Rencana Setoran" of a Target Akhir goal: how much to save per day, week,
/// month and year to reach the target by its deadline, how inflation changes
/// that, whether the recent pace is enough, and the arithmetic behind it.
class FinalPlanSection extends StatelessWidget {
  const FinalPlanSection({
    super.key,
    required this.plan,
    required this.recentPace,
    required this.paceLabel,
  });

  final FinalGoalPlan plan;

  /// Average net saving per month over the recent window.
  final double recentPace;

  /// Describes the window, e.g. "3 bulan terakhir".
  final String paceLabel;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(title: 'Rencana Setoran'),
        const SizedBox(height: AppSpacing.sm),
        if (plan.isReached)
          const InfoBanner(
            message: 'Saldo sudah menutup target. Selamat!',
            color: AppColors.income,
            icon: Icons.check_circle_outline,
          )
        else if (plan.isOverdue)
          InfoBanner(
            message: 'Tenggat sudah lewat dan masih kurang '
                '${formatRupiahAuto(plan.remaining)}. Perpanjang tenggat lewat '
                'menu Edit untuk menghitung ulang setoran.',
            color: AppColors.error,
            icon: Icons.event_busy_outlined,
          )
        else ...[
          Text(
            'Sampai ${formatDateShort(plan.deadline)} '
            '(${formatTimeLeft(plan.daysLeft)}), kamu perlu menabung:',
            style: textTheme.bodyMedium,
          ),
          const SizedBox(height: AppSpacing.gutter),
          PeriodFiguresGrid(figures: plan.required),
          const SizedBox(height: AppSpacing.gutter),
          _PaceBanner(plan: plan, pace: recentPace, paceLabel: paceLabel),
          if (plan.adjustForInflation) ...[
            const SizedBox(height: AppSpacing.sm),
            InfoBanner(
              message: 'Inflasi menambah setoran '
                  '${formatRupiahAuto(plan.inflationExtraPerMonth)}/bln '
                  '(+${formatPercent(plan.inflationExtraPercent)}) dibanding '
                  'target tanpa inflasi '
                  '(${formatRupiahAuto(plan.requiredWithoutInflation.perMonth)}/bln).',
              color: AppColors.onSurfaceVariant,
              icon: Icons.trending_up,
            ),
          ],
        ],
        const SizedBox(height: AppSpacing.md),
        _Breakdown(plan: plan),
      ],
    );
  }
}

class _PaceBanner extends StatelessWidget {
  const _PaceBanner({
    required this.plan,
    required this.pace,
    required this.paceLabel,
  });

  final FinalGoalPlan plan;
  final double pace;
  final String paceLabel;

  @override
  Widget build(BuildContext context) {
    final gap = plan.monthlyGap(pace);

    if (pace <= 0) {
      return InfoBanner(
        message: 'Belum ada setoran dalam $paceLabel. Mulai dengan '
            '${formatRupiahAuto(plan.required.perMonth)} per bulan.',
        color: AppColors.primary,
        icon: Icons.info_outline,
      );
    }
    if (gap <= 0) {
      return InfoBanner(
        message: 'Rata-rata setoranmu $paceLabel '
            '${formatRupiahAuto(pace)}/bln sudah cukup untuk tenggat ini.',
        color: AppColors.income,
        icon: Icons.check_circle_outline,
      );
    }
    return InfoBanner(
      message: 'Rata-rata setoranmu $paceLabel ${formatRupiahAuto(pace)}/bln '
          'kurang ${formatRupiahAuto(gap)}/bln dari kebutuhan.',
      color: AppColors.primary,
      icon: Icons.trending_up,
    );
  }
}

class _Breakdown extends StatelessWidget {
  const _Breakdown({required this.plan});

  final FinalGoalPlan plan;

  @override
  Widget build(BuildContext context) {
    final saving = plan.monthsLeft > 0
        ? plan.remaining / plan.monthsLeft - plan.required.perMonth
        : 0.0;
    final real = plan.realReturn;

    return BorderedListCard(
      children: [
        LedgerRow(
          label: 'Harga target (per ${formatDateShort(plan.priceDate)})',
          value: formatRupiah(plan.targetAmount),
        ),
        if (plan.adjustForInflation)
          LedgerRow(
            label: 'Kenaikan harga ${formatPercent(plan.inflationRate)}/th',
            value: '+${formatRupiahAuto(plan.inflationExtra)}',
            valueColor: AppColors.primary,
          ),
        LedgerRow(
          label: plan.adjustForInflation
              ? 'Target pada ${formatDateShort(plan.deadline)}'
              : 'Target',
          value: formatRupiahAuto(plan.adjustedTarget),
          emphasized: true,
        ),
        LedgerRow(
          label: 'Dikurangi saldo sekarang',
          value: '−${formatRupiah(plan.saved)}',
        ),
        LedgerRow(
          label: 'Sisa yang harus dikumpulkan',
          value: formatRupiahAuto(plan.remaining),
          emphasized: true,
        ),
        if (plan.annualReturn > 0 && saving > 0)
          LedgerRow(
            label: 'Imbal hasil ${formatPercent(plan.annualReturn)}/th '
                'meringankan setoran',
            value: '≈ ${formatRupiahAuto(saving)}/bln',
            valueColor: AppColors.income,
          ),
        if (real != null && plan.annualReturn > 0)
          LedgerRow(
            label: 'Imbal hasil riil (dikurangi inflasi)',
            value: '${real >= 0 ? '+' : '−'}${formatPercent(real.abs(), digits: 2)}/th',
            valueColor: real >= 0 ? AppColors.income : AppColors.error,
          ),
      ],
    );
  }
}
