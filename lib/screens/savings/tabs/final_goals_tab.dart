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

/// "Target Akhir" tab: goals with a total amount to reach, usually by a date.
class FinalGoalsTab extends StatelessWidget {
  const FinalGoalsTab({
    super.key,
    required this.balanceHidden,
    required this.onToggleBalance,
  });

  final bool balanceHidden;
  final VoidCallback onToggleBalance;

  SavingsGoal? _priorityGoal(List<SavingsGoal> active) {
    final sorted = [...active]
      ..sort((a, b) {
        final ad = a.targetDate;
        final bd = b.targetDate;
        if (ad == null && bd == null) return 0;
        if (ad == null) return 1;
        if (bd == null) return -1;
        return ad.compareTo(bd);
      });
    return sorted.isEmpty ? null : sorted.first;
  }

  @override
  Widget build(BuildContext context) {
    final goals = appStore.finalGoals;
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

    final plans = <FinalGoalPlan>[];
    for (final g in active) {
      final plan = g.finalPlan(saved: appStore.goalProgress(g.id));
      if (plan != null && !plan.isReached && !plan.isOverdue) plans.add(plan);
    }
    final need = PeriodFigures.sum(plans.map((p) => p.required));

    final priority = _priorityGoal(active);
    final goalIds = {for (final g in goals) g.id};
    final recent = appStore.savingsContributions
        .where((c) => goalIds.contains(c.goalId))
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));

    final textTheme = Theme.of(context).textTheme;

    return ResponsiveBody(
      child: ListView(
        key: const PageStorageKey<String>('savings_final_tab'),
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.md,
          AppSpacing.md,
          AppSpacing.md,
          88,
        ),
        children: [
          SavingsHeroCard(
            title: 'Total Tabungan Target Akhir',
            amount: appStore.savedAcross(goals),
            caption: '${active.length} target aktif',
            hidden: balanceHidden,
            onToggle: onToggleBalance,
          ),
          if (plans.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            PlanSummaryCard(
              title: 'Kebutuhan menabung semua target',
              caption: 'Sampai tenggat masing-masing, sudah termasuk inflasi.',
              figures: need,
            ),
          ],
          if (priority != null) ...[
            const SizedBox(height: AppSpacing.lg),
            const SectionHeader(title: 'Target Prioritas'),
            const SizedBox(height: AppSpacing.sm),
            SavingsGoalCard(goal: priority),
          ],
          const SizedBox(height: AppSpacing.lg),
          const SectionHeader(title: 'Daftar Celengan Target'),
          const SizedBox(height: AppSpacing.sm),
          if (shown.isEmpty && archived.isEmpty)
            const EmptyState(
              icon: Icons.savings_outlined,
              title: 'Belum ada target akhir',
              subtitle:
                  'Ketuk "Target akhir" untuk membuat target dengan jumlah dan tenggat.',
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
