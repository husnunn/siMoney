import 'package:flutter/material.dart';

import '../utils/formatters.dart';

/// Eye icon button that toggles a screen-local "hide balance" state.
class BalanceVisibilityToggle extends StatelessWidget {
  const BalanceVisibilityToggle({
    super.key,
    required this.hidden,
    required this.onToggle,
    this.color,
  });

  final bool hidden;
  final VoidCallback onToggle;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: hidden ? 'Tampilkan saldo' : 'Sembunyikan saldo',
      onPressed: onToggle,
      icon: Icon(
        hidden ? Icons.visibility_off_outlined : Icons.visibility_outlined,
        color: color,
      ),
    );
  }
}

/// Renders a rupiah amount, or a masked placeholder when [hidden] is true.
class MaskedAmountText extends StatelessWidget {
  const MaskedAmountText({
    super.key,
    required this.amount,
    required this.hidden,
    this.style,
  });

  final int amount;
  final bool hidden;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    return Text(
      hidden ? 'Rp ••••••' : formatRupiah(amount),
      style: style,
    );
  }
}
