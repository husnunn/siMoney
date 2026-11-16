import 'package:flutter/material.dart';

import '../../../models/models.dart';
import '../../../theme/app_spacing.dart';
import '../../../widgets/period_pill_selector.dart';

/// Switch between "Target Akhir" and "Target Berkala" with a one-line
/// explanation of the chosen kind. Only shown when creating a goal.
class GoalKindSelector extends StatelessWidget {
  const GoalKindSelector({
    super.key,
    required this.kind,
    required this.onChanged,
  });

  final SavingsGoalKind kind;
  final ValueChanged<SavingsGoalKind> onChanged;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        PeriodPillSelector<SavingsGoalKind>(
          options: const [
            PeriodPillOption(value: SavingsGoalKind.target, label: 'Target Akhir'),
            PeriodPillOption(
              value: SavingsGoalKind.periodic,
              label: 'Target Berkala',
            ),
          ],
          selected: kind,
          onChanged: onChanged,
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          kind == SavingsGoalKind.periodic
              ? 'Nabung dengan nominal tetap tiap hari, minggu, atau bulan, '
                  'tanpa tenggat.'
              : 'Kumpulkan sejumlah uang sampai tenggat tertentu.',
          style: textTheme.bodySmall,
        ),
      ],
    );
  }
}
