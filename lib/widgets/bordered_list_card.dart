import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

/// Surface container with a divider between each child, used for lists of
/// rows (transactions, settings, allocations) that share one bordered card.
class BorderedListCard extends StatelessWidget {
  const BorderedListCard({
    super.key,
    required this.children,
    this.dividerIndent = 0,
  });

  final List<Widget> children;
  final double dividerIndent;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceContainer,
        border: Border.all(color: AppColors.outlineVariant),
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          for (var i = 0; i < children.length; i++) ...[
            children[i],
            if (i < children.length - 1)
              Divider(height: 1, indent: dividerIndent),
          ],
        ],
      ),
    );
  }
}
