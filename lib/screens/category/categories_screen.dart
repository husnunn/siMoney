import 'package:flutter/material.dart';

import '../../state/app_store.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../widgets/primary_button.dart';

class CategoriesScreen extends StatelessWidget {
  const CategoriesScreen({super.key});

  static const routeName = '/categories';

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: appStore,
      builder: (context, _) {
        final textTheme = Theme.of(context).textTheme;
        final categories = appStore.categories;
        final currentUserId = appStore.currentUser?.id;

        return Scaffold(
          appBar: AppBar(title: const Text('Kategori')),
          floatingActionButton: FloatingActionButton(
            onPressed: () => _showAddSheet(context),
            tooltip: 'Tambah kategori',
            child: const Icon(Icons.add),
          ),
          body: ListView.separated(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.md,
              AppSpacing.lg,
              88,
            ),
            itemCount: categories.length,
            separatorBuilder: (_, _) => const Divider(),
            itemBuilder: (context, index) {
              final cat = categories[index];
              final canDelete = cat.isCustom && cat.createdBy == currentUserId;
              return ListTile(
                contentPadding: EdgeInsets.zero,
                leading: CircleAvatar(
                  backgroundColor: AppColors.mutedSurface,
                  child: Icon(cat.icon, color: AppColors.primary, size: 20),
                ),
                title: Text(cat.name, style: textTheme.titleMedium),
                trailing: cat.isCustom
                    ? Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Custom',
                            style: textTheme.bodySmall?.copyWith(
                              color: AppColors.accent,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          if (canDelete)
                            IconButton(
                              tooltip: 'Hapus kategori',
                              icon: Icon(
                                Icons.delete_outline,
                                color: AppColors.destructive,
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
                                        onPressed: () =>
                                            Navigator.pop(context, false),
                                        child: const Text('Batal'),
                                      ),
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.pop(context, true),
                                        style: TextButton.styleFrom(
                                          foregroundColor: AppColors.destructive,
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
                                    const SnackBar(
                                      content: Text('Kategori dihapus'),
                                    ),
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
                    : Text(
                        'Default',
                        style: textTheme.bodySmall,
                      ),
              );
            },
          ),
        );
      },
    );
  }

  Future<void> _showAddSheet(BuildContext context) async {
    final controller = TextEditingController();
    final result = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        final bottom = MediaQuery.viewInsetsOf(context).bottom;
        return Padding(
          padding: EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.lg,
            AppSpacing.lg,
            AppSpacing.lg + bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Tambah kategori',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: AppSpacing.md),
              TextField(
                controller: controller,
                autofocus: true,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'Nama kategori',
                  hintText: 'Contoh: Pendidikan',
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              PrimaryButton(
                label: 'Simpan',
                onPressed: () {
                  Navigator.of(context).pop(controller.text.trim());
                },
              ),
            ],
          ),
        );
      },
    );
    if (result != null && result.isNotEmpty) {
      await appStore.addCategory(result);
    }
  }
}
