import 'package:flutter/material.dart';

import '../../models/models.dart';
import '../../state/app_store.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../widgets/bordered_list_card.dart';
import '../../widgets/responsive_body.dart';
import '../../widgets/savings_contribution_tile.dart';
import '../../widgets/section_header.dart';
import 'add_edit_savings_goal_screen.dart';
import 'widgets/goal_detail_header.dart';
import 'widgets/goal_detail_sections.dart';

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
            child: ResponsiveBody(
              child: ListView(
                padding: const EdgeInsets.all(AppSpacing.md),
                children: [
                  GoalDetailHeader(goal: goal, progress: progress),
                  if (!isArchived) ...[
                    const SizedBox(height: AppSpacing.lg),
                    GoalDetailActions(goal: goal),
                  ],
                  const SizedBox(height: AppSpacing.lg),
                  if (goal.isPeriodic)
                    PeriodicGoalSections(goal: goal, contributions: contributions)
                  else
                    FinalGoalSections(
                      goal: goal,
                      progress: progress,
                      contributions: contributions,
                    ),
                  const SizedBox(height: AppSpacing.lg),
                  const SectionHeader(title: 'Riwayat'),
                  const SizedBox(height: AppSpacing.sm),
                  if (contributions.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: AppSpacing.lg,
                      ),
                      child: Center(
                        child: Text(
                          'Belum ada riwayat setor/tarik',
                          style: textTheme.bodyMedium,
                        ),
                      ),
                    )
                  else
                    BorderedListCard(
                      dividerIndent: 72,
                      children: [
                        for (final c in contributions)
                          SavingsContributionTile(contribution: c),
                      ],
                    ),
                ],
              ),
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
