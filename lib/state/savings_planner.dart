/// Pure-Dart planning math for savings goals (no Flutter / Firebase imports),
/// so every formula can be unit tested in isolation.
///
/// Conventions: 1 year = 365 days, 1 month = 365 / 12 days (see [PeriodUnit]).
/// Money is handled as `double` internally and rounded only for display.
///
/// The code lives in `planning/`; this file re-exports it so callers need a
/// single import.
library;

export 'planning/final_goal_plan.dart';
export 'planning/period_figures.dart';
export 'planning/periodic_adherence.dart';
export 'planning/periodic_plan.dart';
export 'planning/plan_math.dart';
