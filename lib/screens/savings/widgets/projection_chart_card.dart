import 'package:flutter/material.dart';

import '../../../state/savings_planner.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_spacing.dart';
import '../../../utils/formatters.dart';
import '../../../widgets/section_header.dart';
import 'projection_chart.dart';

/// Card with the savings-vs-price chart of a Target Akhir goal: the balance
/// climbing towards a target whose price rises with inflation.
class ProjectionChartCard extends StatelessWidget {
  const ProjectionChartCard({super.key, required this.plan});

  final FinalGoalPlan plan;

  @override
  Widget build(BuildContext context) {
    final points = plan.series();
    if (points.isEmpty) return const SizedBox.shrink();
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(title: 'Proyeksi Saldo vs Harga Target'),
        const SizedBox(height: AppSpacing.sm),
        Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: AppColors.surfaceContainer,
            border: Border.all(color: AppColors.outlineVariant),
            borderRadius: BorderRadius.circular(AppRadius.lg),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: AppSpacing.md,
                runSpacing: AppSpacing.xs,
                children: [
                  const _LegendItem(
                    color: AppColors.primary,
                    label: 'Saldo (sesuai rencana)',
                    dashed: false,
                  ),
                  _LegendItem(
                    color: AppColors.error,
                    label: plan.adjustForInflation
                        ? 'Harga target (naik karena inflasi)'
                        : 'Target (nominal tetap)',
                    dashed: true,
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              ProjectionChart(points: points),
              const SizedBox(height: AppSpacing.sm),
              Text(
                plan.adjustForInflation
                    ? 'Harga target hari ini ${formatRupiahCompact(plan.currentCost)}, '
                        'menjadi ${formatRupiahCompact(plan.adjustedTarget)} pada '
                        '${formatDateShort(plan.deadline)}. Saldo dan harga bertemu '
                        'di tenggat.'
                    : 'Saldo bertemu target ${formatRupiahCompact(plan.adjustedTarget)} '
                        'pada ${formatDateShort(plan.deadline)}.',
                style: textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _LegendItem extends StatelessWidget {
  const _LegendItem({
    required this.color,
    required this.label,
    required this.dashed,
  });

  final Color color;
  final String label;
  final bool dashed;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 22,
          height: 4,
          child: CustomPaint(painter: _LegendLinePainter(color, dashed)),
        ),
        const SizedBox(width: AppSpacing.sm),
        Flexible(child: Text(label, style: textTheme.bodySmall)),
      ],
    );
  }
}

class _LegendLinePainter extends CustomPainter {
  const _LegendLinePainter(this.color, this.dashed);

  final Color color;
  final bool dashed;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    final y = size.height / 2;
    if (!dashed) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
      return;
    }
    canvas.drawLine(Offset(0, y), Offset(8, y), paint);
    canvas.drawLine(Offset(13, y), Offset(size.width, y), paint);
  }

  @override
  bool shouldRepaint(_LegendLinePainter old) =>
      old.color != color || old.dashed != dashed;
}
