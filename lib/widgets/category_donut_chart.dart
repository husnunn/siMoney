import 'dart:math';

import 'package:flutter/material.dart';

import '../state/analytics_calculator.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/category_colors.dart';
import '../utils/formatters.dart';

/// Donut breakdown of [segments] (already sorted descending), with the
/// grand [total] shown in the empty center and tap-to-select per slice.
class CategoryDonutChart extends StatelessWidget {
  const CategoryDonutChart({
    super.key,
    required this.segments,
    required this.total,
    required this.centerLabel,
    this.selectedCategoryId,
    this.onSegmentTap,
    this.size = 180,
    this.strokeWidth = 24,
  });

  final List<CategorySpend> segments;
  final int total;
  final String centerLabel;
  final String? selectedCategoryId;
  final ValueChanged<String?>? onSegmentTap;
  final double size;
  final double strokeWidth;

  List<_SliceRange> _ranges() {
    var start = -pi / 2;
    final ranges = <_SliceRange>[];
    for (final segment in segments) {
      final sweep = total == 0 ? 0.0 : 2 * pi * (segment.total / total);
      ranges.add(_SliceRange(segment.categoryId, start, start + sweep));
      start += sweep;
    }
    return ranges;
  }

  void _handleTapUp(TapUpDetails details, List<_SliceRange> ranges) {
    final callback = onSegmentTap;
    if (callback == null) return;
    final center = Offset(size / 2, size / 2);
    final local = details.localPosition - center;
    var angle = atan2(local.dy, local.dx);
    if (angle < -pi / 2) angle += 2 * pi;
    for (final range in ranges) {
      if (angle >= range.start && angle < range.end) {
        callback(range.categoryId == selectedCategoryId ? null : range.categoryId);
        return;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final ranges = _ranges();

    return GestureDetector(
      onTapUp: (details) => _handleTapUp(details, ranges),
      child: SizedBox(
        width: size,
        height: size,
        child: Stack(
          alignment: Alignment.center,
          children: [
            CustomPaint(
              size: Size(size, size),
              painter: _DonutPainter(
                segments: segments,
                total: total,
                strokeWidth: strokeWidth,
                selectedCategoryId: selectedCategoryId,
              ),
            ),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: size - strokeWidth * 2 - AppSpacing.md,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      formatRupiah(total),
                      style: textTheme.titleLarge,
                      maxLines: 1,
                      softWrap: false,
                    ),
                  ),
                ),
                Text(centerLabel, style: textTheme.bodySmall),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SliceRange {
  const _SliceRange(this.categoryId, this.start, this.end);

  final String categoryId;
  final double start;
  final double end;
}

class _DonutPainter extends CustomPainter {
  const _DonutPainter({
    required this.segments,
    required this.total,
    required this.strokeWidth,
    required this.selectedCategoryId,
  });

  final List<CategorySpend> segments;
  final int total;
  final double strokeWidth;
  final String? selectedCategoryId;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final inset = strokeWidth / 2;
    final arcRect = rect.deflate(inset);

    if (total == 0) {
      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..color = AppColors.surfaceContainerHigh;
      canvas.drawArc(arcRect, 0, 2 * pi, false, paint);
      return;
    }

    var start = -pi / 2;
    for (final segment in segments) {
      final sweep = 2 * pi * (segment.total / total);
      final isOther = segment.categoryId == AnalyticsCalculator.otherCategoryId;
      final selected = selectedCategoryId == null ||
          selectedCategoryId == segment.categoryId;
      final color = isOther
          ? AppColors.outlineVariant
          : CategoryColors.forCategoryId(segment.categoryId);
      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..color = selected ? color : color.withValues(alpha: 0.3);
      canvas.drawArc(arcRect, start, sweep, false, paint);
      start += sweep;
    }
  }

  @override
  bool shouldRepaint(covariant _DonutPainter oldDelegate) {
    return oldDelegate.segments != segments ||
        oldDelegate.total != total ||
        oldDelegate.selectedCategoryId != selectedCategoryId;
  }
}
