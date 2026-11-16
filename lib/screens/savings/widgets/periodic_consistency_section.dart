import 'package:flutter/material.dart';

import '../../../models/models.dart';
import '../../../state/savings_planner.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_spacing.dart';
import '../../../utils/formatters.dart';
import '../../../widgets/bordered_list_card.dart';
import '../../../widgets/info_banner.dart';
import '../../../widgets/ledger_row.dart';
import '../../../widgets/section_header.dart';

/// How well a periodic goal is being kept up: this period's status, streaks,
/// the share of fulfilled periods and the gap to the schedule.
class PeriodicConsistencySection extends StatelessWidget {
  const PeriodicConsistencySection({
    super.key,
    required this.adherence,
    required this.unit,
    required this.amount,
    required this.startDate,
  });

  final PeriodicAdherence adherence;
  final PeriodUnit unit;
  final int amount;
  final DateTime startDate;

  @override
  Widget build(BuildContext context) {
    final noun = unit.label.toLowerCase();

    if (!adherence.started) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(title: 'Konsistensi'),
          const SizedBox(height: AppSpacing.sm),
          InfoBanner(
            message: 'Target ini mulai ${formatDateShort(startDate)}. '
                'Konsistensi dihitung sejak hari itu.',
            color: AppColors.onSurfaceVariant,
            icon: Icons.event_outlined,
          ),
        ],
      );
    }

    final scheduled = amount * (adherence.currentIndex + 1);
    final ahead = adherence.actualTotal - scheduled;
    final consistency = adherence.consistency;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(title: 'Konsistensi'),
        const SizedBox(height: AppSpacing.sm),
        if (adherence.currentFulfilled)
          InfoBanner(
            message: 'Setoran $noun ini sudah terpenuhi '
                '(${formatRupiah(adherence.currentTotal)} dari ${formatRupiah(amount)}).',
            color: AppColors.income,
            icon: Icons.check_circle_outline,
          )
        else
          InfoBanner(
            message: 'Setoran $noun ini: ${formatRupiah(adherence.currentTotal)} '
                'dari ${formatRupiah(amount)}. Kurang '
                '${formatRupiahAuto(adherence.currentRemaining.toDouble())} '
                'sampai ${formatDateShort(adherence.currentPeriodEnd)}.',
            color: AppColors.primary,
            icon: Icons.schedule,
          ),
        const SizedBox(height: AppSpacing.gutter),
        Row(
          children: [
            Expanded(
              child: _StatTile(
                label: 'Beruntun',
                value: '${adherence.streak} $noun',
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: _StatTile(
                label: 'Terbaik',
                value: '${adherence.bestStreak} $noun',
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: _StatTile(
                label: 'Terpenuhi',
                value: consistency == null
                    ? '–'
                    : formatPercent(consistency * 100, digits: 0),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.gutter),
        BorderedListCard(
          children: [
            LedgerRow(
              label: 'Terkumpul sejak ${formatDateShort(startDate)}',
              value: formatRupiah(adherence.actualTotal),
            ),
            LedgerRow(
              label: 'Seharusnya pada akhir $noun ini',
              value: formatRupiah(scheduled),
            ),
            if (adherence.catchUp > 0)
              LedgerRow(
                label: 'Kurang untuk menyamai jadwal',
                value: formatRupiah(adherence.catchUp),
                emphasized: true,
                valueColor: AppColors.primary,
              )
            else
              LedgerRow(
                label: 'Di depan jadwal',
                value: '+${formatRupiah(ahead)}',
                emphasized: true,
                valueColor: AppColors.income,
              ),
            if (adherence.missedPeriods > 0)
              LedgerRow(
                label: '${unit.label} yang terlewat',
                value: '${adherence.missedPeriods} dari ${adherence.completedPeriods}',
              ),
          ],
        ),
        if (adherence.recent.length > 1) ...[
          const SizedBox(height: AppSpacing.md),
          _RecentBars(adherence: adherence, noun: noun),
        ],
      ],
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.gutter),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: textTheme.labelMedium?.copyWith(
              color: AppColors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(value, style: textTheme.titleSmall),
          ),
        ],
      ),
    );
  }
}

class _RecentBars extends StatelessWidget {
  const _RecentBars({required this.adherence, required this.noun});

  final PeriodicAdherence adherence;
  final String noun;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final recent = adherence.recent;
    final fulfilled = recent.where((b) => b.fulfilled).length;

    return Semantics(
      label: '$fulfilled dari ${recent.length} $noun terakhir terpenuhi',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Riwayat ${recent.length} $noun terakhir',
            style: textTheme.labelLarge,
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              for (final bucket in recent)
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxs),
                    child: _Bar(bucket: bucket),
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Hijau = terpenuhi · merah = terlewat · berbingkai emas = $noun berjalan',
            style: textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

class _Bar extends StatelessWidget {
  const _Bar({required this.bucket});

  final PeriodBucket bucket;

  @override
  Widget build(BuildContext context) {
    late final Color fill;
    if (bucket.fulfilled) {
      fill = AppColors.income;
    } else if (bucket.isCurrent) {
      fill = AppColors.surfaceContainerHighest;
    } else {
      fill = AppColors.error.withValues(alpha: 0.55);
    }

    return Container(
      height: 32,
      decoration: BoxDecoration(
        color: fill,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: bucket.isCurrent
            ? Border.all(color: AppColors.primary, width: 1.5)
            : null,
      ),
    );
  }
}
