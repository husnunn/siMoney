import 'package:flutter/material.dart';

import '../../state/app_store.dart';
import '../../models/transaction.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../utils/formatters.dart';
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
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SegmentedButton<TransactionType>(
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
                      selected: {_type},
                      onSelectionChanged: (s) {
                        setState(() => _type = s.first);
                      },
                      style: ButtonStyle(
                        foregroundColor:
                            WidgetStateProperty.resolveWith((states) {
                          if (states.contains(WidgetState.selected)) {
                            return AppColors.onPrimary;
                          }
                          return AppColors.foreground;
                        }),
                        backgroundColor:
                            WidgetStateProperty.resolveWith((states) {
                          if (states.contains(WidgetState.selected)) {
                            return isIncome
                                ? AppColors.income
                                : AppColors.expense;
                          }
                          return AppColors.surface;
                        }),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    AmountField(
                      controller: _amountController,
                      isIncome: isIncome,
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    Text('Kategori', style: textTheme.labelLarge),
                    const SizedBox(height: AppSpacing.sm),
                    SizedBox(
                      height: 44,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: appStore.categories.length,
                        separatorBuilder: (_, _) =>
                            const SizedBox(width: AppSpacing.sm),
                        itemBuilder: (context, index) {
                          final cat = appStore.categories[index];
                          return CategoryChip(
                            category: cat,
                            selected: cat.id == _categoryId,
                            onTap: () =>
                                setState(() => _categoryId = cat.id),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    Text('Tanggal', style: textTheme.labelLarge),
                    const SizedBox(height: AppSpacing.sm),
                    InkWell(
                      onTap: _pickDate,
                      borderRadius: BorderRadius.circular(12),
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          suffixIcon: Icon(Icons.calendar_today_outlined),
                        ),
                        child: Text(formatDateShort(_date)),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    Text('Catatan', style: textTheme.labelLarge),
                    const SizedBox(height: AppSpacing.sm),
                    TextField(
                      controller: _noteController,
                      maxLines: 2,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: const InputDecoration(
                        hintText: 'Opsional',
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.sm,
                AppSpacing.lg,
                AppSpacing.lg,
              ),
              child: PrimaryButton(
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
