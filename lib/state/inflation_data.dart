import 'dart:math' as math;

/// Indonesian CPI inflation reference data used as the default assumption for
/// savings projections. Figures come from BPS releases (as relayed by Bank
/// Indonesia and the press); the series is bundled with the app and is meant
/// to be refreshed by hand when BPS publishes a new month (first working day
/// of each month).
abstract final class InflationData {
  /// Latest monthly reading shown in the UI.
  static const String latestPeriodLabel = 'Okt 2026';
  static const double latestYoy = 3.23;
  static const double latestMonthly = 0.22;

  /// Government / Bank Indonesia target for 2026 and 2027: 2.5% ± 1%.
  static const double targetMidpoint = 2.5;
  static const double targetBand = 1.0;

  static const String sourceNote = 'BPS dan Bank Indonesia';
  static const String updatedLabel = '2 Nov 2026';

  /// Calendar-year inflation (December to December), in percent.
  static const Map<int, double> annual = {
    2016: 3.02,
    2017: 3.61,
    2018: 3.13,
    2019: 2.72,
    2020: 1.68,
    2021: 1.87,
    2022: 5.51,
    2023: 2.61,
    2024: 1.57,
    2025: 2.92,
  };

  /// Geometric mean of [annual] between [fromYear] and [toYear] inclusive.
  static double geometricAverage(int fromYear, int toYear) {
    var product = 1.0;
    var count = 0;
    for (var year = fromYear; year <= toYear; year++) {
      final value = annual[year];
      if (value == null) continue;
      product *= 1 + value / 100;
      count++;
    }
    if (count == 0) return latestYoy;
    return (math.pow(product, 1 / count).toDouble() - 1) * 100;
  }

  static double get average10y => geometricAverage(2016, 2025);

  static double get average5y => geometricAverage(2021, 2025);

  /// Default ("auto") rate for a horizon: near-term goals anchor on the latest
  /// reading, long-term goals drift towards the long-run average.
  ///
  /// Boundaries are the maximum number of days in 2 / 4 / 7 calendar years
  /// (leap days included), so "2 years" always lands in the 1-2 year bucket.
  static double autoRateForDays(int days) {
    if (days <= 731) return 3.2; // up to 2 years
    if (days <= 1461) return 3.1; // 3-4 years
    if (days <= 2557) return 3.0; // 5-7 years
    return 2.9; // 8+ years
  }

  /// Goals without a deadline (periodic goals) pick their automatic rate for a
  /// mid-term horizon of about five years.
  static const int periodicHorizonDays = 1826;

  /// Resolves a user setting: `null` means "auto for this horizon".
  static double resolve(double? rate, int days) {
    return rate ?? autoRateForDays(days);
  }
}

/// Named inflation scenarios offered next to the "auto" choice.
enum InflationScenario {
  low(label: 'Rendah', rate: 2.5, hint: 'Titik tengah target BI'),
  base(label: 'Dasar', rate: 3.2, hint: 'Setara inflasi terkini'),
  high(label: 'Tinggi', rate: 5.5, hint: 'Setara tahun 2022 (5,51%)');

  const InflationScenario({
    required this.label,
    required this.rate,
    required this.hint,
  });

  final String label;
  final double rate;
  final String hint;
}
