import 'package:flutter/material.dart';

import '../../models/models.dart';
import '../../state/app_store.dart';
import '../../state/inflation_data.dart';
import '../../state/savings_planner.dart';
import '../../theme/app_spacing.dart';
import '../../utils/formatters.dart';
import '../../widgets/amount_field.dart';
import '../../widgets/period_pill_selector.dart';
import '../../widgets/primary_button.dart';
import '../../widgets/responsive_body.dart';
import 'widgets/date_field_tile.dart';
import 'widgets/expected_return_field.dart';
import 'widgets/goal_form_preview.dart';
import 'widgets/goal_kind_selector.dart';
import 'widgets/inflation_settings_section.dart';

/// Create or edit a savings goal of either kind. A new goal starts as the kind
/// of the tab it was created from; an existing goal keeps its kind.
class AddEditSavingsGoalScreen extends StatefulWidget {
  const AddEditSavingsGoalScreen({
    super.key,
    this.goalId,
    this.initialKind = SavingsGoalKind.target,
  });

  static const routeName = '/savings/goal/edit';

  final String? goalId;
  final SavingsGoalKind initialKind;

  @override
  State<AddEditSavingsGoalScreen> createState() =>
      _AddEditSavingsGoalScreenState();
}

class _AddEditSavingsGoalScreenState extends State<AddEditSavingsGoalScreen> {
  late SavingsGoalKind _kind;
  late final TextEditingController _nameController;
  late final TextEditingController _amountController;
  late final TextEditingController _returnController;
  PeriodUnit _unit = PeriodUnit.week;
  DateTime? _deadline;
  late DateTime _startDate;
  bool _adjust = true;
  double? _rate;
  bool _saving = false;

  bool get _isEditing => widget.goalId != null;
  bool get _isPeriodic => _kind == SavingsGoalKind.periodic;

  SavingsGoal? get _existing =>
      widget.goalId == null ? null : appStore.goalById(widget.goalId!);

  static DateTime _today() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  @override
  void initState() {
    super.initState();
    final existing = _existing;
    _kind = existing?.kind ?? widget.initialKind;
    _nameController = TextEditingController(text: existing?.name ?? '');
    final amount = existing == null
        ? 0
        : (existing.isPeriodic
            ? (existing.periodicAmount ?? 0)
            : existing.targetAmount);
    _amountController = TextEditingController(
      text: amount > 0 ? formatRupiah(amount).replaceFirst('Rp', '') : '',
    )..addListener(_refresh);
    _returnController = TextEditingController(
      text: existing != null && existing.expectedReturn > 0
          ? existing.expectedReturn.toString().replaceAll('.', ',')
          : '',
    )..addListener(_refresh);
    _unit = existing?.periodUnit ?? PeriodUnit.week;
    _deadline = existing?.targetDate;
    _startDate = existing?.startDate ?? _today();
    _adjust = existing?.adjustForInflation ?? true;
    _rate = existing?.inflationRate;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    _returnController.dispose();
    super.dispose();
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  double get _annualReturn {
    final text = _returnController.text.trim().replaceAll(',', '.');
    return double.tryParse(text) ?? 0;
  }

  /// Horizon the "automatic" inflation option resolves for.
  int get _autoHorizonDays {
    final deadline = _deadline;
    if (_isPeriodic || deadline == null) return InflationData.periodicHorizonDays;
    return PlanDates.daysBetween(_today(), deadline).clamp(1, 365 * 40);
  }

  Future<void> _pickDeadline() async {
    final today = _today();
    final current = _deadline;
    final initial = (current != null && !current.isBefore(today))
        ? current
        : today.add(const Duration(days: 365));
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: today,
      lastDate: today.add(const Duration(days: 365 * 30)),
    );
    if (picked != null) setState(() => _deadline = picked);
  }

  Future<void> _pickStartDate() async {
    final today = _today();
    final first = today.subtract(const Duration(days: 365 * 5));
    final last = today.add(const Duration(days: 365));
    final initial = _startDate.isBefore(first)
        ? first
        : (_startDate.isAfter(last) ? last : _startDate);
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: first,
      lastDate: last,
    );
    if (picked != null) {
      setState(() => _startDate = DateTime(picked.year, picked.month, picked.day));
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    final amount = parseAmount(_amountController.text);
    final annualReturn = _annualReturn;

    if (name.isEmpty) {
      _showMessage('Masukkan nama target');
      return;
    }
    if (amount <= 0) {
      _showMessage(
        _isPeriodic
            ? 'Masukkan nominal per periode yang valid'
            : 'Masukkan nominal target yang valid',
      );
      return;
    }
    if (annualReturn < 0 || annualReturn > 100) {
      _showMessage('Imbal hasil harus antara 0% dan 100% per tahun');
      return;
    }
    if (!_isPeriodic && _adjust && _deadline == null) {
      _showMessage('Pilih tenggat untuk menyesuaikan target dengan inflasi');
      return;
    }

    setState(() => _saving = true);
    try {
      final existing = _existing;
      if (existing != null) {
        final priceChanged = !_isPeriodic && amount != existing.targetAmount;
        await appStore.updateSavingsGoal(
          existing.copyWith(
            name: name,
            targetAmount: _isPeriodic ? 0 : amount,
            targetDate: _isPeriodic ? null : _deadline,
            clearTargetDate: _isPeriodic || _deadline == null,
            periodicAmount: _isPeriodic ? amount : null,
            periodUnit: _isPeriodic ? _unit : null,
            startDate: _isPeriodic ? _startDate : null,
            adjustForInflation: _adjust,
            inflationRate: _rate,
            clearInflationRate: _rate == null,
            expectedReturn: annualReturn,
            // A new amount is a new price quote: count inflation from today.
            priceDate: priceChanged ? _today() : null,
          ),
        );
      } else {
        await appStore.addSavingsGoal(
          name: name,
          kind: _kind,
          targetAmount: _isPeriodic ? 0 : amount,
          targetDate: _isPeriodic ? null : _deadline,
          periodicAmount: _isPeriodic ? amount : null,
          periodUnit: _isPeriodic ? _unit : null,
          startDate: _isPeriodic ? _startDate : null,
          adjustForInflation: _adjust,
          inflationRate: _rate,
          expectedReturn: annualReturn,
        );
      }

      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      _showMessage(e.toString());
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  String get _title {
    if (_isEditing) return 'Edit target';
    return _isPeriodic ? 'Target berkala baru' : 'Target akhir baru';
  }

  String get _amountLabel {
    if (_isPeriodic) return 'Nominal per ${_unit.label.toLowerCase()}';
    return _adjust ? 'Nominal target (harga hari ini)' : 'Nominal target';
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: Text(_title)),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: ResponsiveBody(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (!_isEditing) ...[
                          GoalKindSelector(
                            kind: _kind,
                            onChanged: (k) => setState(() => _kind = k),
                          ),
                          const SizedBox(height: AppSpacing.lg),
                        ],
                        Text('Nama target', style: textTheme.labelLarge),
                        const SizedBox(height: AppSpacing.sm),
                        TextField(
                          controller: _nameController,
                          textCapitalization: TextCapitalization.sentences,
                          decoration: InputDecoration(
                            hintText: _isPeriodic
                                ? 'mis. Celengan mingguan, Tabungan haji'
                                : 'mis. Dana darurat, Laptop baru',
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xl),
                        if (_isPeriodic) ...[
                          Text('Menabung setiap', style: textTheme.labelLarge),
                          const SizedBox(height: AppSpacing.sm),
                          PeriodPillSelector<PeriodUnit>(
                            options: [
                              for (final u in PeriodUnit.selectable)
                                PeriodPillOption(
                                  value: u,
                                  label: u.perLabel[0].toUpperCase() +
                                      u.perLabel.substring(1),
                                ),
                            ],
                            selected: _unit,
                            onChanged: (u) => setState(() => _unit = u),
                          ),
                          const SizedBox(height: AppSpacing.xl),
                        ],
                        AmountField(
                          controller: _amountController,
                          isIncome: true,
                          label: _amountLabel,
                        ),
                        const SizedBox(height: AppSpacing.xl),
                        if (_isPeriodic)
                          DateFieldTile(
                            label: 'Mulai tanggal',
                            value: formatDateShort(_startDate),
                            onTap: _pickStartDate,
                          )
                        else
                          DateFieldTile(
                            label: 'Tenggat',
                            value: _deadline != null
                                ? formatDateShort(_deadline!)
                                : 'Tanpa tenggat',
                            onTap: _pickDeadline,
                            onClear: _deadline != null
                                ? () => setState(() => _deadline = null)
                                : null,
                            clearTooltip: 'Hapus tenggat',
                            helper: _deadline == null
                                ? 'Isi tenggat untuk melihat rencana setoran '
                                    'per hari, minggu, bulan, dan tahun.'
                                : null,
                          ),
                        const SizedBox(height: AppSpacing.xl),
                        InflationSettingsSection(
                          adjust: _adjust,
                          onAdjustChanged: (v) => setState(() => _adjust = v),
                          rate: _rate,
                          onRateChanged: (r) => setState(() => _rate = r),
                          autoRate:
                              InflationData.autoRateForDays(_autoHorizonDays),
                          title: _isPeriodic
                              ? 'Tampilkan nilai daya beli'
                              : 'Sesuaikan dengan inflasi',
                          subtitle: _isPeriodic
                              ? 'Proyeksi ditampilkan juga dalam daya beli '
                                  'hari ini.'
                              : 'Anggap nominal itu harga hari ini, lalu naikkan '
                                  'sesuai inflasi sampai tenggat.',
                        ),
                        const SizedBox(height: AppSpacing.xl),
                        ExpectedReturnField(controller: _returnController),
                        const SizedBox(height: AppSpacing.xl),
                        GoalFormPreview(
                          isPeriodic: _isPeriodic,
                          amount: parseAmount(_amountController.text),
                          annualReturn: _annualReturn.clamp(0.0, 100.0),
                          unit: _unit,
                          adjust: _adjust,
                          rate: _rate,
                          deadline: _deadline,
                          existing: _existing,
                        ),
                      ],
                    ),
                  ),
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
