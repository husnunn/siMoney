import 'package:flutter/material.dart';

import '../../models/models.dart';
import '../../state/app_store.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../utils/formatters.dart';
import '../../widgets/amount_field.dart';
import '../../widgets/primary_button.dart';

class AddContributionArgs {
  const AddContributionArgs({required this.goalId, required this.type});

  final String goalId;
  final ContributionType type;
}

class AddContributionScreen extends StatefulWidget {
  const AddContributionScreen({
    super.key,
    required this.goalId,
    this.initialType = ContributionType.deposit,
  });

  static const routeName = '/savings/contribution/add';

  final String goalId;
  final ContributionType initialType;

  @override
  State<AddContributionScreen> createState() => _AddContributionScreenState();
}

class _AddContributionScreenState extends State<AddContributionScreen> {
  late ContributionType _type;
  ContributionSource _source = ContributionSource.appBalance;
  late TextEditingController _amountController;
  late TextEditingController _noteController;
  late DateTime _date;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _type = widget.initialType;
    _amountController = TextEditingController();
    _noteController = TextEditingController();
    _date = DateTime.now();
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
        _date = DateTime(picked.year, picked.month, picked.day);
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

    setState(() => _saving = true);
    try {
      await appStore.addSavingsContribution(
        goalId: widget.goalId,
        amount: amount,
        date: _date,
        note: _noteController.text,
        type: _type,
        source: _source,
      );

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
    final isDeposit = _type == ContributionType.deposit;

    return Scaffold(
      appBar: AppBar(
        title: Text(isDeposit ? 'Setor tabungan' : 'Tarik tabungan'),
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
                    SegmentedButton<ContributionType>(
                      segments: const [
                        ButtonSegment(
                          value: ContributionType.deposit,
                          label: Text('Setor'),
                          icon: Icon(Icons.south_west),
                        ),
                        ButtonSegment(
                          value: ContributionType.withdraw,
                          label: Text('Tarik'),
                          icon: Icon(Icons.north_east),
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
                            return isDeposit
                                ? AppColors.onSecondary
                                : AppColors.onError;
                          }
                          return AppColors.onSurface;
                        }),
                        backgroundColor:
                            WidgetStateProperty.resolveWith((states) {
                          if (states.contains(WidgetState.selected)) {
                            return isDeposit
                                ? AppColors.income
                                : AppColors.expense;
                          }
                          return AppColors.surfaceContainer;
                        }),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    AmountField(
                      controller: _amountController,
                      isIncome: isDeposit,
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    Text('Sumber dana', style: textTheme.labelLarge),
                    const SizedBox(height: AppSpacing.sm),
                    SegmentedButton<ContributionSource>(
                      segments: const [
                        ButtonSegment(
                          value: ContributionSource.appBalance,
                          label: Text('Saldo aplikasi'),
                        ),
                        ButtonSegment(
                          value: ContributionSource.external,
                          label: Text('Sumber lain'),
                        ),
                      ],
                      selected: {_source},
                      onSelectionChanged: (s) {
                        setState(() => _source = s.first);
                      },
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      _source == ContributionSource.appBalance
                          ? (isDeposit
                              ? 'Saldo aplikasi akan berkurang sebesar nominal ini.'
                              : 'Saldo aplikasi akan bertambah sebesar nominal ini.')
                          : 'Tidak memengaruhi saldo aplikasi.',
                      style: textTheme.bodySmall,
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
                      decoration: const InputDecoration(hintText: 'Opsional'),
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
                label: isDeposit ? 'Setor' : 'Tarik',
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
