/// Kind of savings goal.
enum SavingsGoalKind {
  /// "Target Akhir": a total amount to reach, optionally by a deadline.
  target,

  /// "Target Berkala": a fixed amount saved every period, no deadline.
  periodic,
}

/// A saving period. [days] is the average length in days, using the
/// convention 1 year = 365 days and 1 month = 365 / 12 days, so every unit
/// converts to every other one consistently (week = 7 × day, and so on).
enum PeriodUnit {
  day(label: 'Hari', perLabel: 'per hari', days: 1),
  week(label: 'Minggu', perLabel: 'per minggu', days: 7),
  month(label: 'Bulan', perLabel: 'per bulan', days: 365 / 12),
  year(label: 'Tahun', perLabel: 'per tahun', days: 365);

  const PeriodUnit({
    required this.label,
    required this.perLabel,
    required this.days,
  });

  final String label;
  final String perLabel;
  final double days;

  /// Units a user can pick when creating a periodic goal.
  static const List<PeriodUnit> selectable = [day, week, month];

  static PeriodUnit? fromName(String? name) {
    for (final unit in values) {
      if (unit.name == name) return unit;
    }
    return null;
  }
}
