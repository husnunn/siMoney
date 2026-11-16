import 'package:flutter/material.dart';

import '../../../models/models.dart';
import '../../../state/app_store.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_spacing.dart';
import '../../../utils/formatters.dart';
import '../../../widgets/bordered_list_card.dart';
import '../../../widgets/section_header.dart';

/// "Riwayat Alokasi": the most recent deposits / withdrawals, one row each,
/// labelled with the goal they belong to.
class AllocationHistorySection extends StatelessWidget {
  const AllocationHistorySection({super.key, required this.contributions});

  final List<SavingsContribution> contributions;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(title: 'Riwayat Alokasi'),
        const SizedBox(height: AppSpacing.sm),
        BorderedListCard(
          dividerIndent: 56,
          children: [
            for (final contribution in contributions)
              _AllocationRow(contribution: contribution),
          ],
        ),
      ],
    );
  }
}

class _AllocationRow extends StatelessWidget {
  const _AllocationRow({required this.contribution});

  final SavingsContribution contribution;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final isDeposit = contribution.isDeposit;
    final color = isDeposit ? AppColors.income : AppColors.expense;
    final sign = isDeposit ? '+' : '−';
    final goalName = appStore.goalById(contribution.goalId)?.name ?? 'Target';

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      leading: CircleAvatar(
        radius: 18,
        backgroundColor: AppColors.surfaceContainerHigh,
        child: Icon(
          isDeposit ? Icons.south_west : Icons.north_east,
          size: 16,
          color: color,
        ),
      ),
      title: Text(goalName, style: textTheme.labelLarge),
      subtitle: Text(
        formatRelativeTime(contribution.date),
        style: textTheme.bodySmall,
      ),
      trailing: Text(
        '$sign${formatRupiah(contribution.amount)}',
        style: textTheme.labelLarge?.copyWith(color: color),
      ),
    );
  }
}
