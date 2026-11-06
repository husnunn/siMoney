import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

/// Signature "ambient glow" card: a dark elevated surface with soft radial
/// glow circles tucked in the corners, used for hero/summary sections
/// (balance, totals, profile) across the app.
class GlowHeroCard extends StatelessWidget {
  const GlowHeroCard({
    super.key,
    required this.child,
    this.glowColor = AppColors.primary,
    this.secondaryGlowColor,
    this.padding = const EdgeInsets.all(AppSpacing.md + AppSpacing.xs),
    this.borderRadius = AppRadius.xl,
  });

  final Widget child;
  final Color glowColor;
  final Color? secondaryGlowColor;
  final EdgeInsetsGeometry padding;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    final secondary = secondaryGlowColor ?? glowColor;

    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: Container(
        decoration: const BoxDecoration(color: AppColors.surfaceContainer),
        child: Stack(
          children: [
            Positioned(
              top: -60,
              right: -60,
              child: _GlowCircle(color: glowColor, size: 160),
            ),
            Positioned(
              bottom: -50,
              left: -50,
              child: _GlowCircle(color: secondary, size: 140),
            ),
            Padding(padding: padding, child: child),
          ],
        ),
      ),
    );
  }
}

class _GlowCircle extends StatelessWidget {
  const _GlowCircle({required this.color, required this.size});

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            color.withValues(alpha: 0.18),
            color.withValues(alpha: 0.0),
          ],
        ),
      ),
    );
  }
}
