import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../state/savings_planner.dart';
import '../../../theme/app_colors.dart';
import '../../../utils/formatters.dart';

/// Line chart of [ProjectionPoint]s: balance (solid) against cost (dashed).
class ProjectionChart extends StatelessWidget {
  const ProjectionChart({super.key, required this.points, this.height = 220});

  final List<ProjectionPoint> points;
  final double height;

  @override
  Widget build(BuildContext context) {
    final labelStyle =
        Theme.of(context).textTheme.bodySmall ?? DefaultTextStyle.of(context).style;

    return Semantics(
      label: 'Grafik proyeksi saldo menuju harga target',
      image: true,
      child: SizedBox(
        height: height,
        width: double.infinity,
        child: CustomPaint(
          painter: _ChartPainter(points: points, labelStyle: labelStyle),
        ),
      ),
    );
  }
}

class _ChartPainter extends CustomPainter {
  _ChartPainter({required this.points, required this.labelStyle});

  final List<ProjectionPoint> points;
  final TextStyle labelStyle;

  static const double _left = 58;
  static const double _right = 12;
  static const double _top = 8;
  static const double _bottom = 24;

  @override
  void paint(Canvas canvas, Size size) {
    if (points.length < 2) return;
    final chart = Rect.fromLTRB(
      _left,
      _top,
      size.width - _right,
      size.height - _bottom,
    );
    if (chart.width <= 0 || chart.height <= 0) return;

    var maxValue = 0.0;
    for (final p in points) {
      maxValue = math.max(maxValue, math.max(p.balance, p.cost));
    }
    if (maxValue <= 0) return;

    final step = _niceStep(maxValue * 1.05 / 4);
    final yMax = (maxValue * 1.05 / step).ceil() * step;
    final totalDays = points.last.day;
    if (totalDays <= 0) return;

    double dx(double day) => chart.left + chart.width * (day / totalDays);
    double dy(double value) => chart.bottom - chart.height * (value / yMax);

    // Horizontal grid and y-axis labels.
    final gridPaint = Paint()
      ..color = AppColors.outlineVariant.withValues(alpha: 0.6)
      ..strokeWidth = 1;
    for (var v = 0.0; v <= yMax + step / 2; v += step) {
      final y = dy(v);
      canvas.drawLine(Offset(chart.left, y), Offset(chart.right, y), gridPaint);
      final tp = _layout(formatRupiahCompact(v));
      tp.paint(canvas, Offset(chart.left - 8 - tp.width, y - tp.height / 2));
    }

    // X-axis labels: quarters for short horizons, years otherwise.
    final shortRange = totalDays <= 548;
    final unitDays = shortRange ? 365 / 4 : 365.0;
    final totalUnits = totalDays / unitDays;
    final stepUnits = shortRange ? 1 : (totalUnits <= 6 ? 1 : (totalUnits <= 12 ? 2 : 5));
    for (var k = 0;; k += stepUnits) {
      final day = k * unitDays;
      if (day > totalDays + 0.5) break;
      final x = dx(day);
      final label = k == 0
          ? 'Sekarang'
          : (shortRange ? '${k * 3} bln' : '$k th');
      final tp = _layout(label);
      final left = k == 0 ? x : x - tp.width / 2;
      if (left + tp.width <= size.width) {
        tp.paint(canvas, Offset(left, chart.bottom + 6));
      }
    }

    // Balance and cost paths.
    final balancePath = Path();
    final costPath = Path();
    for (var i = 0; i < points.length; i++) {
      final p = points[i];
      final x = dx(p.day);
      if (i == 0) {
        balancePath.moveTo(x, dy(p.balance));
        costPath.moveTo(x, dy(p.cost));
      } else {
        balancePath.lineTo(x, dy(p.balance));
        costPath.lineTo(x, dy(p.cost));
      }
    }

    final area = Path.from(balancePath)
      ..lineTo(chart.right, chart.bottom)
      ..lineTo(chart.left, chart.bottom)
      ..close();
    canvas.drawPath(
      area,
      Paint()..color = AppColors.primary.withValues(alpha: 0.10),
    );

    _drawDashed(
      canvas,
      costPath,
      Paint()
        ..color = AppColors.error
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..strokeJoin = StrokeJoin.round,
    );
    canvas.drawPath(
      balancePath,
      Paint()
        ..color = AppColors.primary
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.5
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );

    // Start and end markers.
    final first = points.first;
    final last = points.last;
    canvas.drawCircle(
      Offset(dx(first.day), dy(first.balance)),
      5,
      Paint()..color = AppColors.primary,
    );
    canvas.drawCircle(
      Offset(dx(first.day), dy(first.cost)),
      5,
      Paint()..color = AppColors.error,
    );
    canvas.drawCircle(
      Offset(dx(last.day), dy(last.balance)),
      6,
      Paint()..color = AppColors.income,
    );
  }

  TextPainter _layout(String text) {
    return TextPainter(
      text: TextSpan(text: text, style: labelStyle),
      textDirection: TextDirection.ltr,
      maxLines: 1,
    )..layout();
  }

  static double _niceStep(double raw) {
    final magnitude =
        math.pow(10, (math.log(raw) / math.ln10).floor()).toDouble();
    for (final m in const [1.0, 2.0, 2.5, 5.0, 10.0]) {
      if (raw <= m * magnitude) return m * magnitude;
    }
    return 10 * magnitude;
  }

  static void _drawDashed(
    Canvas canvas,
    Path path,
    Paint paint, {
    double dash = 7,
    double gap = 5,
  }) {
    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        final next = math.min(distance + dash, metric.length);
        canvas.drawPath(metric.extractPath(distance, next), paint);
        distance += dash + gap;
      }
    }
  }

  @override
  bool shouldRepaint(_ChartPainter old) =>
      old.points != points || old.labelStyle != labelStyle;
}
