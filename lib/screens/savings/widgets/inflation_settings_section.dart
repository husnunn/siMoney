import 'package:flutter/material.dart';

import '../../../state/inflation_data.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_spacing.dart';
import '../../../utils/formatters.dart';

/// Switch + scenario chips + fine-tuning slider for the inflation assumption
/// of a savings goal. `rate == null` means "automatic for the horizon".
class InflationSettingsSection extends StatelessWidget {
  const InflationSettingsSection({
    super.key,
    required this.adjust,
    required this.onAdjustChanged,
    required this.rate,
    required this.onRateChanged,
    required this.autoRate,
    this.title = 'Sesuaikan dengan inflasi',
    this.subtitle =
        'Harga naik dari tahun ke tahun, jadi nominal target ikut dinaikkan.',
  });

  final bool adjust;
  final ValueChanged<bool> onAdjustChanged;

  /// Yearly inflation in percent, or `null` for automatic.
  final double? rate;
  final ValueChanged<double?> onRateChanged;

  /// What "automatic" resolves to for the current horizon.
  final double autoRate;

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final animate = !MediaQuery.disableAnimationsOf(context);

    // A Material (not a decorated Container) so the switch tile's ink splash
    // stays visible.
    return Material(
      color: AppColors.surfaceContainer,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        side: const BorderSide(color: AppColors.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SwitchListTile(
            value: adjust,
            onChanged: onAdjustChanged,
            title: Text(title, style: textTheme.labelLarge),
            subtitle: Text(subtitle, style: textTheme.bodySmall),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.xs,
            ),
          ),
          AnimatedSize(
            duration: animate ? const Duration(milliseconds: 200) : Duration.zero,
            alignment: Alignment.topCenter,
            child: adjust
                ? _RateControls(
                    rate: rate,
                    autoRate: autoRate,
                    onRateChanged: onRateChanged,
                  )
                : const SizedBox(width: double.infinity),
          ),
        ],
      ),
    );
  }
}

/// The expanded part: current rate, scenario chips, slider and data notes.
class _RateControls extends StatelessWidget {
  const _RateControls({
    required this.rate,
    required this.autoRate,
    required this.onRateChanged,
  });

  final double? rate;
  final double autoRate;
  final ValueChanged<double?> onRateChanged;

  bool _isScenario(InflationScenario s) =>
      rate != null && (rate! - s.rate).abs() < 0.001;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final effective = rate ?? autoRate;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        0,
        AppSpacing.md,
        AppSpacing.md,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text('Asumsi inflasi', style: textTheme.labelLarge),
              ),
              Text(
                '${formatPercent(effective)} per tahun',
                style: textTheme.labelLarge?.copyWith(color: AppColors.primary),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              ChoiceChip(
                label: Text('Otomatis ${formatPercent(autoRate)}'),
                selected: rate == null,
                onSelected: (_) => onRateChanged(null),
              ),
              for (final s in InflationScenario.values)
                ChoiceChip(
                  label: Text('${s.label} ${formatPercent(s.rate)}'),
                  selected: _isScenario(s),
                  onSelected: (_) => onRateChanged(s.rate),
                ),
            ],
          ),
          Slider(
            value: effective.clamp(0.0, 10.0),
            min: 0,
            max: 10,
            divisions: 100,
            label: formatPercent(effective),
            onChanged: (v) => onRateChanged((v * 10).roundToDouble() / 10),
          ),
          Text(
            'Otomatis: tenor pendek memakai inflasi terkini, tenor panjang '
            'mendekati rata-rata jangka panjang. Rendah = titik tengah target '
            'BI, Tinggi = setara tahun 2022.',
            style: textTheme.bodySmall,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Inflasi terkini ${formatPercent(InflationData.latestYoy, digits: 2)} '
            '(${InflationData.latestPeriodLabel}) · rata-rata 10 tahun '
            '${formatPercent(InflationData.average10y, digits: 2)} · target BI '
            '${formatPercent(InflationData.targetMidpoint)} '
            '±${formatPercent(InflationData.targetBand, digits: 0)}. '
            'Sumber: ${InflationData.sourceNote}.',
            style: textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}
