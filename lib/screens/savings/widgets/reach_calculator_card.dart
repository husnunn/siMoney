import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../state/savings_planner.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_spacing.dart';
import '../../../utils/formatters.dart';
import '../../../widgets/info_banner.dart';
import '../../../widgets/section_header.dart';

/// "Kapan Tercapai?": pick a monthly saving and see when a Target Akhir goal
/// is reached, compared with its deadline and with a world without inflation.
class ReachCalculatorCard extends StatefulWidget {
  const ReachCalculatorCard({super.key, required this.plan});

  final FinalGoalPlan plan;

  @override
  State<ReachCalculatorCard> createState() => _ReachCalculatorCardState();
}

class _ReachCalculatorCardState extends State<ReachCalculatorCard> {
  static const double _min = 100000;
  static const double _stepSize = 100000;

  late double _max;
  late double _contribution;

  @override
  void initState() {
    super.initState();
    final need = widget.plan.required.perMonth;
    _max = math.max(10000000, (need * 2 / 1000000).ceil() * 1000000.0);
    final rounded = (need / _stepSize).round() * _stepSize;
    _contribution = rounded.clamp(_min, _max);
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final plan = widget.plan;

    final months = FinalGoalPlan.monthsToReach(
      targetAmount: plan.currentCost.round(),
      saved: plan.saved,
      monthlyContribution: _contribution,
      adjustForInflation: plan.adjustForInflation,
      inflationRate: plan.inflationRate,
      annualReturn: plan.annualReturn,
    );
    final monthsWithoutInflation = plan.adjustForInflation
        ? FinalGoalPlan.monthsToReach(
            targetAmount: plan.targetAmount,
            saved: plan.saved,
            monthlyContribution: _contribution,
            annualReturn: plan.annualReturn,
          )
        : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(title: 'Kapan Tercapai?'),
        const SizedBox(height: AppSpacing.xs),
        Text(
          'Kalau kamu menabung sekian setiap bulan, kapan target ini tercapai?',
          style: textTheme.bodySmall,
        ),
        const SizedBox(height: AppSpacing.sm),
        Container(
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
                  Text('Setoran per bulan', style: textTheme.labelLarge),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerRight,
                      child: Text(
                        formatRupiah(_contribution.round()),
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
              Slider(
                value: _contribution,
                min: _min,
                max: _max,
                divisions: ((_max - _min) / _stepSize).round(),
                label: formatRupiahCompact(_contribution),
                onChanged: (v) => setState(() => _contribution = v),
              ),
              const SizedBox(height: AppSpacing.sm),
              _Result(plan: plan, months: months),
              if (monthsWithoutInflation != null && months != null) ...[
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Inflasi memperlambat ${months - monthsWithoutInflation} bulan. '
                  'Tanpa inflasi, target tercapai dalam '
                  '${formatDuration(monthsWithoutInflation)}.',
                  style: textTheme.bodySmall,
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _Result extends StatelessWidget {
  const _Result({required this.plan, required this.months});

  final FinalGoalPlan plan;
  final int? months;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    if (months == null) {
      return const InfoBanner(
        message: 'Dengan setoran ini target belum tercapai dalam 50 tahun. '
            'Naikkan setoran atau turunkan asumsi inflasi.',
        color: AppColors.primary,
        icon: Icons.info_outline,
      );
    }

    final date = PlanDates.addMonths(plan.today, months!);
    final diffDays = PlanDates.daysBetween(plan.deadline, date);
    final diffMonths = (diffDays.abs() / (365 / 12)).round();

    late final String verdict;
    late final Color color;
    if (diffDays > 15) {
      verdict = '${formatDuration(diffMonths)} lebih lambat dari tenggat '
          '(${formatDateShort(plan.deadline)}).';
      color = AppColors.primary;
    } else if (diffDays < -15) {
      verdict = '${formatDuration(diffMonths)} lebih cepat dari tenggat '
          '(${formatDateShort(plan.deadline)}).';
      color = AppColors.income;
    } else {
      verdict = 'Pas dengan tenggat (${formatDateShort(plan.deadline)}).';
      color = AppColors.income;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Target tercapai pada', style: textTheme.bodySmall),
        const SizedBox(height: AppSpacing.xs),
        Text(
          formatMonthYear(date),
          style: textTheme.displaySmall?.copyWith(color: AppColors.onSurface),
        ),
        Text('Dalam ${formatDuration(months!)} dari sekarang',
            style: textTheme.bodyMedium),
        const SizedBox(height: AppSpacing.gutter),
        InfoBanner(message: verdict, color: color),
      ],
    );
  }
}
