import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

/// One "label ........ value" line of a calculation breakdown. Put several
/// inside a [BorderedListCard] to get a ledger-style statement.
class LedgerRow extends StatelessWidget {
  const LedgerRow({
    super.key,
    required this.label,
    required this.value,
    this.emphasized = false,
    this.valueColor,
  });

  final String label;
  final String value;

  /// Bold label and value, for subtotals and results.
  final bool emphasized;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final labelStyle = emphasized
        ? textTheme.labelLarge
        : textTheme.bodyMedium?.copyWith(color: AppColors.onSurfaceVariant);
    final valueStyle = (emphasized ? textTheme.titleSmall : textTheme.labelLarge)
        ?.copyWith(
      color: valueColor ?? AppColors.onSurface,
      fontFeatures: const [FontFeature.tabularFigures()],
    );

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.gutter,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: [
          Expanded(child: Text(label, style: labelStyle)),
          const SizedBox(width: AppSpacing.sm),
          Flexible(
            child: Text(value, style: valueStyle, textAlign: TextAlign.end),
          ),
        ],
      ),
    );
  }
}
