import 'package:flutter/material.dart';

import '../../../theme/app_colors.dart';
import '../../../theme/app_spacing.dart';
import '../../../widgets/balance_visibility_toggle.dart';
import '../../../widgets/glow_hero_card.dart';

/// Summary card at the top of a savings tab: a title, one big amount with the
/// usual hide/show toggle, and a caption.
class SavingsHeroCard extends StatelessWidget {
  const SavingsHeroCard({
    super.key,
    required this.title,
    required this.amount,
    required this.caption,
    required this.hidden,
    required this.onToggle,
  });

  final String title;
  final int amount;
  final String caption;
  final bool hidden;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return GlowHeroCard(
      glowColor: AppColors.primary,
      secondaryGlowColor: AppColors.secondary,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(child: Text(title, style: textTheme.bodyMedium)),
              BalanceVisibilityToggle(
                hidden: hidden,
                color: AppColors.onSurfaceVariant,
                onToggle: onToggle,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          MaskedAmountText(
            amount: amount,
            hidden: hidden,
            style: textTheme.displayLarge?.copyWith(color: AppColors.primary),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(caption, style: textTheme.bodySmall),
        ],
      ),
    );
  }
}
