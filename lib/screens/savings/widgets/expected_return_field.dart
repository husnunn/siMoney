import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../theme/app_spacing.dart';

/// Optional yearly yield (in percent) of wherever the money is kept.
class ExpectedReturnField extends StatelessWidget {
  const ExpectedReturnField({super.key, required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Imbal hasil tempat menabung (opsional)',
          style: textTheme.labelLarge,
        ),
        const SizedBox(height: AppSpacing.sm),
        TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
          ],
          decoration: const InputDecoration(
            hintText: 'mis. 4,5',
            suffixText: '% per tahun',
            helperText: 'Kosongkan bila uang disimpan tanpa bunga. '
                'Mis. deposito atau reksa dana pasar uang.',
          ),
        ),
      ],
    );
  }
}
