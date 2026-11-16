import '../../models/savings_plan_types.dart';

/// The same saving expressed per day, week, month and year.
class PeriodFigures {
  const PeriodFigures({
    required this.perDay,
    required this.perWeek,
    required this.perMonth,
    required this.perYear,
  });

  static const PeriodFigures zero = PeriodFigures(
    perDay: 0,
    perWeek: 0,
    perMonth: 0,
    perYear: 0,
  );

  factory PeriodFigures.fromDaily(double perDay) {
    return PeriodFigures(
      perDay: perDay,
      perWeek: perDay * PeriodUnit.week.days,
      perMonth: perDay * PeriodUnit.month.days,
      perYear: perDay * PeriodUnit.year.days,
    );
  }

  factory PeriodFigures.fromAmount(double amount, PeriodUnit unit) {
    return PeriodFigures.fromDaily(amount / unit.days);
  }

  /// Adds several figures together (e.g. the combined need of all goals).
  factory PeriodFigures.sum(Iterable<PeriodFigures> items) {
    var day = 0.0;
    var week = 0.0;
    var month = 0.0;
    var year = 0.0;
    for (final f in items) {
      day += f.perDay;
      week += f.perWeek;
      month += f.perMonth;
      year += f.perYear;
    }
    return PeriodFigures(
      perDay: day,
      perWeek: week,
      perMonth: month,
      perYear: year,
    );
  }

  final double perDay;
  final double perWeek;
  final double perMonth;
  final double perYear;

  double of(PeriodUnit unit) {
    return switch (unit) {
      PeriodUnit.day => perDay,
      PeriodUnit.week => perWeek,
      PeriodUnit.month => perMonth,
      PeriodUnit.year => perYear,
    };
  }
}

/// A dated money movement (positive = deposit, negative = withdrawal).
class DatedAmount {
  const DatedAmount(this.date, this.amount);

  final DateTime date;
  final int amount;
}

/// One point of the "balance vs. cost" projection chart.
class ProjectionPoint {
  const ProjectionPoint({
    required this.day,
    required this.balance,
    required this.cost,
  });

  /// Days from today.
  final double day;

  /// Projected savings balance.
  final double balance;

  /// Projected cost of the goal (rises with inflation when adjusted).
  final double cost;
}
