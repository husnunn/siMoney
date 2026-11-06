import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Circular monogram avatar (initials) reused across transaction rows,
/// contribution rows, and the account profile card.
class AvatarMonogram extends StatelessWidget {
  const AvatarMonogram({
    super.key,
    required this.initials,
    this.radius = 20,
    this.background = AppColors.surfaceContainerHigh,
    this.foreground = AppColors.onSurface,
    this.badge,
  });

  final String initials;
  final double radius;
  final Color background;
  final Color foreground;
  final Widget? badge;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    final avatar = CircleAvatar(
      radius: radius,
      backgroundColor: background,
      child: Text(
        initials,
        style: textTheme.labelLarge?.copyWith(
          color: foreground,
          fontSize: radius * 0.65,
        ),
      ),
    );

    if (badge == null) return avatar;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        avatar,
        Positioned(right: -2, bottom: -2, child: badge!),
      ],
    );
  }
}
