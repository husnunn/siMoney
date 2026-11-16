import 'package:flutter/material.dart';

import '../../../models/models.dart';
import '../../../state/app_store.dart';
import '../../../state/savings_goal_planning.dart';
import '../../../state/savings_planner.dart';
import '../../../theme/app_spacing.dart';
import '../../../widgets/empty_state.dart';
import '../../../widgets/responsive_body.dart';
import '../../../widgets/section_header.dart';
import '../widgets/allocation_history_section.dart';
import '../widgets/plan_summary_card.dart';
import '../widgets/savings_goal_card.dart';
import '../widgets/savings_hero_card.dart';

/// "Target Berkala" tab: a fixed amount saved every day, week or month, with
/// no deadline. Everything else (per day / week / year) is computed.
class PeriodicGoalsTab extends StatelessWidget {
  const PeriodicGoalsTab({
    super.key,
    required this.balanceHidden,
    required this.onToggleBalance,
  });

  final bool balanceHidden;
  final VoidCallback onToggleBalance;

  @override
  Widget build(BuildContext context) {
    final goals = appStore.periodicGoals;
    final shown = goals
        .where((g) => g.status != SavingsGoalStatus.archived)
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    final archived = goals
        .where((g) => g.status == SavingsGoalStatus.archived)
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    final active =
        goals.where((g) => g.status == SavingsGoalStatus.active).toList();

    final commitment = PeriodFigures.sum([
      for (final g in active)
        if (g.periodicPlan() case final plan?) plan.figures,
    ]);

    final goalIds = {for (final g in goals) g.id};
    final recent = appStore.savingsContributions
        .where((c) => goalIds.contains(c.goalId))
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));

    final textTheme = Theme.of(context).textTheme;

    return ResponsiveBody(
      child: ListView(
        key: const PageStorageKey<String>('savings_periodic_tab'),
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.md,
          AppSpacing.md,
          AppSpacing.md,
          88,
        ),
        children: [
          SavingsHeroCard(
            title: 'Total Terkumpul (Target Berkala)',
            amount: appStore.savedAcross(goals),
            caption: '${active.length} target aktif',
            hidden: balanceHidden,
            onToggle: onToggleBalance,
          ),
          if (active.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            PlanSummaryCard(
              title: 'Komitmen menabung semua target',
              caption: 'Gabungan target berkala aktif bila dijalankan terus-menerus.',
              figures: commitment,
            ),
          ],
          const SizedBox(height: AppSpacing.lg),
          const SectionHeader(title: 'Daftar Target Berkala'),
          const SizedBox(height: AppSpacing.sm),
          if (shown.isEmpty && archived.isEmpty)
            const EmptyState(
              icon: Icons.repeat,
              title: 'Belum ada target berkala',
              subtitle: 'Nabung dengan nominal tetap tiap hari, minggu, atau '
                  'bulan, tanpa tenggat. Contoh: Rp120.000 per minggu. '
                  'Ketuk "Target berkala" untuk memulai.',
            )
          else ...[
            for (final g in shown) SavingsGoalCard(goal: g),
            if (archived.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.md),
              Text('Diarsipkan', style: textTheme.titleSmall),
              const SizedBox(height: AppSpacing.sm),
              for (final g in archived) SavingsGoalCard(goal: g),
            ],
          ],
          if (recent.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.lg),
            AllocationHistorySection(contributions: recent.take(5).toList()),
          ],
        ],
      ),
    );
  }
}
