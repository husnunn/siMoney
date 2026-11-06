import 'package:flutter/material.dart';

import '../../state/app_store.dart';
import '../../theme/app_spacing.dart';
import '../../utils/formatters.dart';
import '../../widgets/amount_field.dart';
import '../../widgets/primary_button.dart';

class AddEditSavingsGoalScreen extends StatefulWidget {
  const AddEditSavingsGoalScreen({super.key, this.goalId});

  static const routeName = '/savings/goal/edit';

  final String? goalId;

  @override
  State<AddEditSavingsGoalScreen> createState() =>
      _AddEditSavingsGoalScreenState();
}

class _AddEditSavingsGoalScreenState extends State<AddEditSavingsGoalScreen> {
  late TextEditingController _nameController;
  late TextEditingController _targetController;
  DateTime? _targetDate;
  bool _saving = false;

  bool get _isEditing => widget.goalId != null;

  @override
  void initState() {
    super.initState();
    final existing =
        widget.goalId != null ? appStore.goalById(widget.goalId!) : null;
    _nameController = TextEditingController(text: existing?.name ?? '');
    _targetController = TextEditingController(
      text: existing != null
          ? formatRupiah(existing.targetAmount).replaceFirst('Rp', '')
          : '',
    );
    _targetDate = existing?.targetDate;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _targetController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _targetDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 10)),
    );
    if (picked != null) {
      setState(() => _targetDate = picked);
    }
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    final target = parseAmount(_targetController.text);

    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Masukkan nama target')),
      );
      return;
    }
    if (target <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Masukkan nominal target yang valid')),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      if (_isEditing) {
        final existing = appStore.goalById(widget.goalId!);
        if (existing != null) {
          await appStore.updateSavingsGoal(
            existing.copyWith(
              name: name,
              targetAmount: target,
              targetDate: _targetDate,
              clearTargetDate: _targetDate == null,
            ),
          );
        }
      } else {
        await appStore.addSavingsGoal(
          name: name,
          targetAmount: target,
          targetDate: _targetDate,
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

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit target' : 'Target baru'),
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
                    Text('Nama target', style: textTheme.labelLarge),
                    const SizedBox(height: AppSpacing.sm),
                    TextField(
                      controller: _nameController,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: const InputDecoration(
                        hintText: 'mis. Dana darurat, Laptop baru',
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    AmountField(
                      controller: _targetController,
                      isIncome: true,
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    Text('Tenggat (opsional)', style: textTheme.labelLarge),
                    const SizedBox(height: AppSpacing.sm),
                    InkWell(
                      onTap: _pickDate,
                      borderRadius: BorderRadius.circular(12),
                      child: InputDecorator(
                        decoration: InputDecoration(
                          suffixIcon: _targetDate != null
                              ? IconButton(
                                  icon: const Icon(Icons.close),
                                  onPressed: () =>
                                      setState(() => _targetDate = null),
                                )
                              : const Icon(Icons.calendar_today_outlined),
                        ),
                        child: Text(
                          _targetDate != null
                              ? formatDateShort(_targetDate!)
                              : 'Tanpa tenggat',
                        ),
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
