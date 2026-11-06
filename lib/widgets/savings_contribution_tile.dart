import 'package:flutter/material.dart';

import '../models/models.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../utils/formatters.dart';

class SavingsContributionTile extends StatelessWidget {
  const SavingsContributionTile({super.key, required this.contribution});

  final SavingsContribution contribution;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final isDeposit = contribution.isDeposit;
    final amountColor = isDeposit ? AppColors.income : AppColors.expense;
    final sign = isDeposit ? '+' : '−';
    final sourceLabel = contribution.source == ContributionSource.appBalance
        ? 'dari saldo aplikasi'
        : 'dari sumber lain';

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: AppColors.surfaceContainerHigh,
            child: Icon(
              isDeposit ? Icons.south_west : Icons.north_east,
              size: 18,
              color: amountColor,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isDeposit ? 'Setor' : 'Tarik',
                  style: textTheme.labelLarge,
                ),
                const SizedBox(height: 2),
                Text(
                  '$sourceLabel · ${contribution.createdByName} · '
                  '${formatRelativeTime(contribution.date)}',
                  style: textTheme.bodySmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (contribution.note.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    contribution.note,
                    style: textTheme.bodySmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Text(
            '$sign${formatRupiah(contribution.amount)}',
            style: textTheme.labelLarge?.copyWith(color: amountColor),
          ),
        ],
      ),
    );
  }
}
