import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

/// Reusable empty-state block: optional icon, title, optional subtitle,
/// centered in a vertically padded column.
class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    this.icon,
    required this.title,
    this.subtitle,
    this.titleStyle,
    this.padding = const EdgeInsets.symmetric(vertical: AppSpacing.xxl),
  });

  final IconData? icon;
  final String title;
  final String? subtitle;
  final TextStyle? titleStyle;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: padding,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 48, color: AppColors.outline.withValues(alpha: 0.5)),
              const SizedBox(height: AppSpacing.md),
            ],
            Text(
              title,
              style: titleStyle ?? textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
            if (subtitle != null) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(subtitle!, style: textTheme.bodySmall, textAlign: TextAlign.center),
            ],
          ],
        ),
      ),
    );
  }
}
