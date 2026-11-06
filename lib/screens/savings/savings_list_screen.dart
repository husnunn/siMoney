import 'package:flutter/material.dart';

import '../../models/models.dart';
import '../../state/app_store.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../utils/formatters.dart';
import '../../widgets/balance_visibility_toggle.dart';
import '../../widgets/bordered_list_card.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/glow_hero_card.dart';
import '../../widgets/savings_progress_bar.dart';
import '../../widgets/section_header.dart';
import '../../widgets/status_pill.dart';
import 'add_edit_savings_goal_screen.dart';
import 'savings_goal_detail_screen.dart';

class SavingsListScreen extends StatefulWidget {
  const SavingsListScreen({super.key});

  @override
  State<SavingsListScreen> createState() => _SavingsListScreenState();
}

class _SavingsListScreenState extends State<SavingsListScreen> {
  bool _balanceHidden = false;

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
    return ListenableBuilder(
      listenable: appStore,
      builder: (context, _) {
        final active = appStore.savingsGoals
            .where((g) => g.status != SavingsGoalStatus.archived)
            .toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
        final archived = appStore.savingsGoals
            .where((g) => g.status == SavingsGoalStatus.archived)
            .toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
        final priority = _priorityGoal(
          active.where((g) => g.status == SavingsGoalStatus.active).toList(),
        );
        final recentContributions = [...appStore.savingsContributions]
          ..sort((a, b) => b.date.compareTo(a.date));
        final topContributions = recentContributions.take(5).toList();

        return Scaffold(
          appBar: AppBar(title: const Text('Tabungan')),
          floatingActionButton: FloatingActionButton(
            heroTag: 'fab_savings',
            onPressed: () {
              Navigator.of(context)
                  .pushNamed(AddEditSavingsGoalScreen.routeName);
            },
            tooltip: 'Tambah target',
            child: const Icon(Icons.add),
          ),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.md,
              AppSpacing.md,
              88,
            ),
            children: [
              _SavingsHeroSection(
                totalSavings: appStore.totalSavings,
                activeCount: active.length,
                balanceHidden: _balanceHidden,
                onToggleBalance: () =>
                    setState(() => _balanceHidden = !_balanceHidden),
              ),
              if (priority != null) ...[
                const SizedBox(height: AppSpacing.lg),
                const SectionHeader(title: 'Target Prioritas'),
                const SizedBox(height: AppSpacing.sm),
                _GoalCard(goal: priority),
              ],
              const SizedBox(height: AppSpacing.lg),
              _GoalListSection(active: active, archived: archived),
              if (topContributions.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.lg),
                _AllocationHistorySection(contributions: topContributions),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _SavingsHeroSection extends StatelessWidget {
  const _SavingsHeroSection({
    required this.totalSavings,
    required this.activeCount,
    required this.balanceHidden,
    required this.onToggleBalance,
  });

  final int totalSavings;
  final int activeCount;
  final bool balanceHidden;
  final VoidCallback onToggleBalance;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return GlowHeroCard(
      glowColor: AppColors.primary,
      secondaryGlowColor: AppColors.secondary,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Total Tabungan Terkumpul', style: textTheme.bodyMedium),
              BalanceVisibilityToggle(
                hidden: balanceHidden,
                color: AppColors.onSurfaceVariant,
                onToggle: onToggleBalance,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          MaskedAmountText(
            amount: totalSavings,
            hidden: balanceHidden,
            style: textTheme.displayLarge?.copyWith(color: AppColors.primary),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text('$activeCount target aktif', style: textTheme.bodySmall),
        ],
      ),
    );
  }
}

class _GoalListSection extends StatelessWidget {
  const _GoalListSection({required this.active, required this.archived});

  final List<SavingsGoal> active;
  final List<SavingsGoal> archived;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(title: 'Daftar Celengan Target'),
        const SizedBox(height: AppSpacing.sm),
        if (active.isEmpty && archived.isEmpty)
          const EmptyState(
            icon: Icons.savings_outlined,
            title: 'Belum ada target tabungan',
            subtitle: 'Ketuk + untuk membuat target baru.',
          )
        else ...[
          ...active.map((g) => _GoalCard(goal: g)),
          if (archived.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            Text('Diarsipkan', style: textTheme.titleSmall),
            const SizedBox(height: AppSpacing.sm),
            ...archived.map((g) => _GoalCard(goal: g)),
          ],
        ],
      ],
    );
  }
}

class _AllocationHistorySection extends StatelessWidget {
  const _AllocationHistorySection({required this.contributions});

  final List<SavingsContribution> contributions;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(title: 'Riwayat Alokasi'),
        const SizedBox(height: AppSpacing.sm),
        BorderedListCard(
          dividerIndent: 56,
          children: [
            for (final contribution in contributions)
              _AllocationRow(contribution: contribution),
          ],
        ),
      ],
    );
  }
}

class _GoalCard extends StatelessWidget {
  const _GoalCard({required this.goal});

  final SavingsGoal goal;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final progress = appStore.goalProgress(goal.id);

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainer,
        border: Border.all(color: AppColors.outlineVariant),
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        onTap: () {
          Navigator.of(context).pushNamed(
            SavingsGoalDetailScreen.routeName,
            arguments: goal.id,
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      goal.name,
                      style: textTheme.labelLarge,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (goal.status == SavingsGoalStatus.completed)
                    const StatusPill(label: 'Tercapai', color: AppColors.income)
                  else if (goal.status == SavingsGoalStatus.archived)
                    const StatusPill(label: 'Diarsipkan', color: AppColors.outline),
                ],
              ),
              if (goal.targetDate != null) ...[
                const SizedBox(height: 2),
                Text(
                  'Target ${formatDateShort(goal.targetDate!)}',
                  style: textTheme.bodySmall,
                ),
              ],
              const SizedBox(height: AppSpacing.sm),
              SavingsProgressBar(progress: progress, target: goal.targetAmount),
            ],
          ),
        ),
      ),
    );
  }
}

class _AllocationRow extends StatelessWidget {
  const _AllocationRow({required this.contribution});

  final SavingsContribution contribution;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final isDeposit = contribution.isDeposit;
    final color = isDeposit ? AppColors.income : AppColors.expense;
    final sign = isDeposit ? '+' : '−';
    final goalName = appStore.goalById(contribution.goalId)?.name ?? 'Target';

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      leading: CircleAvatar(
        radius: 18,
        backgroundColor: AppColors.surfaceContainerHigh,
        child: Icon(
          isDeposit ? Icons.south_west : Icons.north_east,
          size: 16,
          color: color,
        ),
      ),
      title: Text(goalName, style: textTheme.labelLarge),
      subtitle: Text(formatRelativeTime(contribution.date), style: textTheme.bodySmall),
      trailing: Text(
        '$sign${formatRupiah(contribution.amount)}',
        style: textTheme.labelLarge?.copyWith(color: color),
      ),
    );
  }
}
