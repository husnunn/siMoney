import 'package:flutter/material.dart';

import '../theme/app_spacing.dart';
import '../theme/category_colors.dart';

/// Small uppercase pill badge for a transaction's category label. There is
/// no stored color per category, so the hue is derived deterministically
/// from the category id so the same category always renders the same tint.
class CategoryTag extends StatelessWidget {
  const CategoryTag({super.key, required this.categoryId, required this.label});

  final String categoryId;
  final String label;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final color = CategoryColors.forCategoryId(categoryId);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Text(
        label.toUpperCase(),
        style: textTheme.labelSmall?.copyWith(
          color: color,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}
