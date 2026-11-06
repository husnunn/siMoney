import 'package:flutter/material.dart';

import '../models/transaction.dart';
import '../models/user.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../utils/formatters.dart';
import 'avatar_monogram.dart';

class TransactionTile extends StatelessWidget {
  const TransactionTile({
    super.key,
    required this.transaction,
    required this.categoryName,
    required this.categoryIcon,
    required this.author,
    this.tag,
    this.onTap,
  });

  final TxRecord transaction;
  final String categoryName;
  final IconData categoryIcon;
  final AppUser? author;
  final Widget? tag;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final isIncome = transaction.isIncome;
    final amountColor = isIncome ? AppColors.income : AppColors.expense;
    final sign = isIncome ? '+' : '−';
    final authorName = author?.name ??
        (transaction.createdByName.isNotEmpty
            ? transaction.createdByName
            : 'Pengguna');
    final initials = author?.initials ??
        (authorName.trim().isEmpty
            ? '?'
            : authorName
                .trim()
                .split(RegExp(r'\s+'))
                .take(2)
                .map((p) => p[0].toUpperCase())
                .join());

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        child: Row(
          children: [
            AvatarMonogram(initials: initials),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          categoryName,
                          style: textTheme.labelLarge,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (tag != null) ...[
                        const SizedBox(width: AppSpacing.xs),
                        tag!,
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'oleh $authorName · ${formatRelativeTime(transaction.createdAt)}',
                    style: textTheme.bodySmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (transaction.note.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      transaction.note,
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
              '$sign${formatRupiah(transaction.amount)}',
              style: textTheme.labelLarge?.copyWith(color: amountColor),
            ),
          ],
        ),
      ),
    );
  }
}
