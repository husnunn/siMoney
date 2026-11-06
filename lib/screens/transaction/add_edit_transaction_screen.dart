import 'package:flutter/material.dart';

import '../../state/app_store.dart';
import '../../models/models.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../utils/formatters.dart';
import '../../widgets/add_category_sheet.dart';
import '../../widgets/amount_field.dart';
import '../../widgets/category_chip.dart';
import '../../widgets/primary_button.dart';

class AddEditTransactionScreen extends StatefulWidget {
  const AddEditTransactionScreen({
    super.key,
    this.transactionId,
    this.initialType,
  });

  static const routeName = '/transaction/edit';

  final String? transactionId;
  final TransactionType? initialType;

  @override
  State<AddEditTransactionScreen> createState() =>
      _AddEditTransactionScreenState();
}

class _AddEditTransactionScreenState extends State<AddEditTransactionScreen> {
  late TransactionType _type;
  late TextEditingController _amountController;
  late TextEditingController _noteController;
  String? _categoryId;
  late DateTime _date;
  bool _saving = false;

  bool get _isEditing => widget.transactionId != null;

  @override
  void initState() {
    super.initState();
    final existing = widget.transactionId != null
        ? appStore.transactionById(widget.transactionId!)
        : null;

    _type = existing?.type ?? widget.initialType ?? TransactionType.expense;
    _amountController = TextEditingController(
      text: existing != null
          ? formatRupiah(existing.amount).replaceFirst('Rp', '')
          : '',
    );
    _noteController = TextEditingController(text: existing?.note ?? '');
    _categoryId = existing?.categoryId ?? appStore.categories.first.id;
    _date = existing?.createdAt ?? DateTime.now();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 1)),
    );
    if (picked != null) {
      setState(() {
        _date = DateTime(
          picked.year,
          picked.month,
          picked.day,
          _date.hour,
          _date.minute,
        );
      });
    }
  }

  Future<void> _addCategory() async {
    final name = await showAddCategorySheet(context);
    if (name == null) return;
    await appStore.addCategory(name);
    final matches = appStore.categories.where((c) => c.name == name).toList();
    if (matches.isNotEmpty && mounted) {
      setState(() => _categoryId = matches.last.id);
    }
  }

  Future<void> _save() async {
    final amount = parseAmount(_amountController.text);
    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Masukkan nominal yang valid')),
      );
      return;
    }
    if (_categoryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih kategori')),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      final user = appStore.currentUser;
      final ledger = appStore.currentLedger;
      if (user == null || ledger == null) {
        throw StateError('Ledger belum siap');
      }

      if (_isEditing) {
        final existing = appStore.transactionById(widget.transactionId!);
        if (existing != null) {
          await appStore.updateTransaction(
            existing.copyWith(
              type: _type,
              amount: amount,
              categoryId: _categoryId,
              note: _noteController.text.trim(),
              createdAt: _date,
            ),
          );
        }
      } else {
        await appStore.addTransaction(
          type: _type,
          amount: amount,
          categoryId: _categoryId!,
          note: _noteController.text.trim(),
          createdAt: _date,
        );
      }

      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final isIncome = _type == TransactionType.income;

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit transaksi' : 'Tambah transaksi'),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _TransactionTypeSelector(
                      type: _type,
                      onChanged: (type) => setState(() => _type = type),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    AmountField(
                      controller: _amountController,
                      isIncome: isIncome,
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    Text('Kategori', style: textTheme.labelLarge),
                    const SizedBox(height: AppSpacing.sm),
                    _CategoryPickerRow(
                      categories: appStore.categories,
                      selectedId: _categoryId,
                      onSelect: (id) => setState(() => _categoryId = id),
                      onAddCategory: _addCategory,
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    Text('Tanggal', style: textTheme.labelLarge),
                    const SizedBox(height: AppSpacing.sm),
                    _DateField(date: _date, onTap: _pickDate),
                    const SizedBox(height: AppSpacing.xl),
                    Text('Catatan', style: textTheme.labelLarge),
                    const SizedBox(height: AppSpacing.sm),
                    TextField(
                      controller: _noteController,
                      maxLines: 2,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: const InputDecoration(
                        hintText: 'Opsional (cth: makan siang, tiket bioskop)',
                        prefixIcon: Icon(Icons.edit_note_outlined),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                AppSpacing.sm,
                AppSpacing.md,
                AppSpacing.md,
              ),
              child: PrimaryButton.gradient(
                label: 'Simpan',
                onPressed: _save,
                isLoading: _saving,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TransactionTypeSelector extends StatelessWidget {
  const _TransactionTypeSelector({required this.type, required this.onChanged});

  final TransactionType type;
  final ValueChanged<TransactionType> onChanged;

  @override
  Widget build(BuildContext context) {
    final isIncome = type == TransactionType.income;

    return SegmentedButton<TransactionType>(
      segments: const [
        ButtonSegment(
          value: TransactionType.expense,
          label: Text('Pengeluaran'),
          icon: Icon(Icons.arrow_upward),
        ),
        ButtonSegment(
          value: TransactionType.income,
          label: Text('Pemasukan'),
          icon: Icon(Icons.arrow_downward),
        ),
      ],
      selected: {type},
      onSelectionChanged: (s) => onChanged(s.first),
      style: ButtonStyle(
        foregroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return isIncome ? AppColors.onSecondary : AppColors.onError;
          }
          return AppColors.onSurface;
        }),
        backgroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return isIncome ? AppColors.income : AppColors.expense;
          }
          return AppColors.surfaceContainer;
        }),
      ),
    );
  }
}

class _CategoryPickerRow extends StatelessWidget {
  const _CategoryPickerRow({
    required this.categories,
    required this.selectedId,
    required this.onSelect,
    required this.onAddCategory,
  });

  final List<TxCategory> categories;
  final String? selectedId;
  final ValueChanged<String> onSelect;
  final VoidCallback onAddCategory;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 56,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: categories.length + 1,
        separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.sm),
        itemBuilder: (context, index) {
          if (index == categories.length) {
            return _AddCategoryChip(onTap: onAddCategory);
          }
          final cat = categories[index];
          return CategoryChip(
            category: cat,
            selected: cat.id == selectedId,
            onTap: () => onSelect(cat.id),
          );
        },
      ),
    );
  }
}

class _DateField extends StatelessWidget {
  const _DateField({required this.date, required this.onTap});

  final DateTime date;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.md,
        ),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainer,
          border: Border.all(color: AppColors.outlineVariant),
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: const Icon(Icons.calendar_today_outlined, size: 16),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(formatDateShort(date), style: textTheme.labelLarge),
            ),
            const Icon(Icons.chevron_right),
          ],
        ),
      ),
    );
  }
}

class _AddCategoryChip extends StatelessWidget {
  const _AddCategoryChip({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.full),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.md,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.full),
            border: Border.all(
              color: AppColors.outlineVariant,
              style: BorderStyle.solid,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.add, size: 18, color: AppColors.onSurfaceVariant),
              const SizedBox(width: AppSpacing.sm),
              Text(
                'Kategori',
                style: textTheme.labelLarge?.copyWith(
                  color: AppColors.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
