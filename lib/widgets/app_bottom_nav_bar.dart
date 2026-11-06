import 'dart:ui';

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

class AppNavDestination {
  const AppNavDestination({
    required this.icon,
    required this.selectedIcon,
    required this.label,
  });

  final IconData icon;
  final IconData selectedIcon;
  final String label;
}

/// Bespoke bottom navigation bar matching the reference design: a
/// translucent dark bar with a thin gold top-aligned indicator on the
/// active tab, instead of Flutter's stock filled-pill indicator.
class AppBottomNavBar extends StatelessWidget {
  const AppBottomNavBar({
    super.key,
    required this.destinations,
    required this.selectedIndex,
    required this.onDestinationSelected,
  });

  final List<AppNavDestination> destinations;
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final bottomInset = MediaQuery.of(context).padding.bottom;

    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          decoration: const BoxDecoration(
            color: Color(0xE6181C24), // surfaceContainerLow @ ~90% alpha
            border: Border(
              top: BorderSide(color: AppColors.outlineVariant, width: 0.5),
            ),
          ),
          padding: EdgeInsets.only(bottom: bottomInset),
          child: SizedBox(
            height: 64,
            child: Row(
              children: [
                for (var i = 0; i < destinations.length; i++)
                  Expanded(
                    child: _NavItem(
                      destination: destinations[i],
                      selected: i == selectedIndex,
                      labelStyle: textTheme.labelSmall,
                      onTap: () => onDestinationSelected(i),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.destination,
    required this.selected,
    required this.onTap,
    this.labelStyle,
  });

  final AppNavDestination destination;
  final bool selected;
  final VoidCallback onTap;
  final TextStyle? labelStyle;

  @override
  Widget build(BuildContext context) {
    final color = selected
        ? AppColors.primary
        : AppColors.onSurfaceVariant;

    return InkWell(
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Reserve the indicator's slot for every item (visible only when
          // selected) so the bar never overlaps the icon below it and the
          // layout doesn't shift when selection changes.
          SizedBox(
            width: 32,
            height: 2,
            child: selected
                ? DecoratedBox(
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(1),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.5),
                          blurRadius: 6,
                        ),
                      ],
                    ),
                  )
                : null,
          ),
          const SizedBox(height: 6),
          Icon(
            selected ? destination.selectedIcon : destination.icon,
            size: 22,
            color: color,
          ),
          const SizedBox(height: 4),
          Text(destination.label, style: labelStyle?.copyWith(color: color)),
        ],
      ),
    );
  }
}
