import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import '../services/auth_service.dart';
import '../services/csv_export_service.dart';
import '../state/app_store.dart';

/// Shared "export all transactions as CSV" action used by the Account
/// screen's settings list and the Home screen's quick-action grid.
Future<void> exportTransactionsCsv(
  BuildContext context, {
  required ValueChanged<bool> setLoading,
}) async {
  setLoading(true);
  try {
    final txs = appStore.transactions;
    if (txs.isEmpty) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Belum ada transaksi untuk diekspor')),
      );
      return;
    }

    final csv = CsvExportService.buildAllTimeTransactionsCsv(txs);
    final ledgerName = appStore.currentLedger?.name ?? 'Buku kas';
    await SharePlus.instance.share(
      ShareParams(text: csv, subject: 'SiMoney - CSV $ledgerName'),
    );
  } catch (e) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(AuthService.messageFor(e))),
    );
  } finally {
    setLoading(false);
  }
}
