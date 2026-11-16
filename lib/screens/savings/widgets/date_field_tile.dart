import 'package:flutter/material.dart';

import '../../../theme/app_spacing.dart';

/// A labelled field that shows a date and opens a picker when tapped, with an
/// optional clear button and helper line.
class DateFieldTile extends StatelessWidget {
  const DateFieldTile({
    super.key,
    required this.label,
    required this.value,
    required this.onTap,
    this.onClear,
    this.clearTooltip = 'Hapus tanggal',
    this.helper,
  });

  final String label;
  final String value;
  final VoidCallback onTap;
  final VoidCallback? onClear;
  final String clearTooltip;
  final String? helper;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: textTheme.labelLarge),
        const SizedBox(height: AppSpacing.sm),
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          child: InputDecorator(
            decoration: InputDecoration(
              suffixIcon: onClear != null
                  ? IconButton(
                      icon: const Icon(Icons.close),
                      tooltip: clearTooltip,
                      onPressed: onClear,
                    )
                  : const Icon(Icons.calendar_today_outlined),
            ),
            child: Text(value),
          ),
        ),
        if (helper != null) ...[
          const SizedBox(height: AppSpacing.xs),
          Text(helper!, style: textTheme.bodySmall),
        ],
      ],
    );
  }
}
