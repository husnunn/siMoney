import 'package:flutter/material.dart';

import '../models/models.dart';

/// One category's aggregated totals within a period, used to drive the
/// donut chart and ranked category list on the analytics screen.
class CategorySpend {
  const CategorySpend({
    required this.categoryId,
    required this.categoryName,
    required this.icon,
    required this.total,
    required this.percentOfTotal,
  });

  final String categoryId;
  final String categoryName;
  final IconData icon;
  final int total;

  /// 0..100, 0 when the grand total is 0.
  final double percentOfTotal;
}

abstract final class AnalyticsCalculator {
  static const otherCategoryId = '_other';

  /// Filters [txs] to [type] transactions whose createdAt falls in the
  /// half-open range [start, end).
  static List<TxRecord> transactionsInRange(
    List<TxRecord> txs,
    TransactionType type,
    DateTime start,
    DateTime end,
  ) {
    return txs
        .where((t) =>
            t.type == type &&
            !t.createdAt.isBefore(start) &&
            t.createdAt.isBefore(end))
        .toList();
  }

  static int totalAmount(List<TxRecord> txs) {
    return txs.fold(0, (sum, t) => sum + t.amount);
  }

  /// Groups [txs] by categoryId, resolving name/icon via [categoryById],
  /// sorted descending by total. When [topN] is given and more than that
  /// many categories have a nonzero total, the remainder are collapsed into
  /// a single trailing "Lainnya" entry.
  static List<CategorySpend> byCategory(
    List<TxRecord> txs,
    TxCategory? Function(String categoryId) categoryById, {
    int? topN,
  }) {
    final totals = <String, int>{};
    for (final tx in txs) {
      totals[tx.categoryId] = (totals[tx.categoryId] ?? 0) + tx.amount;
    }

    final grandTotal = totals.values.fold(0, (sum, v) => sum + v);

    final entries = totals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    List<MapEntry<String, int>> kept = entries;
    int otherTotal = 0;
    if (topN != null && entries.length > topN) {
      kept = entries.sublist(0, topN);
      otherTotal = entries
          .sublist(topN)
          .fold(0, (sum, e) => sum + e.value);
    }

    final result = kept.map((entry) {
      final category = categoryById(entry.key);
      return CategorySpend(
        categoryId: entry.key,
        categoryName: category?.name ?? 'Lainnya',
        icon: category?.icon ?? Icons.more_horiz,
        total: entry.value,
        percentOfTotal: grandTotal == 0 ? 0 : (entry.value / grandTotal) * 100,
      );
    }).toList();

    if (otherTotal > 0) {
      result.add(CategorySpend(
        categoryId: otherCategoryId,
        categoryName: 'Lainnya',
        icon: Icons.more_horiz,
        total: otherTotal,
        percentOfTotal: grandTotal == 0 ? 0 : (otherTotal / grandTotal) * 100,
      ));
    }

    return result;
  }

  /// Percent change of [current] vs [previous]; null when [previous] is 0
  /// (avoids a meaningless infinite percentage on a first-ever period).
  static double? percentChange(int current, int previous) {
    if (previous == 0) return null;
    return ((current - previous) / previous) * 100;
  }
}
