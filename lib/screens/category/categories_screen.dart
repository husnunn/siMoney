import 'package:flutter/material.dart';

import '../../models/models.dart';
import '../../state/app_store.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../widgets/add_category_sheet.dart';

class CategoriesScreen extends StatelessWidget {
  const CategoriesScreen({super.key});

  static const routeName = '/categories';

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: appStore,
      builder: (context, _) {
        final categories = appStore.categories;
        final currentUserId = appStore.currentUser?.id;

        return Scaffold(
          appBar: AppBar(title: const Text('Kategori')),
          floatingActionButton: FloatingActionButton(
            onPressed: () async {
              final name = await showAddCategorySheet(context);
              if (name != null) {
                await appStore.addCategory(name);
              }
            },
            tooltip: 'Tambah kategori',
            child: const Icon(Icons.add),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.md,
              AppSpacing.md,
              88,
            ),
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.surfaceContainer,
                border: Border.all(color: AppColors.outlineVariant),
                borderRadius: BorderRadius.circular(AppRadius.lg),
              ),
              clipBehavior: Clip.antiAlias,
              child: Column(
                children: [
                  for (var index = 0; index < categories.length; index++) ...[
                    _CategoryRow(
                      category: categories[index],
                      canDelete: categories[index].isCustom &&
                          categories[index].createdBy == currentUserId,
                    ),
                    if (index < categories.length - 1)
                      const Divider(height: 1),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _CategoryRow extends StatelessWidget {
  const _CategoryRow({required this.category, required this.canDelete});

  final TxCategory category;
  final bool canDelete;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final cat = category;
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      leading: CircleAvatar(
        backgroundColor: AppColors.surfaceContainerHigh,
        child: Icon(cat.icon, color: AppColors.onSurface, size: 20),
      ),
      title: Text(cat.name, style: textTheme.titleMedium),
      trailing: cat.isCustom
          ? Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Custom',
                  style: textTheme.bodySmall?.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                if (canDelete)
                  IconButton(
                    tooltip: 'Hapus kategori',
                    icon: const Icon(
                      Icons.delete_outline,
                      color: AppColors.error,
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 40,
                      minHeight: 40,
                    ),
                    onPressed: () async {
                      final confirmed = await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Hapus kategori?'),
                          content: const Text(
                            'Kategori ini akan dihapus. Transaksi lama tetap ditampilkan dengan nama kategori terakhir.',
                          ),
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
                      if (confirmed != true) return;

                      try {
                        await appStore.deleteCategory(cat.id);
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Kategori dihapus')),
                        );
                      } catch (e) {
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Akses ditolak. Hanya pembuat kategori yang bisa menghapus.',
                            ),
                          ),
                        );
                      }
                    },
                  ),
              ],
            )
          : Text('Default', style: textTheme.bodySmall),
    );
  }
}
