import 'package:flutter/material.dart';

import '../../models/models.dart';
import '../../state/app_store.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../utils/formatters.dart';
import '../../widgets/savings_contribution_tile.dart';
import '../../widgets/savings_progress_bar.dart';
import '../../widgets/status_pill.dart';
import 'add_contribution_screen.dart';
import 'add_edit_savings_goal_screen.dart';

class SavingsGoalDetailScreen extends StatelessWidget {
  const SavingsGoalDetailScreen({super.key, required this.goalId});

  static const routeName = '/savings/goal/detail';

  final String goalId;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: appStore,
      builder: (context, _) {
        final goal = appStore.goalById(goalId);
        final textTheme = Theme.of(context).textTheme;

        if (goal == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Target')),
            body: const Center(child: Text('Target tidak ditemukan')),
          );
        }

        final progress = appStore.goalProgress(goalId);
        final contributions = appStore.contributionsForGoal(goalId)
          ..sort((a, b) => b.date.compareTo(a.date));
        final isArchived = goal.status == SavingsGoalStatus.archived;

        return Scaffold(
          appBar: AppBar(
            title: Text(goal.name),
            actions: [
              PopupMenuButton<String>(
                onSelected: (value) => _handleMenu(context, goal, value),
                itemBuilder: (context) => [
                  const PopupMenuItem(value: 'edit', child: Text('Edit')),
                  if (isArchived)
                    const PopupMenuItem(
                      value: 'reactivate',
                      child: Text('Aktifkan kembali'),
                    )
                  else
                    const PopupMenuItem(
                      value: 'archive',
                      child: Text('Arsipkan'),
                    ),
                  if (progress == 0)
                    const PopupMenuItem(value: 'delete', child: Text('Hapus')),
                ],
              ),
            ],
          ),
          body: SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          if (goal.status == SavingsGoalStatus.completed)
                            const StatusPill(
                              label: 'Tercapai',
                              color: AppColors.income,
                            )
                          else if (isArchived)
                            const StatusPill(
                              label: 'Diarsipkan',
                              color: AppColors.outline,
                            ),
                        ],
                      ),
                      if (goal.targetDate != null) ...[
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          'Target tercapai sebelum ${formatDateShort(goal.targetDate!)}',
                          style: textTheme.bodySmall,
                        ),
                      ],
                      const SizedBox(height: AppSpacing.md),
                      SavingsProgressBar(
                        progress: progress,
                        target: goal.targetAmount,
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      if (!isArchived)
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () => Navigator.of(context).pushNamed(
                                  AddContributionScreen.routeName,
                                  arguments: AddContributionArgs(
                                    goalId: goalId,
                                    type: ContributionType.deposit,
                                  ),
                                ),
                                icon: const Icon(Icons.south_west),
                                label: const Text('Setor'),
                              ),
                            ),
                            const SizedBox(width: AppSpacing.md),
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () => Navigator.of(context).pushNamed(
                                  AddContributionScreen.routeName,
                                  arguments: AddContributionArgs(
                                    goalId: goalId,
                                    type: ContributionType.withdraw,
                                  ),
                                ),
                                icon: const Icon(Icons.north_east),
                                label: const Text('Tarik'),
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                  child: Text('Riwayat', style: textTheme.titleMedium),
                ),
                const SizedBox(height: AppSpacing.sm),
                const Divider(),
                Expanded(
                  child: contributions.isEmpty
                      ? Center(
                          child: Text(
                            'Belum ada riwayat setor/tarik',
                            style: textTheme.bodyMedium,
                          ),
                        )
                      : ListView.separated(
                          itemCount: contributions.length,
                          separatorBuilder: (_, _) =>
                              const Divider(indent: 72),
                          itemBuilder: (context, index) {
                            return SavingsContributionTile(
                              contribution: contributions[index],
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _handleMenu(
    BuildContext context,
    SavingsGoal goal,
    String value,
  ) async {
    switch (value) {
      case 'edit':
        Navigator.of(context).pushNamed(
          AddEditSavingsGoalScreen.routeName,
          arguments: goal.id,
        );
      case 'archive':
        await appStore.archiveSavingsGoal(goal.id);
      case 'reactivate':
        await appStore.reactivateSavingsGoal(goal.id);
      case 'delete':
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Hapus target?'),
            content: const Text('Tindakan ini tidak dapat dibatalkan.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Batal'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.error,
                ),
                child: const Text('Hapus'),
              ),
            ],
          ),
        );
        if (confirmed == true && context.mounted) {
          try {
            await appStore.deleteSavingsGoal(goal.id);
            if (context.mounted) Navigator.of(context).pop();
          } catch (e) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(e.toString())),
              );
            }
          }
        }
    }
  }
}
