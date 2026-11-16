import 'package:flutter/material.dart';

import '../../../models/models.dart';
import '../../../state/savings_planner.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_spacing.dart';
import '../../../utils/formatters.dart';

const List<PeriodUnit> _allUnits = [
  PeriodUnit.day,
  PeriodUnit.week,
  PeriodUnit.month,
  PeriodUnit.year,
];

/// The same amount shown per day, week, month and year. Two columns on a
/// phone, four on wider screens. [highlight] tints the unit the goal is
/// defined in (or the one that matters most, usually the month).
class PeriodFiguresGrid extends StatelessWidget {
  const PeriodFiguresGrid({
    super.key,
    required this.figures,
    this.highlight = PeriodUnit.month,
  });

  final PeriodFigures figures;
  final PeriodUnit? highlight;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 520 ? 4 : 2;
        final tileWidth =
            (constraints.maxWidth - AppSpacing.sm * (columns - 1)) / columns;
        return Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            for (final unit in _allUnits)
              SizedBox(
                width: tileWidth,
                child: _FigureTile(
                  label: unit.perLabel,
                  value: figures.of(unit),
                  highlighted: unit == highlight,
                ),
              ),
          ],
        );
      },
    );
  }
}

class _FigureTile extends StatelessWidget {
  const _FigureTile({
    required this.label,
    required this.value,
    required this.highlighted,
  });

  final String label;
  final double value;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final accent = highlighted ? AppColors.primary : AppColors.onSurface;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.gutter,
        vertical: AppSpacing.gutter,
      ),
      decoration: BoxDecoration(
        color: highlighted
            ? AppColors.primary.withValues(alpha: 0.12)
            : AppColors.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: highlighted
              ? AppColors.primary.withValues(alpha: 0.5)
              : Colors.transparent,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: textTheme.labelMedium?.copyWith(
              color: highlighted ? AppColors.primary : AppColors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              formatRupiahAuto(value),
              style: textTheme.titleSmall?.copyWith(
                color: accent,
                fontWeight: FontWeight.w700,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// A compact single-row version of [PeriodFiguresGrid] for list cards.
class PeriodFiguresStrip extends StatelessWidget {
  const PeriodFiguresStrip({
    super.key,
    required this.figures,
    this.highlight = PeriodUnit.month,
  });

  final PeriodFigures figures;
  final PeriodUnit? highlight;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Row(
      children: [
        for (var i = 0; i < _allUnits.length; i++) ...[
          if (i > 0) const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _allUnits[i].perLabel,
                  style: textTheme.bodySmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: AppSpacing.xxs),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    formatRupiahCompact(figures.of(_allUnits[i])),
                    style: textTheme.labelLarge?.copyWith(
                      color: _allUnits[i] == highlight
                          ? AppColors.primary
                          : AppColors.onSurface,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
